//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class TagsViewController: UIViewController {

    var viewModel: TagsModel = TagsModel()
    var loadingOlders: Bool = false
	var sortBy: String?
	var sortOrder: String?
	var showOnlyTrending = false

    var searchBar: UISearchBar = UISearchBar()
    var tableView: UITableView = UITableView()
	var sortButton: UIBarButtonItem!
	var trendingButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        self.tableView.register(TagTableViewCell.self, forCellReuseIdentifier: "tagtableviewcell")
        self.tableView.allowsSelection = false

		self.sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(showSort))
		self.trendingButton = UIBarButtonItem(title: "Only Trending", style: .plain, target: self, action: #selector(showTrending))
		self.navigationItem.rightBarButtonItems = [trendingButton]

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

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		self.executeQuery(searchTerm: self.searchBar.text)
    }

    override func viewWillLayoutSubviews() {
        layoutSearchBar()
        layoutTableView()
    }

	@objc
	func showTrending(sender: Any?) {
		self.showOnlyTrending.toggle()
		self.sortButton.isEnabled = !self.showOnlyTrending
		self.trendingButton.title = self.showOnlyTrending ? "All": "Only Trending"
		// use default sorting after changing isTrending
		self.sortBy = nil
		self.sortOrder = nil
		self.executeQuery(searchTerm: self.searchBar.text)
	}

	@objc
	func showSort(sender: Any?) {
		var sortOptions: [(String, String)] = []
		if self.showOnlyTrending {
			sortOptions = []
		} else {
			sortOptions = [
				("name",""),
				("name","-")
			]
		}
		let vc = SortOrderDialog(sortOptions, selectedOptionIndex: 3)
		vc.onOptionSelected = { selectedIndex in
			self.sortBy = sortOptions[selectedIndex].0
			self.sortOrder = sortOptions[selectedIndex].1
			self.navigationController?.popViewController(animated: true)
		}
		self.navigationController?.pushViewController(vc, animated: true)
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
        var query = TagsQuery.find(searchTerm ?? "")
		query = query.onlyTrending(self.showOnlyTrending)
        self.viewModel.loadEntries(query: query)
    }
}

extension TagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}

extension TagsViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.executeQuery(searchTerm: searchBar.text)
    }
}

extension TagsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagtableviewcell") as? TagTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(tag: item)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension TagsViewController: TagTableViewCellDelegate {
    func onShowActions(_ tag: String) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction.init(title: "Show feed", style: .default, handler: { _ in
            let query = ActivitiesQuery.everywhere().withTag(tag)
            GetSocialUIActivityFeedView(for: query).show()
        }))
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
