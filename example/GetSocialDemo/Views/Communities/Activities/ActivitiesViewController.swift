//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialSDK

class ActivitiesViewController: UIViewController {

    let viewModel: ActivitiesModel

    var tableView: UITableView = UITableView()
	var sortBy: String?
	var sortOrder: String?
	var showOnlyTrending = false

	var sortButton: UIBarButtonItem!
	var trendingButton: UIBarButtonItem!

	let initialQuery: ActivitiesQuery

	var searchBar: UISearchBar = UISearchBar()
	var labelSearchBar = UISearchBar()
	var propertySearchBar = UISearchBar()

	init(_ query: ActivitiesQuery) {
		self.initialQuery = query
		self.viewModel = ActivitiesModel()
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        self.tableView.register(ActivitiesTableViewCell.self, forCellReuseIdentifier: "activitiestableviewcell")
        self.tableView.allowsSelection = false

		self.sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(showSort))
		self.trendingButton = UIBarButtonItem(title: "Only Trending", style: .plain, target: self, action: #selector(showTrending))
		self.navigationItem.rightBarButtonItems = [trendingButton]

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

		self.view.addSubview(self.searchBar)
		self.view.addSubview(self.labelSearchBar)
		self.view.addSubview(self.propertySearchBar)
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		self.executeQuery(searchTerm: self.searchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
    }

    override func viewWillLayoutSubviews() {
		layoutSearchFields()
		layoutTableView()
    }

	private func executeQuery(searchTerm: String?, label: String?, property: String?) {
		self.showActivityIndicatorView()
		var query = self.initialQuery.copy() as! ActivitiesQuery
		if let searchTerm = searchTerm {
			query = query.withText(searchTerm)
		}
		if let searchLabel = label, !searchLabel.isEmpty {
			query = query.withLabels(searchLabel.components(separatedBy: ","))
		}
		if let searchProperties = property, !searchProperties.isEmpty {
			var propertyDictionary: [String: String] = [:]
			let dictElements = searchProperties.components(separatedBy: ",")
			dictElements.forEach {
				let components = $0.components(separatedBy: "=")
				if let key = components.first, let value = components.last {
					propertyDictionary[key] = value
				}
			}
			if !propertyDictionary.isEmpty {
				query = query.withProperties(propertyDictionary)
			}
		}

		query = query.onlyTrending(self.showOnlyTrending)
		self.viewModel.loadEntries(query)
	}

	internal func layoutSearchFields() {

		searchBar.translatesAutoresizingMaskIntoConstraints = false
		let top = searchBar.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
		let left = searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
		let right = searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)

		NSLayoutConstraint.activate([left, top, right])

		searchBar.enablesReturnKeyAutomatically = false
		searchBar.delegate = self

		labelSearchBar.translatesAutoresizingMaskIntoConstraints = false
		labelSearchBar.placeholder = "label1,label2"
		NSLayoutConstraint.activate([
			self.labelSearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			self.labelSearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			self.labelSearchBar.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor),
		])
		labelSearchBar.enablesReturnKeyAutomatically = false
		labelSearchBar.delegate = self

		propertySearchBar.translatesAutoresizingMaskIntoConstraints = false
		propertySearchBar.placeholder = "key:value,key1:value1"
		NSLayoutConstraint.activate([
			self.propertySearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			self.propertySearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			self.propertySearchBar.topAnchor.constraint(equalTo: self.labelSearchBar.bottomAnchor),
		])
		propertySearchBar.enablesReturnKeyAutomatically = false
		propertySearchBar.delegate = self
	}

    internal func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(self.tableView)

        let top = tableView.topAnchor.constraint(equalTo: self.propertySearchBar.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

	@objc
	func showTrending(sender: Any?) {
		self.showOnlyTrending.toggle()
		self.sortButton.isEnabled = !self.showOnlyTrending
		self.trendingButton.title = self.showOnlyTrending ? "All": "Only Trending"
		// use default sorting after changing isTrending
		self.sortBy = "nil"
		self.sortOrder = nil
		self.executeQuery(searchTerm: self.searchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
	}

	@objc
	func showSort(sender: Any?) {
		var sortOptions: [(String, String)] = []
		if self.showOnlyTrending {
			sortOptions = []
		} else {
			sortOptions = [
				("createdAt",""),
				("createdAt","-")]
		}
		let vc = SortOrderDialog(sortOptions, selectedOptionIndex: 3)
		vc.onOptionSelected = { selectedIndex in
			self.sortBy = sortOptions[selectedIndex].0
			self.sortOrder = sortOptions[selectedIndex].1
			self.navigationController?.popViewController(animated: true)
		}
		self.navigationController?.pushViewController(vc, animated: true)
	}

}

extension ActivitiesViewController: UISearchBarDelegate {

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		self.executeQuery(searchTerm: self.searchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
	}
}

extension ActivitiesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

extension ActivitiesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activitiestableviewcell") as? ActivitiesTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(activity: item)

        return cell ?? UITableViewCell()
    }
}
