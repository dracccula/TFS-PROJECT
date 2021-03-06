//
//  CellModels.swift
//  TFS PROJECT
//
//  Created by Vladislav Kireev on 14.03.2020.
//  Copyright © 2020 VK. All rights reserved.
//
import Foundation

struct Channel {
    let identifier: String?
    let name: String?
    let lastMessage: String?
    let lastActivity: Date?
}

struct Message {
    let senderId: String?
    let senderName: String?
    let content: String?
    let created: Date?
}
