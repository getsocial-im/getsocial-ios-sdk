//
//  File.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 16/11/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

protocol ChatsViewDelegate {
    func onShowChat(_ chat: Chat)
}

class ChatsView {

    var onShowChat: ((Chat) -> Void)?
    var viewController: ChatsViewController

    init() {
        self.viewController = ChatsViewController()
        self.viewController.delegate = self
        self.viewController.model = ChatsModel()
    }

}

extension ChatsView: ChatsViewControllerDelegate {
    func onShowChat(_ chat: Chat) {
        self.onShowChat?(chat)
    }
}
