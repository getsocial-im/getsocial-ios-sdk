//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol ChatsViewControllerDelegate {
    func onShowChat(_ chat: Chat)
}

class ChatsViewController: UIViewController {

    var model: ChatsModel = ChatsModel()
    var tableView: UITableView = UITableView()
    var delegate: ChatsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(ChatCell.self, forCellReuseIdentifier: "chatcell")
        self.tableView.allowsSelection = false
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.title = "Chats"

        self.model.onChatsLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }
        self.model.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error)
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutTableView()
    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery() {
        self.showActivityIndicatorView()
        self.model.loadChats()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let actualPosition = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height - scrollView.frame.size.height
//        if actualPosition > 0 && self.viewModel.numberOfEntries() > 0 && actualPosition > contentHeight && !self.loadingOlders {
//            self.loadingOlders = true
//            self.showActivityIndicatorView()
//            self.viewModel.loadOlder()
//        }
    }
}

extension ChatsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

extension ChatsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatcell") as? ChatCell
        let item = self.model.entry(at: indexPath.row)
        cell?.onShowDetails = {
            self.showAlert(withTitle: "Details", andText: item.description)
        }
        cell?.delegate = self
        cell?.update(item)

        return cell ?? UITableViewCell()
    }
}

extension ChatsViewController: ChatCellDelegate {
    func onShowChat(_ chat: Chat) {
        self.delegate?.onShowChat(chat)
    }
}
