//
//  MessageThreadController.swift
//  Message Board
//
//  Created by Spencer Curtis on 8/7/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

class MessageThreadController {
    
    var uuid : String?
    func fetchMessageThreads(completion: @escaping () -> Void) {
        
        let requestURL = MessageThreadController.baseURL.appendingPathExtension("json")
        
        // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
        if isUITesting {
            fetchLocalMessageThreads(completion: completion)
            return
        }
        print(requestURL)
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error fetching message threads: \(error)")
                completion()
                return
            }
            
            guard let data = data else { NSLog("No data returned from data task"); completion(); return }
            do {
                let messages = try JSONDecoder().decode([String : MessageThread].self, from: data)
                for(_, value) in messages{
                    self.messageThreads.append(value)
                    self.removeDuplicates()
                }
            } catch {
                self.messageThreads = []
                NSLog("Error decoding message threads from JSON data: \(error)")
            }
            
            completion()
        }.resume()
    }
    
    func removeDuplicates(){
        var idArray : [String] = []
        var newArray : [MessageThread] = []
        for index in messageThreads{
            if newArray.contains(index){
                continue
            }else{
                if(!idArray.contains(index.identifier)){
                    newArray.append(index)
                    idArray.append(index.identifier)
                }
            }
        }
        messageThreads = newArray
    }
    
    func createMessageThread(with title: String, completion: @escaping () -> Void) {
        
        // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
        if isUITesting {
            createLocalMessageThread(with: title, completion: completion)
            return
        }
        
        let thread = MessageThread(title: title)
        
        let requestURL = MessageThreadController.baseURL.appendingPathComponent(thread.identifier).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        do {
            request.httpBody = try JSONEncoder().encode(thread)
        } catch {
            NSLog("Error encoding thread to JSON: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error with message thread creation data task: \(error)")
                completion()
                return
            }
            
            self.messageThreads.append(thread)
            completion()
            
        }.resume()
    }
    
    func createMessage(in messageThread: MessageThread, withText text: String, sender: String, completion: @escaping () -> Void) {
        
        // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
        if isUITesting {
            createLocalMessage(in: messageThread, withText: text, sender: sender, completion: completion)
            return
        }
        
        guard let index = messageThreads.index(of: messageThread) else { completion(); return }
        
        let message = MessageThread.Message(text: text, sender: sender)
        self.uuid = UUID().uuidString
        messageThreads[index].messages[self.uuid!] = message
        
        let requestURL = MessageThreadController.baseURL.appendingPathComponent(messageThread.identifier).appendingPathComponent("messages").appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.post.rawValue
        
        do {
            request.httpBody = try JSONEncoder().encode(message)
        } catch {
            NSLog("Error encoding message to JSON: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error with message thread creation data task: \(error)")
                completion()
                return
            }
            
            completion()
            
        }.resume()
    }
    
    static let baseURL = URL(string: "https://sprint8-eeac0.firebaseio.com/")!
    var messageThreads: [MessageThread] = []
}
