//
//  GenericTableViewController.swift
//
//  Created by Gábor Vass on 21/03/2021.
//

import Foundation
import UIKit

class GenericTableViewController<View: UIView, Cell: GenericTableViewCell<View>>: UITableViewController {

	var numberOfItems: () -> Int = {0} {
		didSet {
			tableView.reloadData()
		}
	}

	var configureCell: ((IndexPath, Cell) -> Void)?

	var heightForRow: ((IndexPath) -> CGFloat)?

	var didSelectRow: ((IndexPath) -> Void)?

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.tableFooterView = UIView()
		tableView.separatorInset = UIEdgeInsets.zero
		tableView.register(Cell.self, forCellReuseIdentifier: "cell")
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return heightForRow?(indexPath) ?? 44.0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return numberOfItems()
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? Cell else {
			return UITableViewCell()
		}
		configureCell?(indexPath, cell)
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelectRow?(indexPath)
	}
}
