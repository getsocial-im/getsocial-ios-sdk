//
//  VoteViewController.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 03/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class VoteViewController: UIViewController {
	let tableView = UITableView()
	let addVotesButton = UIButton(type: .roundedRect)
	let setVotesButton = UIButton(type: .roundedRect)
	let removeVotesButton = UIButton(type: .roundedRect)

	let viewModel: VoteViewModel

	init(_ activityId: String) {
		self.viewModel = VoteViewModel(activityId)
		super.init(nibName: nil, bundle: nil)

	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.viewModel.onVotesAdded = { [weak self] in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Success", andText: "Votes added")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onVotesSet = { [weak self] in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Success", andText: "Votes set")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onVotesRemoved = { [weak self] in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Success", andText: "Votes removed")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onVotesAddedError = { [weak self] error in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Error", andText: "Failed to add votes: \(error)")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onVotesSetError = { [weak self] error in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Error", andText: "Failed to set votes: \(error)")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onVotesRemovedError = { [weak self] error in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Error", andText: "Failed to remove votes: \(error)")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.viewModel.onError = { [weak self] error in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.showAlert(withTitle: "Error", andText: "Error: \(error)")
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}

		self.viewModel.onPollOptionsAvailable = { [weak self] in
			guard let self = self else { return }
			self.hideActivityIndicatorView()
			self.tableView.reloadData()
			self.removeVotesButton.isEnabled = self.viewModel.isRemoveButtonEnabled()
		}
		self.tableView.register(VoteOptionTableViewCell.self, forCellReuseIdentifier: "voteoptiontableviewcell")
		self.tableView.delegate = self
		self.tableView.dataSource = self
	}

	override func viewDidAppear(_ animated: Bool) {
		//showActivityIndicatorView()
		self.viewModel.loadPoll()
	}

	override func viewWillLayoutSubviews() {
		layoutViews()
	}

	internal func layoutViews() {
		self.view.backgroundColor = UIDesign.Colors.viewBackground
		self.tableView.translatesAutoresizingMaskIntoConstraints = false

		let buttonsView = UIStackView()
		buttonsView.axis = .horizontal
		buttonsView.distribution = .fillEqually
		buttonsView.translatesAutoresizingMaskIntoConstraints = false
		buttonsView.addArrangedSubview(addVotesButton)
		buttonsView.addArrangedSubview(setVotesButton)
		buttonsView.addArrangedSubview(removeVotesButton)

		addVotesButton.setTitle("Add Votes", for: .normal)
		addVotesButton.addTarget(self, action: #selector(addVotes(sender:)), for: .touchUpInside)

		setVotesButton.setTitle("Set Votes", for: .normal)
		setVotesButton.addTarget(self, action: #selector(setVotes(sender:)), for: .touchUpInside)

		removeVotesButton.setTitle("Remove Votes", for: .normal)
		removeVotesButton.addTarget(self, action: #selector(removeVotes(sender:)), for: .touchUpInside)

		self.view.addSubview(buttonsView)
		self.view.addSubview(self.tableView)

		NSLayoutConstraint.activate([
			buttonsView.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor),
			buttonsView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			buttonsView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			buttonsView.bottomAnchor.constraint(equalTo: self.tableView.topAnchor),
			buttonsView.heightAnchor.constraint(equalToConstant: 30),
			tableView.topAnchor.constraint(equalTo: buttonsView.bottomAnchor),
			tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
		])
	}

	@objc
	func addVotes(sender: Any?) {
		//showActivityIndicatorView()
		self.viewModel.addVotes()
	}

	@objc
	func setVotes(sender: Any?) {
		//showActivityIndicatorView()
		self.viewModel.setVotes()
	}

	@objc
	func removeVotes(sender: Any?) {
		//showActivityIndicatorView()
		self.viewModel.removeVotes()
	}

}

extension VoteViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 120
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = self.viewModel.pollOptions[indexPath.row]
		self.viewModel.markOption(item.optionId)
	}

	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		let item = self.viewModel.pollOptions[indexPath.row]
		self.viewModel.markOption(item.optionId)
	}
}

extension VoteViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.viewModel.pollOptions.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "voteoptiontableviewcell") as? VoteOptionTableViewCell
		let item = self.viewModel.pollOptions[indexPath.row]
		let selected = self.viewModel.selectedPollOptions.contains(item.optionId)

		cell?.update(item, selected: selected)

		return cell ?? UITableViewCell()
	}
}
