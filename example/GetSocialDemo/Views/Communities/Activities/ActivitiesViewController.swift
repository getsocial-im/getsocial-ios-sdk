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

	init(_ query: ActivitiesQuery) {
		self.viewModel = ActivitiesModel(query)
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

extension ActivitiesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
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
