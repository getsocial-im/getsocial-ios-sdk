//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol TopicTableViewControllerDelegate {
    func onFollowersClicked(ofTopic: String)
    func onShowFeedClicked(ofTopic: String)
    func onPostActivityClicked(topic: String)
}

class TopicsViewController: UIViewController {

    var viewModel: TopicsModel = TopicsModel()
    var delegate: TopicTableViewControllerDelegate?
    var loadingOlders: Bool = false

    var searchBar: UISearchBar = UISearchBar()
    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        self.tableView.register(TopicTableViewCell.self, forCellReuseIdentifier: "topictableviewcell")
        self.tableView.allowsSelection = false
        self.title = "Topics"

        self.viewModel.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }
        self.viewModel.onDidOlderLoad = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
            self.loadingOlders = false
        }

        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error.localizedDescription)
        }
        self.viewModel.topicFollowed = { itemIndex in
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Topic followed")
        }
        self.viewModel.topicUnfollowed = { itemIndex in
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Topic unfollowed")
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery(searchTerm: nil)
    }

    override func viewWillLayoutSubviews() {
        layoutSearchBar()
        layoutTableView()
    }

    internal func layoutSearchBar() {

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        let top = searchBar.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)

        NSLayoutConstraint.activate([left, top, right])

        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = self

    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery(searchTerm: String?) {
        self.showActivityIndicatorView()
        let query = TopicsQuery.find(searchTerm: searchTerm ?? "")
        self.viewModel.loadEntries(query: query)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height - scrollView.frame.size.height
        if actualPosition > 0 && self.viewModel.numberOfEntries() > 0 && actualPosition > contentHeight && !self.loadingOlders {
            self.loadingOlders = true
            self.showActivityIndicatorView()
            self.viewModel.loadOlder()
        }
    }
}

extension TopicsViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.executeQuery(searchTerm: searchBar.text)
    }
}

extension TopicsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
}

extension TopicsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topictableviewcell") as? TopicTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(topic: item)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension TopicsViewController: TopicTableViewCellDelegate {
    func onFollowersClicked(ofTopic: String) {
        self.delegate?.onFollowersClicked(ofTopic: ofTopic)
    }

    func onFollowButtonClicked(ofTopic: String) {
        self.viewModel.followTopic(ofTopic)
    }

    func onTopicClicked(_ id: String) {
        if let topic = self.viewModel.findTopic(id) {
            self.showAlert(withText: topic.description)
        }
    }

    func onShowFeedClicked(_ id: String) {
        if let topic = self.viewModel.findTopic(id) {
            self.delegate?.onShowFeedClicked(ofTopic: topic.id)
        }
    }

    func onPostActivityClicked(_ id: String) {
        if let topic = self.viewModel.findTopic(id) {
            self.delegate?.onPostActivityClicked(topic: topic.id)
        }
    }
}
