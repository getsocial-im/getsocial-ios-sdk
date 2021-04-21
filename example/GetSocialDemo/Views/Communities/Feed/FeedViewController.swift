//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol FeedTableViewControllerDelegate {
}

class FeedViewController: UIViewController {

    var viewModel: FeedModel = FeedModel()
    var delegate: FeedTableViewControllerDelegate?

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        self.tableView.register(ActivityTableViewCell.self, forCellReuseIdentifier: "activitytableviewcell")
        self.tableView.allowsSelection = false
        self.title = "DemoFeed"

        self.viewModel.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }

		self.viewModel.reactionUpdated = { index in
			self.hideActivityIndicatorView()
			let indexToReload = IndexPath.init(row: index, section: 0)
			self.tableView.reloadRows(at: [indexToReload], with: .automatic)
			self.showAlert(withText: "Reactions updated")
		}
        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error.localizedDescription)
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutTableView()
    }

	internal func executeQuery() {
		self.showActivityIndicatorView()
		self.viewModel.loadEntries()
	}

    internal func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(self.tableView)

        let top = tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

}

extension FeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activitytableviewcell") as? ActivityTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(activity: item)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension FeedViewController: ActivityTableViewCellDelegate {
    func onShowActions(_ ofActivity: String) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction.init(title: "Reaction details", style: .default, handler: { _ in
			if let activity = self.viewModel.findActivity(ofActivity) {
				let description = "Known reactors: \(activity.reactions), my reactions: \(activity.myReactions), reactions count: \(activity.reactionsCount)"
				self.showAlert(withText: description)
			}
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Comment details", style: .default, handler: { _ in
			if let activity = self.viewModel.findActivity(ofActivity) {
				let description = "Known commenters: \(activity.commenters), comments count: \(activity.commentsCount)"
				self.showAlert(withText: description)
			}
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Add reaction", style: .default, handler: { _ in
			self.showReactionInput(title: "Add reaction") { reaction in
				self.showActivityIndicatorView()
				self.viewModel.addReaction(reaction, activityId: ofActivity)
			}
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Set reaction", style: .default, handler: { _ in
			self.showReactionInput(title: "Set reaction") { reaction in
				self.showActivityIndicatorView()
				self.viewModel.setReaction(reaction, activityId: ofActivity)
			}
		}))
		actionSheet.addAction(UIAlertAction.init(title: "Remove reaction", style: .default, handler: { _ in
			self.showReactionInput(title: "Remove reaction") { reaction in
				self.showActivityIndicatorView()
				self.viewModel.removeReaction(reaction, activityId: ofActivity)
			}
		}))

		actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }

	private func showReactionInput(title: String, then: @escaping (String) -> Void) {

		let alert = UISimpleAlertViewController(title: title, message: "Enter reaction", cancelButtonTitle: "Cancel", otherButtonTitles: ["Ok"])
		alert?.addTextField(withPlaceholder: "like", defaultText: "like", isSecure: false)
		alert?.show(dismissHandler: { (selectedIndex, selectedTitle, didCancel) in
			if didCancel {
				return
			}
			let reaction = alert?.contentOfTextField(at: 0)
			then(reaction ?? "like")
		})
	}
}
