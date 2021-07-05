//
//  CreatePollView.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 26/04/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class CreatePollView: UIViewController {

	private let textLabel = UILabel()
	private let endDateLabel = UILabel()
	private let selectDateLabel = UILabel()
	private let allowMultipleVotesLabel = UILabel()

	private let text = UITextFieldWithCopyPaste()
	private let endDate = UITextFieldWithCopyPaste()
	private let endDatePicker = UIDatePicker()
	private let allowMultipleVotes = UISwitch()

	private let addOption = UIButton(type: .roundedRect)

	private let createButton = UIButton(type: .roundedRect)

	private let optionsStack = UIStackView()
	private let scrollView = UIScrollView()

	private let viewModel: CreatePollViewModel

	init(_ postTarget: PostActivityTarget) {
		self.viewModel = CreatePollViewModel(postTarget)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewDidLoad() {
		setup()
	}

	private func setup() {
		// setup keyboard observers
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

		self.view.backgroundColor = UIDesign.Colors.viewBackground

		self.scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(self.scrollView)

		let stackview = UIStackView()
		stackview.translatesAutoresizingMaskIntoConstraints = false
		stackview.axis = .vertical
		stackview.spacing = 4
		scrollView.addSubview(stackview)

		textLabel.text = "Text"
		endDateLabel.text = "End Date"
		selectDateLabel.text = "Select"
		allowMultipleVotesLabel.text = "Allow Multiple"

		text.textColor = UIDesign.Colors.inputText
		text.backgroundColor = .lightGray

		endDate.backgroundColor = .lightGray

		endDatePicker.addTarget(self, action: #selector(dateChanged(sender:)), for: .valueChanged)

		stackview.addFormRow(elements: [textLabel, text])
		stackview.addFormRow(elements: [endDateLabel, endDate])
		stackview.addFormRow(elements: [selectDateLabel, endDatePicker])
		stackview.addFormRow(elements: [allowMultipleVotesLabel, allowMultipleVotes])

		addOption.setTitle("Add Option", for: .normal)
		addOption.addTarget(self, action: #selector(addOption(sender:)), for: .touchUpInside)

		stackview.addArrangedSubview(addOption)

		optionsStack.axis = .vertical
		optionsStack.translatesAutoresizingMaskIntoConstraints = false
		scrollView.addSubview(optionsStack)

		createButton.setTitle("Create", for: .normal)
		createButton.addTarget(self, action: #selector(create(sender:)), for: .touchUpInside)

		stackview.addArrangedSubview(createButton)

		NSLayoutConstraint.activate([
			scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			stackview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			stackview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			stackview.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
			optionsStack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			optionsStack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			optionsStack.topAnchor.constraint(equalTo: stackview.bottomAnchor),
			optionsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
		])

	}

	// MARK: Handle keyboard

	@objc
	private func keyboardWillShow(notification: NSNotification) {
		let userInfo = notification.userInfo
		if let keyboardSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			self.scrollView.contentInset = UIEdgeInsets.init(top: self.scrollView.contentInset.top, left: self.scrollView.contentInset.left, bottom: keyboardSize.height, right: self.scrollView.contentInset.right)
		}
	}

	@objc
	private func keyboardWillHide(notification: NSNotification) {
		self.scrollView.contentInset = UIEdgeInsets.init(top: self.scrollView.contentInset.top, left: self.scrollView.contentInset.left, bottom: 0, right: self.scrollView.contentInset.right)
	}

	@objc
	private func dateChanged(sender: UIView) {
		let selectedDate = self.endDatePicker.date
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm"
		self.endDate.text = formatter.string(from: selectedDate)
	}

	@objc
	private func create(sender: UIView) {
		let activityContent = ActivityContent()
		let pollContent = PollContent()
		pollContent.allowMultipleVotes = self.allowMultipleVotes.isOn
		if (self.endDate.text?.count ?? 0) > 0 {
			pollContent.endDate = self.endDatePicker.date
		}
		var optionsAreValid = true
		var pollOptions: [PollOptionContent] = []
		self.optionsStack.arrangedSubviews.forEach {
			let view = $0 as! PollOptionView
			switch view.collectData() {
				case .success(let pollOption):
					pollOptions.append(pollOption)
				case .failure(let error):
					optionsAreValid = false
					self.showAlert(withTitle: "Error", andText: "\(error)")
			}
		}
		guard optionsAreValid else {
			return
		}
		pollContent.options = pollOptions
		activityContent.text = self.text.text
		activityContent.poll = pollContent
		self.viewModel.onSuccess = { [weak self] in
			self?.hideActivityIndicatorView()
			self?.showAlert(withText: "Poll created")
			self?.clearFields()
		}
		self.viewModel.onError = { [weak self] error in
			self?.hideActivityIndicatorView()
			self?.showAlert(withTitle: "Error", andText: error)
		}
		self.showActivityIndicatorView()
		self.viewModel.createPoll(activityContent)
	}

	@objc
	private func addOption(sender: UIView) {
		let view = PollOptionView()
		view.onRemoveTap = {
			self.optionsStack.removeArrangedSubview(view)
			view.removeFromSuperview()
		}
		self.optionsStack.addArrangedSubview(view)
	}

	func clearFields() {
		self.optionsStack.arrangedSubviews.forEach {
			self.optionsStack.removeArrangedSubview($0)
			$0.removeFromSuperview()
		}
		self.text.text = nil
		self.endDate.text = nil
		self.allowMultipleVotes.isOn = false
	}


}
