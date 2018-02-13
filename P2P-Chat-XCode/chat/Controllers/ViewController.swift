//
//  ViewController.swift
//  chat
//
//  Copyright © 2017 Charles Bethin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ChatServiceManagerDelegate {

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var textView: UIView!
    
    @IBOutlet weak var changeViewButton: UIBarButtonItem!
    var changeViewState : ViewStateType = .messages
    
    
    let chatService = ChatServiceManager()
    
    var messageList : MessageList = MessageList()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        changeViewButton.title = "Users"

        sendButton.layer.cornerRadius = 3
        
        messageTextField.delegate = self
        messageTableView.delegate = self

        // Do any additional setup after loading the view.
        chatService.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGestureRecognizer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func tableViewTapped() {
        messageTextField.endEditing(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func changeView(_ sender: Any) {
        if changeViewState == .messages {
            changeViewState = .users
            changeViewButton.title = "Messages"
            self.title = "Nearby Users"
            
        } else {
            changeViewState = .messages
            changeViewButton.title = "Users"
            self.title = "Nearby Messages"
        }
        
        messageTableView.reloadData()
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let messageText = messageTextField.text {
            let message = Message(sourceID: chatService.myPeerId.displayName, destinationID: "all", number: chatService.messageNumber, type: .message, data: messageText)
            self.messageList.addMessage(message: message)
            chatService.send(message: message)
            
            messageTableView.reloadData()
            messageTextField.text = ""
        }
        messageTextField.resignFirstResponder()
    }
    
    func connectedDevicesChanged(manager: ChatServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.messageTableView.reloadData()  
        }
    }
    
    func didReceiveMessage(manager: ChatServiceManager, message: Message) {
        OperationQueue.main.addOperation {
            if !self.messageList.hasMessage(message: message) {
                self.messageList.addMessage(message: message)
                self.messageTableView.reloadData()
                self.chatService.send(message: message)
            } else {
                print("Already received message")
            }
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        if changeViewState == .messages {
            
            if messageList.messages[indexPath.row].sourceID == chatService.myPeerId.displayName {
                cell.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.05)
                cell.textLabel?.text = "\(messageList.messages[indexPath.row].data)"
            } else {
                cell.textLabel?.text = "\(messageList.messages[indexPath.row].sourceID): \(messageList.messages[indexPath.row].data)"
            }
            
        } else if changeViewState == .users {
            cell.textLabel?.text = chatService.userList.users[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if changeViewState == .messages {
            return messageList.messages.count
        } else if changeViewState == .users {
            return chatService.userList.users.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}

extension ViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.heightConstraint.constant = 350
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }

}

enum ViewStateType {
    case users
    case messages
}

