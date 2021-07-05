//
//  VotesListViewController.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 07/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class VoteListViewController: UIViewController {

	let viewModel: VotesListModel

	init(_ activityId: String) {
		self.viewModel = VotesListModel(activityId)
		super.init(nibName: nil, bundle: nil)

	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private lazy var tableViewController: GenericTableViewController<VoteView, GenericTableViewCell<VoteView>> = {
		let vc = GenericTableViewController<VoteView, GenericTableViewCell<VoteView>>()
		vc.configureCell = { indexPath, cell in
			let entry = self.viewModel.votes[indexPath.row]
			cell.view.update(entry)
		}
		vc.numberOfItems = {
			return self.viewModel.votes.count
		}
		vc.heightForRow = { _ in
			return 50
		}
		vc.tableView.estimatedRowHeight = 50
		return vc
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Votes"
		self.setupModel()
		self.install(self.tableViewController)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.viewModel.loadVotes()
	}

	private func setupModel() {
		self.viewModel.onVotesLoaded = {
			self.tableViewController.tableView.reloadData()
		}
		self.viewModel.onError = { error in
			self.showAlert(withTitle: "Error", andText: "Failed to load votes: \(error)")
		}
	}

}
