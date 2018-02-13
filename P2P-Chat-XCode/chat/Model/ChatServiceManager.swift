//
//  ChatServiceManager.swift
//  chat
//
//  Copyright © 2017 Charles Bethin. All rights reserved.


import Foundation
import MultipeerConnectivity

protocol ChatServiceManagerDelegate {
    func connectedDevicesChanged(manager : ChatServiceManager, connectedDevices: [String])
    func didReceiveMessage(manager : ChatServiceManager, message: Message)
}

class ChatServiceManager : NSObject {
    
    let ChatServiceType = "chat"
    let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    var userList = UserList()
    
    var messageNumber: Int = 0
    var timers = [Int : Timer]()
    
    let serviceAdvertiser : MCNearbyServiceAdvertiser
    let serviceBrowser : MCNearbyServiceBrowser
    
    var delegate : ChatServiceManagerDelegate?
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    override init() {

        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ChatServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ChatServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    func send(message : Message) {
        if session.connectedPeers.count > 0 {
            let messageData = NSKeyedArchiver.archivedData(withRootObject: message)
            do {
                try self.session.send(messageData, toPeers: session.connectedPeers, with: .reliable)
                waitForAck(message: message)
                messageNumber += 1
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        } else {
            print("No connected peers")
            alertUserMessageFail(message: message)
        }
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    // Set a timer for the corresponding ack
    private func waitForAck(message: Message) {
        var timer = Timer()
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(ackNotReceived(timer:)), userInfo: message, repeats: false)
        timers[message.number] = timer
    }
    
    // Turn off timer of the corresponding ack number
    private func handleAck(message: Message) {
        print("Got ack num \(message.number) from \(message.sourceID)")
        timers[message.number]?.invalidate()
        timers[message.number] = nil
    }
    
    @objc private func ackNotReceived(timer: Timer) {
        let message = timer.userInfo as! Message
        print("Message number \(message.number) not receieved")
        alertUserMessageFail(message: message)
    }
    
    private func alertUserMessageFail(message: Message) {
        if message.type == .message {
            let alert = UIAlertController(title: "Message Not Received", message: "Your message was \"\(message.data)\" not receieved by anyone", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            let delegate = self.delegate as! UIViewController
            delegate.present(alert, animated: true, completion: nil)
        }
    }
    
    }

extension ChatServiceManager : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        invitationHandler(true, self.session)
        
        if !userList.hasUser(username: peerID.displayName) {
            // Add user to user list
            userList.addUser(username: peerID.displayName)
            
            // Let other peers know you see the user
            let addUserMessage = Message(sourceID: self.myPeerId.displayName, destinationID: "all", number: messageNumber, type: .newUser , data: peerID.displayName)
            self.send(message: addUserMessage)
            messageNumber += 1
            
            // Update delegate
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: self.userList.users)
        }
    }
}

extension ChatServiceManager : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Haven't started browsing yet: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        
        if !userList.hasUser(username: peerID.displayName) {
            
            // Add User to user list
            userList.addUser(username: peerID.displayName)
            
            // Let other's in system know the user is there
            let addUserMessage = Message(sourceID: self.myPeerId.displayName, destinationID: "all", number: messageNumber, type: .newUser , data: peerID.displayName)
            self.send(message: addUserMessage)
            messageNumber += 1
            
            // Update the delegate
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: self.userList.users)
        }
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if userList.hasUser(username: peerID.displayName) {
            userList.removeUser(username: peerID.displayName)
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: self.userList.users)
        }
    }
}

extension ChatServiceManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
        for connectedPeer in session.connectedPeers {
            userList.addUser(username: connectedPeer.displayName)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let rcvdMessage = NSKeyedUnarchiver.unarchiveObject(with: data) as! Message
        if rcvdMessage.type == .message {
            let ack = Message(sourceID: myPeerId.displayName,
                              destinationID: rcvdMessage.sourceID,
                              number: rcvdMessage.number,
                              type: .ack,
                              data: rcvdMessage.data)
            self.send(message: ack)
            self.delegate?.didReceiveMessage(manager: self, message: rcvdMessage)
        } else if rcvdMessage.type == .ack {
            handleAck(message: rcvdMessage)
        } else if rcvdMessage.type == .newUser && !userList.hasUser(username: rcvdMessage.data) {
            userList.addUser(username: rcvdMessage.data)
            print("Added user: \(rcvdMessage)")
        } else {
            print("Unknown message type:", rcvdMessage.sourceID, rcvdMessage.type, rcvdMessage.data)
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Did receive stream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Receiving resources")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finished receiving resources")
    }
}
