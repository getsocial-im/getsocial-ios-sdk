//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol PollsTableViewControllerDelegate {
	func onVote(_ activity: Activity)
	func onShowAllVotes(_ activity: Activity)
}

class PollsViewController: UIViewController {

    var viewModel: PollsModel
    var delegate: PollsTableViewControllerDelegate?

	var filterView: UISegmentedControl = UISegmentedControl(items: ["All", "Voted", "Not Voted"])
    var tableView: UITableView = UITableView()
	var selectedPollStatus: PollStatus = .withPoll

	init(_ query: ActivitiesQuery) {
		self.viewModel = ActivityPollsModel(query)
		super.init(nibName: nil, bundle: nil)
	}

	init(_ query: AnnouncementsQuery) {
		self.viewModel = AnnouncementPollsModel(query)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(PollTableViewCell.self, forCellReuseIdentifier: "polltableviewcell")
        self.tableView.allowsSelection = false
        self.title = "Polls"

        self.viewModel.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }

        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error.localizedDescription)
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

		// show all first time
		self.filterView.selectedSegmentIndex = 0
		self.filterView.addTarget(self, action: #selector(filterValueChanged(sender:)), for: .valueChanged)

    }

	@objc
	func filterValueChanged(sender: Any?) {
		switch self.filterView.selectedSegmentIndex {
			case 1:
				self.selectedPollStatus = .withPollVotedByMe
			case 2:
				self.selectedPollStatus = .withPollNotVotedByMe
			default:
				self.selectedPollStatus = .withPoll

		}
		self.executeQuery()
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutViews()
    }

	internal func executeQuery() {
		self.showActivityIndicatorView()
		self.viewModel.loadEntries(pollStatus: self.selectedPollStatus)
	}

    internal func layoutViews() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
		filterView.translatesAutoresizingMaskIntoConstraints = false

		self.view.addSubview(self.filterView)
		self.view.addSubview(self.tableView)

        NSLayoutConstraint.activate([
			filterView.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor),
			filterView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			filterView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			filterView.bottomAnchor.constraint(equalTo: self.tableView.topAnchor),
			tableView.topAnchor.constraint(equalTo: self.filterView.bottomAnchor),
			tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
		])
    }
}

extension PollsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension PollsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "polltableviewcell") as? PollTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(activity: item)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension PollsViewController: PollTableViewCellDelegate {
    func onShowActions(_ ofActivity: String) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
			if let activity = self.viewModel.findActivity(ofActivity) {
				let description = "Known voters: \(activity.poll?.knownVoters ?? [])"
				self.showAlert(withText: description)
			}
		}))
		if let activity = self.viewModel.findActivity(ofActivity) {
			if let source = activity.source, source.isActionAllowed(action: .react) {
				actionSheet.addAction(UIAlertAction.init(title: "Vote", style: .default, handler: { _ in
					if let activity = self.viewModel.findActivity(ofActivity) {
						self.delegate?.onVote(activity)
					}
				}))
			}
		}
		actionSheet.addAction(UIAlertAction.init(title: "All Votes", style: .default, handler: { _ in
			if let activity = self.viewModel.findActivity(ofActivity) {
				self.delegate?.onShowAllVotes(activity)
			}
		}))

		actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
