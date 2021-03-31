//
//  ChatModel.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 16/11/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class ChatsModel {

    private var chats: [Chat] = []

    var onChatsLoaded: (() -> Void)?
    var onError: ((String) -> Void)?

    func numberOfEntries() -> Int {
        return self.chats.count
    }

    func entry(at: Int) -> Chat {
        return self.chats[at]
    }

    func loadChats() {
        self.chats = []
        self.loadChats(ChatsPagingQuery(), success: { [weak self] result in
            self?.chats = result
            self?.onChatsLoaded?()
            }, failure: { [weak self] errorMessage in
                self?.onError?(errorMessage)
            })
    }

    private func loadChats(_ pagingQuery: ChatsPagingQuery, success: @escaping ([Chat]) -> Void, failure: @escaping (String) -> Void) {
        Communities.chats(pagingQuery, success: { result in
            success(result.chats)
        }, failure: { error in
            failure(error.localizedDescription)
        })
    }
}
