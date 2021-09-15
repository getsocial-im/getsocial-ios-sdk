//
//  SortDialogViewController.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 10/08/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class SortOrderDialog: UITableViewController {

	public var onOptionSelected: ((Int) -> Void)?

	private let sortOptions: [(String, String)]
	private let selectedOptionIndex: Int

	required init(_ options: [(String, String)], selectedOptionIndex: Int) {
		self.selectedOptionIndex = selectedOptionIndex
		self.sortOptions = options

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.onOptionSelected?(indexPath.row)
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel?.text = self.sortOptions[indexPath.row].1 + " " + self.sortOptions[indexPath.row].0
		return cell
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.sortOptions.count
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	@objc
	func close(sender: Any?) {
		self.onOptionSelected?(self.selectedOptionIndex)
	}

}
