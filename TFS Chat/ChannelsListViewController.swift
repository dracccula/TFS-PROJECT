//
//  ViewController.swift
//  TFS PROJECT
//
//  Created by Vladislav Kireev on 17.02.2020.
//  Copyright © 2020 VK. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, InfoDataDelegate {
    
    @IBAction func addChannelButton(_ sender: Any) {
        showAlertToAddChannel()
    }
    @IBOutlet weak var profileButton: UIButton!
    @IBAction func clickAvatarButton(_ sender: Any) {
    }
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var channelsTableView: UITableView!
    private let spinner = SpinnerUtils()
    enum TableSection: Int {
        case online, offline
    }
    
    var channelsArray : [Channel] = []
    var onlineChannelsArray: [Channel] = []
    var historyChannelsArray: [Channel] = []
    
    let app = UIApplication.shared.delegate as! AppDelegate
    private lazy var reference = app.db.collection("channels")
    
    func getSortedChannelsArrays(source: [Channel]){
        onlineChannelsArray = []
        historyChannelsArray = []
        source.forEach { channel in
            if channel.lastActivity != nil {
                if channel.lastActivity! > Date().addingTimeInterval(-600) {
                    onlineChannelsArray.append(channel)
                } else {
                    historyChannelsArray.append(channel)
                }
            } else {
                historyChannelsArray.append(channel)
            }
        }
    }
    
    private func getChannels(){
        channelsArray = []
        spinner.showActivityIndicator(uiView: self.view)
        DispatchQueue.main.async {
            self.reference.addSnapshotListener { snapshot, error in
                snapshot!.documents.forEach { data in
                    let identifier = data.documentID
                    let name = data.data()["name"] as? String
                    let lastMessage = data.data()["lastMessage"] as? String
                    let lastActivity = data.data()["lastActivity"] as? Timestamp
                    //                print("\(identifier ?? "id"), \(name ?? "Untitled"), \(lastMessage ?? "No messages"), \(lastActivity)")
                    self.channelsArray.append(Channel(identifier: identifier, name: name, lastMessage: lastMessage, lastActivity: lastActivity?.dateValue()))
                }
                self.getSortedChannelsArrays(source: self.channelsArray)
                self.channelsTableView.reloadData()
            }
            self.spinner.hideActivityIndicator(uiView: self.view)
        }
    }
    
    private func showAlertToAddChannel() {
        let alert = UIAlertController(title: "Add new channel", message: "Enter a channel name", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            self.addChannel(channelName: textField?.text ?? "")
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addChannel(channelName: String) {
        DispatchQueue.main.async {
            self.spinner.showActivityIndicator(uiView: self.view)
            self.reference.addDocument(data: Channel(identifier: nil, name: channelName, lastMessage: "", lastActivity: Date()).toDict)
            self.channelsTableView.reloadData()
            self.spinner.hideActivityIndicator(uiView: self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
      return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return onlineChannelsArray.count
        } else {
            return historyChannelsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
           switch section {
           case 0:
               return "Online"
           case 1:
               return "History"
           default:
               return nil
           }
       }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelViewCell
            cell.configure(with: onlineChannelsArray[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelViewCell
            cell.configure(with: historyChannelsArray[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard =  UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyBoard.instantiateViewController(withIdentifier: "ChannelViewController") as? ChannelViewController
            else {
                return print("Error")
        }
        switch indexPath.section {
        case 0:
            let name = onlineChannelsArray[indexPath.row].name
            vc.title = name
            vc.channel = onlineChannelsArray[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
            print(onlineChannelsArray[indexPath.row].lastActivity ?? "no date")
            print(Date())
            print(Date().addingTimeInterval(-600))
            print(onlineChannelsArray[indexPath.row].identifier ?? "no id")
        case 1:
            let name = historyChannelsArray[indexPath.row].name
            vc.title = name
            vc.channel = historyChannelsArray[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
            print(historyChannelsArray[indexPath.row].lastActivity ?? "no date")
            print(Date())
            print(Date().addingTimeInterval(-600))
            print(historyChannelsArray[indexPath.row].identifier ?? "no id")
        default:
            print("Error")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getChannels()
        profileButton.makeRounded()
        if let image = GCDDataManager().getSavedPicture(named: "profilePicture") {
            profileButton.setImage(image, for: .normal)
        }
        if let name = GCDDataManager().getSavedText(named: "name") {
            profileName.text = name
        }
        channelsTableView.dataSource = self
        channelsTableView.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if let destination = segue.destination as? ProfileViewController {
               destination.delegate = self
           }
       }
       
       func passInfo() {
        if let image = GCDDataManager().getSavedPicture(named: "profilePicture") {
            profileButton.setImage(image, for: .normal)
        }
        self.profileName.text = GCDDataManager().getSavedText(named: "name")
       }
}

// MARK: Extension which make image rounded
extension UIButton {
    func makeRounded() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}

extension Channel {
    var toDict: [String: Any] {
        return ["identifier": identifier ?? "",
                "lastActivity": Timestamp(date: lastActivity!),
                "name": name!,
                "lastMessage": lastMessage!]
         
    }
}