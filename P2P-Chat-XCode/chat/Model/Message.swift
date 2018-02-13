//
//  Message.swift
//  chat
//
//  Created by Charles Bethin on 12/7/17.
//  Copyright © 2017 Charles Bethin. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Message: NSObject, NSCoding {
    let sourceID : String
    let destinationID : String
    let type : MessageType
    let number : Int
    let data : String
    var didSend : Bool
    
    init(sourceID: String, destinationID: String, number: Int, type: MessageType, data: String) {
        self.sourceID = sourceID
        self.destinationID = destinationID
        self.type = type
        self.number = number
        self.data = data
        self.didSend = false
    }

    
    required convenience init(coder aDecoder: NSCoder) {
        let sourceID = aDecoder.decodeObject(forKey: "sourceID") as! String
        let destinationID = aDecoder.decodeObject(forKey: "destinationID") as! String
        let type = aDecoder.decodeObject(forKey: "type") as! String
        let number = aDecoder.decodeInteger(forKey: "number")
        let data = aDecoder.decodeObject(forKey: "data") as! String
        
        self.init(sourceID: sourceID, destinationID: destinationID, number: number, type: MessageType(rawValue: type)!, data: data)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.sourceID, forKey: "sourceID")
        aCoder.encode(self.destinationID, forKey: "destinationID")
        aCoder.encode(self.type.rawValue, forKey: "type")
        aCoder.encode(self.number, forKey: "number")
        aCoder.encode(self.data, forKey: "data")
    }
    
}


class MessageList {
    
    var messages: [Message]
    
    init() {
        self.messages = []
    }
    
    func addMessage(message: Message) {
        self.messages.append(message)
    }
    
    func hasMessage(message: Message) -> Bool {
        for msgInArray in messages {
            if msgInArray.number == message.number && msgInArray.sourceID == message.sourceID && msgInArray.data == message.data {
                return true
            } else {
                // Do nothing
            }
        }
        
        return false
    }
}


enum MessageType: String {
    case message = "message"
    case ack = "ack"
    case newUser = "newUser"
}
