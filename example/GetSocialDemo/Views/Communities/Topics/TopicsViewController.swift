//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol TopicTableViewControllerDelegate {
    func onShowFollowers(_ ofTopic: String)
	func onShowPolls(_ inTopic: String)
	func onShowAnnouncementsPolls(_ inTopic: String)
	func onShowFeed(_ ofTopic: String, byCurrentUser: Bool)
    func onPostActivity(_ topic: String)
	func onCreatePoll(_ topic: String)
	func onShowPlainFeed(_ ofTopic: String)
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
        self.viewModel.onDidOlderLoad = { needReload in
            self.hideActivityIndicatorView()
            self.loadingOlders = false
            if needReload {
                self.tableView.reloadData()
            }
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
        let query = TopicsQuery.find(searchTerm ?? "")
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
    func onShowActions(_ topicId: String, isFollowed: Bool, canPost: Bool) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
            if let topic = self.viewModel.findTopic(topicId) {
                self.showAlert(withText: topic.description)
            }
        }))
        actionSheet.addAction(UIAlertAction.init(title: "Feed UI", style: .default, handler: { _ in
			self.delegate?.onShowFeed(topicId, byCurrentUser: false)
        }))
		actionSheet.addAction(UIAlertAction.init(title: "Feed", style: .default, handler: { _ in
			self.delegate?.onShowPlainFeed(topicId)
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Activities with Polls", style: .default, handler: { _ in
			self.delegate?.onShowPolls(topicId)
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Announcements with Polls", style: .default, handler: { _ in
			self.delegate?.onShowAnnouncementsPolls(topicId)
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Activities created by Me", style: .default, handler: { _ in
			self.delegate?.onShowFeed(topicId, byCurrentUser: true)
		}))
        actionSheet.addAction(UIAlertAction.init(title: isFollowed ? "Unfollow" : "Follow", style: .default, handler: { _ in
            self.viewModel.followTopic(topicId)
        }))
        actionSheet.addAction(UIAlertAction.init(title: "Followers", style: .default, handler: { _ in
            self.delegate?.onShowFollowers(topicId)
        }))
        if canPost {
            actionSheet.addAction(UIAlertAction.init(title: "Post", style: .default, handler: { _ in
                self.delegate?.onPostActivity(topicId)
            }))
			actionSheet.addAction(UIAlertAction.init(title: "Create Poll", style: .default, handler: { _ in
				self.delegate?.onCreatePoll(topicId)
			}))
        }
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
		self.present(actionSheet, animated: true, completion: nil)
    }
}
