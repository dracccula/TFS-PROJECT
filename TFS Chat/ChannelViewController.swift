//
//  ConversationViewController.swift
//  TFS PROJECT
//
//  Created by Vladislav Kireev on 02.03.2020.
//  Copyright © 2020 VK. All rights reserved.
//

import UIKit
import Firebase

class ChannelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendButtonAction(_ sender: Any) {
        sendMessage()
        getMessages()
    }
    
    private let spinner = SpinnerUtils()
    var channel: Channel?
    let app = UIApplication.shared.delegate as! AppDelegate
    
    private lazy var reference: CollectionReference = {
    guard let channelIdentifier = channel?.identifier else { fatalError() }
        return app.db.collection("channels").document(channelIdentifier).collection("messages")
    }()
    
    var messagesArray : [Message] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = messagesTableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageViewCell
        cell.configure(with: messagesArray[indexPath.row])
        return cell
    }
    
//    //MARK: Function that scroll to bottom
//    func scrollToBottom(){
//        DispatchQueue.main.async {
//            let indexPath = IndexPath(
//                row: self.messagesTableView.numberOfRows(inSection:  self.messagesTableView.numberOfSections - 1) - 1,
//                section: self.messagesTableView.numberOfSections - 1)
//            self.messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
//        }
//    }
    
    func getMessages() {
        messagesArray = []
        DispatchQueue.main.async {
            self.spinner.showActivityIndicator(uiView: self.view)
            self.reference.addSnapshotListener { (snapshot, error) in
                snapshot?.documents.forEach { data in
                    let senderID = data.data()["senderID"] as? String
                    let senderName = data.data()["senderName"] as? String
                    let content = data.data()["content"] as? String
                    let created = data.data()["created"] as? Timestamp
                    print("\(senderID ?? "noId"), \(senderName ?? "noName"), \(content ?? "empty"), \(created?.dateValue() ?? Date())")
                    self.messagesArray.append(Message(senderId: senderID, senderName: senderName, content: content, created: created?.dateValue()))
                }
                self.refreshUI()
                self.spinner.hideActivityIndicator(uiView: self.view)
            }
        }
    }
    
    func refreshUI() {
        DispatchQueue.main.async {
            self.messagesTableView.reloadData()
            print("self.messagesTableView.reloadData()")
        }
    }
    
    func sendMessage() {
        sendButton.isEnabled = false
        reference.addDocument(data: Message(senderId: "VK", senderName: "VK", content: messageTextField.text, created: Date()).toDict)
        sendButton.isEnabled = true
        messageTextField.text = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getMessages()
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messagesTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        messagesTableView.reloadData()
    }
}

extension Message {
    var toDict: [String: Any] {
        return ["content": content ?? "",
                "created": Timestamp(date: created!),
                "senderID": senderId!,
                "senderName": senderName!]
         
    }
}