//
//  UserIdCellView.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class UserIdCellView: UITableViewCell {

    var onFinishedEditing: ((String) -> Void)?

    internal let userIdField: UITextFieldWithCopyPaste = UITextFieldWithCopyPaste.init(frame: CGRect(x: 0, y: 0, width: 100, height: 30))

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUIElements()
    }

    func updateContent(userId: String) {
        self.userIdField.text = userId
    }

    internal func setupUIElements() {
        self.contentView.backgroundColor = .white
        self.contentView.isUserInteractionEnabled = true
        userIdField.delegate = self
        userIdField.becomeFirstResponder()
        userIdField.translatesAutoresizingMaskIntoConstraints = false
        userIdField.borderStyle = .roundedRect
        userIdField.backgroundColor = .white
        userIdField.layer.borderColor = UIColor.darkGray.cgColor
        userIdField.placeholder = "Enter User Id"

        self.contentView.addSubview(userIdField)
        let top = userIdField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4)
        let left = userIdField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 4)
        let right = userIdField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -4)
        let height = userIdField.heightAnchor.constraint(equalToConstant: 40.0)

        NSLayoutConstraint.activate([left, top, right, height])
    }

}

extension UserIdCellView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.onFinishedEditing?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.onFinishedEditing?(textField.text ?? "")
        return true
    }
}

