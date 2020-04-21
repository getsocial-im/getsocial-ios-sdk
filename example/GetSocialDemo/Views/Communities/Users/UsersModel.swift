//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class UsersModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: (() -> Void)?
    var onError: ((Error) -> Void)?

    var pagingQuery: UsersPagingQuery?
    var query: UsersQuery?

    var users: [User] = []
    var nextCursor: String = ""

    func loadEntries(query: UsersQuery) {
        self.query = query
        self.pagingQuery = UsersPagingQuery.init(query: query)
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.users.removeAll()
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadOlder() {
        if self.nextCursor.count == 0 {
            onDidOlderLoad?()
        }
        self.pagingQuery?.nextCursor = self.nextCursor
        executeQuery(success: onDidOlderLoad, failure: onError)
    }

    func numberOfEntries() -> Int {
        return self.users.count
    }

    func entry(at: Int) -> User {
        return self.users[at]
    }

    func find(_ id: String) -> User? {
        return self.users.filter {
            return $0.userId == id
        }.first
    }

    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.users(query: self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.users.append(contentsOf: result.users)
            success?()
        }) { error in
            failure?(error)
        }
    }

}
