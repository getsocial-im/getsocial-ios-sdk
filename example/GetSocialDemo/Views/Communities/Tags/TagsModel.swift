//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class TagsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: (() -> Void)?
    var onError: ((Error) -> Void)?

    var query: TagsQuery?

    var tags: [String] = []

    func loadEntries(query: TagsQuery) {
        self.query = query
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func numberOfEntries() -> Int {
        return self.tags.count
    }

    func entry(at: Int) -> String {
        return self.tags[at]
    }

    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.tags(self.query!, success: { result in
            self.tags = result
            success?()
        }) { error in
            failure?(error)
        }
    }
}
