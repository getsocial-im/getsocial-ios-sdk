//
//  File.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 16/11/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class ChatMessagesView {

    var viewController: ChatMessagesViewController

    init(_ chat: Chat) {
        self.viewController = ChatMessagesViewController()
        self.viewController.model = ChatMessagesModel(chat)
    }

    init(_ userId: UserId) {
        self.viewController = ChatMessagesViewController()
        self.viewController.model = ChatMessagesModel(userId)
    }

}
