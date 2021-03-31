//
//  ChatModel.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 16/11/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class ChatMessagesModel {

    private var chat: Chat?
    private let chatId: ChatId
    private var pagingQuery: ChatMessagesPagingQuery?
    private var nextMessagesCursor: String?
    private var previousMessagesCursor: String?
    private var refreshCursor: String?
    private var messages: [ChatMessage] = []
    private var otherUser: User?

    var onInitialDataLoaded: (() -> Void)?
    var onOlderMessages: ((Int) -> Void)?
    var onNewerMessages: ((Int) -> Void)?
    var onNothingToLoad: (() -> Void)?
    var onMessageSent: ((Int) -> Void)?
    var onError: ((String) -> Void)?

    init(_ chat: Chat) {
        self.chat = chat
        self.chatId = ChatId.create(chat.id)
        self.pagingQuery = ChatMessagesPagingQuery(ChatMessagesQuery.inChat(self.chatId))
        self.pagingQuery?.limit = 10
    }

    init(_ userId: UserId) {
        self.chatId = ChatId.create(userId)
        self.pagingQuery = ChatMessagesPagingQuery(ChatMessagesQuery.inChat(self.chatId))
        Communities.user(userId, success: { user in
            self.otherUser = user
            Communities.chat(ChatId.create(userId), success: { chat in
                self.chat = chat
            }, failure: { error in
                print("Could not load chat, error: \(error)")
            })
        }, failure: { error in
            self.onError?("Could not load user, error: \(error)")
        })
    }

    func loadInitialChatMessages() {
        self.messages = []
        self.loadMessages(success: { [weak self] messages in
            self?.messages = messages
            self?.onInitialDataLoaded?()
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }

    func loadNewer() {
        if let cursor = self.refreshCursor, !cursor.isEmpty {
            self.pagingQuery?.nextMessagesCursor = cursor
            self.loadMessages(success: { [weak self] messages in
                self?.messages.append(contentsOf: messages)
                self?.onNewerMessages?(messages.count)
            }, failure: { [weak self] errorMessage in
                self?.onError?(errorMessage)
            })
        } else {
            print("nothing to load")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 10000000000), execute: {
                self.onNothingToLoad?()
            })
        }
    }

    func loadOlder() {
        if let cursor = self.previousMessagesCursor, !cursor.isEmpty {
            self.pagingQuery?.previousMessagesCursor = cursor
            self.loadMessages(success: { [weak self] messages in
                self?.messages.insert(contentsOf: messages, at: 0)
                self?.onOlderMessages?(messages.count)
            }, failure: { [weak self] errorMessage in
                self?.onError?(errorMessage)
            })
        } else {
            print("nothing to load")
            self.onNothingToLoad?()
        }
    }

    func chatTitle() -> String {
        if let chat = self.chat {
            return chat.title
        }
        if let user = self.otherUser {
            return user.displayName
        }
        return "Unknown"
    }

    func numberOfEntries() -> Int {
        return self.messages.count
    }

    func entry(at: Int) -> ChatMessage {
        return self.messages[at]
    }

    private func loadMessages(success: @escaping ([ChatMessage]) -> Void, failure: @escaping (String) -> Void) {
        Communities.chatMessages(self.pagingQuery!, success: { [weak self] result in
            self?.nextMessagesCursor = result.nextMessagesCursor
            self?.refreshCursor = result.refreshCursor
            self?.previousMessagesCursor = result.previousMessagesCursor
            success(result.messages)
        }, failure: { error in
            failure(error.localizedDescription)
        })
    }

    func sendMessage(_ content: ChatMessageContent) {
        Communities.sendChatMessage(content, target: self.chatId, success: { [weak self] message in
            self?.messages.append(message)
            if let strongSelf = self {
                print("num of messages after post: \(strongSelf.messages.count)")
                strongSelf.onMessageSent?(strongSelf.messages.count)

            }
        }, failure: { [weak self] error in
            self?.onError?(error.localizedDescription)
        })
    }
}
