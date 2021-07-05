//
//  GenericTableViewCell.swift
//
//  Created by Gábor Vass on 21/03/2021.
//

import Foundation
import UIKit

class GenericTableViewCell<View: UIView>: UITableViewCell {

	lazy var view: View = {
		return View()
	}()

	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		self.selectionStyle = .none
		self.view.translatesAutoresizingMaskIntoConstraints = false

		self.contentView.addSubview(self.view)
		NSLayoutConstraint.activate([
			self.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
			self.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
			self.view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			self.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
		])
	}

}
