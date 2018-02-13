//
//  UserList.swift
//  chat
//
//  Created by Charles Bethin on 12/11/17.
//  Copyright © 2017 Charles Bethin. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class UserList {
    
    var users : [String]
    
    init() {
        self.users = []
    }
    
    func addUser(username: String) {
        print("Found user \(username)")
        if !self.hasUser(username: username) {
            self.users.append(username)
        }
    }
    
    func removeUser(username: String) {
        print("Lost user \(username)")
        if let index = users.index(of: username) {
            print(index)
            users.remove(at: index)
        }
    }
    
    func hasUser(username: String) -> Bool {
        for usernameInArray in users {
            if usernameInArray == username {
                return true
            } else {
                // do nothing
            }
        }
        
        return false
    }
    
    
}

