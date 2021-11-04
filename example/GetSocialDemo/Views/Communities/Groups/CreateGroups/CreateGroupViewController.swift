//
//  CreateGroupsViewController.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class CreateGroupViewController: UIViewController {
    
    var oldGroup: Group?
    var model: CreateGroupModel
    
    private let scrollView = UIScrollView()
    private let idLabel = UILabel()
    private let idText = UITextFieldWithCopyPaste()
    
    private let titleLabel = UILabel()
    private let titleText = UITextFieldWithCopyPaste()

    private let descriptionLabel = UILabel()
    private let descriptionText = UITextFieldWithCopyPaste()

    private let avatarImageUrlLabel = UILabel()
    private let avatarImageUrlText = UITextFieldWithCopyPaste()
    
    private let avatarImage = UIImageView()
    private var avatarImageHeightConstraint: NSLayoutConstraint?
    private let avatarAddImageButton = UIButton(type: .roundedRect)
    private let avatarClearImageButton = UIButton(type: .roundedRect)

    private let allowPostLabel = UILabel()
    private let allowPostSegmentedControl = UISegmentedControl()
    
    private let allowInteractLabel = UILabel()
    private let allowInteractSegmentedControl = UISegmentedControl()

    private let property1KeyLabel = UILabel()
    private let property1KeyText = UITextFieldWithCopyPaste()

    private let property1ValueLabel = UILabel()
    private let property1ValueText = UITextFieldWithCopyPaste()

    private let isDiscoverableLabel = UILabel()
    private let isDiscoverableSwitch = UISwitch()
    
    private let isPrivateLabel = UILabel()
    private let isPrivateSwitch = UISwitch()

	private let labelsLabel = UILabel()
	private let labelsValueText = UITextFieldWithCopyPaste()

    private let createButton = UIButton(type: .roundedRect)
    
    private var isKeyboardShown = false
    private let imagePicker =  UIImagePickerController()

    required init(_ groupToEdit: Group? = nil) {
        self.oldGroup = groupToEdit
        self.model = CreateGroupModel(oldGroupId: groupToEdit?.id)
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
        setupModel()
    }
    
    private func setupModel() {
        self.model.onGroupCreated = { [weak self] group in
            self?.hideActivityIndicatorView()
            self?.showAlert(withTitle: "Group created", andText: group.description)
        }
        self.model.onGroupUpdated = { [weak self] group in
            self?.hideActivityIndicatorView()
            self?.showAlert(withTitle: "Group updated", andText: group.description)
        }
        self.model.onError = { [weak self] error in
            self?.hideActivityIndicatorView()
            self?.showAlert(withTitle: "Error", andText: "Failed to create group, error: \(error)")
        }
    }
    
    private func setup() {
        // setup keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.view.backgroundColor = UIDesign.Colors.viewBackground
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height + 300)
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        setupIdRow()
        setupTitleRow()
        setupDescriptionRow()
        setupAvatarImageUrlRow()
        setupAvatarImageRow()
        setupAllowPostRow()
        setupAllowInteractRow()
        setupProperty1KeyRow()
        setupProperty1ValueRow()
        setupIsDiscoverableRow()
        setupIsPrivateRow()
		setupLabelsRow()
        setupCreateButton()
    }
    
    private func setupIdRow() {
        self.idLabel.translatesAutoresizingMaskIntoConstraints = false
        self.idLabel.text = "Group ID"
        self.idLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.idLabel)
        
        NSLayoutConstraint.activate([
            self.idLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.idLabel.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -8),
            self.idLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 8),
            self.idLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.idText.translatesAutoresizingMaskIntoConstraints = false
        self.idText.borderStyle = .roundedRect
        self.idText.isEnabled = true
        if let oldGroup = self.oldGroup {
            self.idText.text = oldGroup.id
            self.idText.isEnabled = false
        }
        self.scrollView.addSubview(self.idText)
        NSLayoutConstraint.activate([
            self.idText.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.idText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.idText.topAnchor.constraint(equalTo: self.idLabel.bottomAnchor, constant: 4),
            self.idText.heightAnchor.constraint(equalToConstant: 30)
        ])
        
    }

    private func setupTitleRow() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.text = "Name"
        self.titleLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.titleLabel)
        
        NSLayoutConstraint.activate([
            self.titleLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.titleLabel.topAnchor.constraint(equalTo: self.idText.bottomAnchor, constant: 8),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.titleText.translatesAutoresizingMaskIntoConstraints = false
        self.titleText.borderStyle = .roundedRect
        self.titleText.text = self.oldGroup?.title
        self.scrollView.addSubview(self.titleText)
        NSLayoutConstraint.activate([
            self.titleText.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.titleText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.titleText.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4),
            self.titleText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupDescriptionRow() {
        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionLabel.text = "Description"
        self.descriptionLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.descriptionLabel)
        
        NSLayoutConstraint.activate([
            self.descriptionLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.descriptionLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.descriptionLabel.topAnchor.constraint(equalTo: self.titleText.bottomAnchor, constant: 8),
            self.descriptionLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.descriptionText.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionText.borderStyle = .roundedRect
        self.descriptionText.text = self.oldGroup?.groupDescription
        self.scrollView.addSubview(self.descriptionText)
        NSLayoutConstraint.activate([
            self.descriptionText.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.descriptionText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.descriptionText.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 4),
            self.descriptionText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupAvatarImageUrlRow() {
        self.avatarImageUrlLabel.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImageUrlLabel.text = "Avatar URL"
        self.avatarImageUrlLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.avatarImageUrlLabel)
        
        NSLayoutConstraint.activate([
            self.avatarImageUrlLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.avatarImageUrlLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.avatarImageUrlLabel.topAnchor.constraint(equalTo: self.descriptionText.bottomAnchor, constant: 8),
            self.avatarImageUrlLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.avatarImageUrlText.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImageUrlText.borderStyle = .roundedRect
        self.avatarImageUrlText.text = self.oldGroup?.avatarUrl
        self.scrollView.addSubview(self.avatarImageUrlText)
        NSLayoutConstraint.activate([
            self.avatarImageUrlText.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.avatarImageUrlText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.avatarImageUrlText.topAnchor.constraint(equalTo: self.avatarImageUrlLabel.bottomAnchor, constant: 4),
            self.avatarImageUrlText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupAvatarImageRow() {
        self.avatarImage.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImage.isHidden = true
        self.scrollView.addSubview(self.avatarImage)

        self.avatarAddImageButton.translatesAutoresizingMaskIntoConstraints = false
        self.avatarAddImageButton.isHidden = false
        self.avatarAddImageButton.setTitle("Select", for: .normal)
        self.avatarAddImageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        self.scrollView.addSubview(self.avatarAddImageButton)

        self.avatarClearImageButton.translatesAutoresizingMaskIntoConstraints = false
        self.avatarClearImageButton.isHidden = true
        self.avatarClearImageButton.setTitle("Clear", for: .normal)
        self.avatarClearImageButton.addTarget(self, action: #selector(clearImage), for: .touchUpInside)
        self.scrollView.addSubview(self.avatarClearImageButton)

        self.avatarImageHeightConstraint = self.avatarImage.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            self.avatarImage.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.avatarImage.topAnchor.constraint(equalTo: self.avatarImageUrlText.bottomAnchor, constant: 8),
            self.avatarImage.widthAnchor.constraint(equalToConstant: 200),
            self.avatarImageHeightConstraint!,
        ])

        NSLayoutConstraint.activate([
            self.avatarAddImageButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.avatarAddImageButton.topAnchor.constraint(equalTo: self.avatarImage.bottomAnchor, constant: 8),
            self.avatarAddImageButton.heightAnchor.constraint(equalToConstant: 30),
            self.avatarAddImageButton.widthAnchor.constraint(equalToConstant: 100)
        ])

        NSLayoutConstraint.activate([
            self.avatarClearImageButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 8),
            self.avatarClearImageButton.topAnchor.constraint(equalTo: self.avatarImage.bottomAnchor, constant: 8),
            self.avatarClearImageButton.heightAnchor.constraint(equalToConstant: 30),
            self.avatarClearImageButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func setupAllowPostRow() {
        self.allowPostLabel.translatesAutoresizingMaskIntoConstraints = false
        self.allowPostLabel.text = "Allow Post"
        self.allowPostLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.allowPostLabel)
        
        NSLayoutConstraint.activate([
            self.allowPostLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.allowPostLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.allowPostLabel.topAnchor.constraint(equalTo: self.avatarAddImageButton.bottomAnchor, constant: 8),
            self.allowPostLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.allowPostSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.allowPostSegmentedControl.insertSegment(withTitle: "Owner", at: 0, animated: false)
        self.allowPostSegmentedControl.insertSegment(withTitle: "Admin", at: 1, animated: false)
        self.allowPostSegmentedControl.insertSegment(withTitle: "Member", at: 2, animated: false)
        self.allowPostSegmentedControl.selectedSegmentIndex = 0
        if let oldGroup = self.oldGroup {
            let oldValue = oldGroup.settings.permissions[CommunitiesAction.post]?.rawValue ?? 0
            if oldValue == 3 {
                self.allowPostSegmentedControl.selectedSegmentIndex = 2
            } else {
                self.allowPostSegmentedControl.selectedSegmentIndex = oldValue
            }
        }
        self.scrollView.addSubview(self.allowPostSegmentedControl)
        
        NSLayoutConstraint.activate([
            self.allowPostSegmentedControl.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.allowPostSegmentedControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.allowPostSegmentedControl.topAnchor.constraint(equalTo: self.allowPostLabel.bottomAnchor, constant: 8),
            self.allowPostSegmentedControl.heightAnchor.constraint(equalToConstant: 20)
        ])

    }
    
    private func setupAllowInteractRow() {
        self.allowInteractLabel.translatesAutoresizingMaskIntoConstraints = false
        self.allowInteractLabel.text = "Allow Interact"
        self.allowInteractLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.allowInteractLabel)
        
        NSLayoutConstraint.activate([
            self.allowInteractLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.allowInteractLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.allowInteractLabel.topAnchor.constraint(equalTo: self.allowPostSegmentedControl.bottomAnchor, constant: 8),
            self.allowInteractLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.allowInteractSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.allowInteractSegmentedControl.insertSegment(withTitle: "Owner", at: 0, animated: false)
        self.allowInteractSegmentedControl.insertSegment(withTitle: "Admin", at: 1, animated: false)
        self.allowInteractSegmentedControl.insertSegment(withTitle: "Member", at: 2, animated: false)
        self.allowInteractSegmentedControl.selectedSegmentIndex = 0
        if let oldGroup = self.oldGroup {
            let oldValue = oldGroup.settings.permissions[CommunitiesAction.comment]?.rawValue ?? 0
            if oldValue == 3 {
                self.allowInteractSegmentedControl.selectedSegmentIndex = 2
            } else {
                self.allowInteractSegmentedControl.selectedSegmentIndex = oldValue
            }
        }
        self.scrollView.addSubview(self.allowInteractSegmentedControl)
        
        NSLayoutConstraint.activate([
            self.allowInteractSegmentedControl.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
            self.allowInteractSegmentedControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.allowInteractSegmentedControl.topAnchor.constraint(equalTo: self.allowInteractLabel.bottomAnchor, constant: 8),
            self.allowInteractSegmentedControl.heightAnchor.constraint(equalToConstant: 20)
        ])

    }
    
    private func setupProperty1KeyRow() {
        self.property1KeyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.property1KeyLabel.text = "Property key"
        self.property1KeyLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.property1KeyLabel)
        
        NSLayoutConstraint.activate([
            self.property1KeyLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.property1KeyLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.property1KeyLabel.topAnchor.constraint(equalTo: self.allowInteractSegmentedControl.bottomAnchor, constant: 8),
            self.property1KeyLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.property1KeyText.translatesAutoresizingMaskIntoConstraints = false
        self.property1KeyText.borderStyle = .roundedRect
        self.property1KeyText.text = self.oldGroup?.settings.properties.first?.key
        self.scrollView.addSubview(self.property1KeyText)
        NSLayoutConstraint.activate([
            self.property1KeyText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.property1KeyText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.property1KeyText.topAnchor.constraint(equalTo: self.property1KeyLabel.bottomAnchor, constant: 4),
            self.property1KeyText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupProperty1ValueRow() {
        self.property1ValueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.property1ValueLabel.text = "Property value"
        self.property1ValueLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.property1ValueLabel)
        
        NSLayoutConstraint.activate([
            self.property1ValueLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.property1ValueLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.property1ValueLabel.topAnchor.constraint(equalTo: self.property1KeyText.bottomAnchor, constant: 8),
            self.property1ValueLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.property1ValueText.translatesAutoresizingMaskIntoConstraints = false
        self.property1ValueText.borderStyle = .roundedRect
        self.property1ValueText.text = self.oldGroup?.settings.properties.first?.value
        self.scrollView.addSubview(self.property1ValueText)
        NSLayoutConstraint.activate([
            self.property1ValueText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.property1ValueText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.property1ValueText.topAnchor.constraint(equalTo: self.property1ValueLabel.bottomAnchor, constant: 4),
            self.property1ValueText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupIsDiscoverableRow() {
        self.isDiscoverableLabel.translatesAutoresizingMaskIntoConstraints = false
        self.isDiscoverableLabel.text = "Discoverable?"
        self.isDiscoverableLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.isDiscoverableLabel)
        
        NSLayoutConstraint.activate([
            self.isDiscoverableLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.isDiscoverableLabel.topAnchor.constraint(equalTo: self.property1ValueText.bottomAnchor, constant: 8),
            self.isDiscoverableLabel.widthAnchor.constraint(equalToConstant: 200),
            self.isDiscoverableLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        self.isDiscoverableSwitch.translatesAutoresizingMaskIntoConstraints = false
        if let oldGroup = self.oldGroup {
            self.isDiscoverableSwitch.isOn = oldGroup.settings.isDiscovarable
        }
        self.scrollView.addSubview(self.isDiscoverableSwitch)
        NSLayoutConstraint.activate([
            self.isDiscoverableSwitch.leadingAnchor.constraint(equalTo: self.isDiscoverableLabel.trailingAnchor, constant: 8),
            self.isDiscoverableSwitch.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.isDiscoverableSwitch.centerYAnchor.constraint(equalTo: self.isDiscoverableLabel.centerYAnchor),
            self.isDiscoverableSwitch.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupIsPrivateRow() {
        self.isPrivateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.isPrivateLabel.text = "Private?"
        self.isPrivateLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.isPrivateLabel)
        
        NSLayoutConstraint.activate([
            self.isPrivateLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.isPrivateLabel.topAnchor.constraint(equalTo: self.isDiscoverableSwitch.bottomAnchor, constant: 8),
            self.isPrivateLabel.widthAnchor.constraint(equalToConstant: 200),
            self.isPrivateLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        self.isPrivateSwitch.translatesAutoresizingMaskIntoConstraints = false
        if let oldGroup = self.oldGroup {
            self.isPrivateSwitch.isOn = oldGroup.settings.isPrivate
        }
        self.scrollView.addSubview(self.isPrivateSwitch)
        NSLayoutConstraint.activate([
            self.isPrivateSwitch.leadingAnchor.constraint(equalTo: self.isPrivateLabel.trailingAnchor, constant: 8),
            self.isPrivateSwitch.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.isPrivateSwitch.centerYAnchor.constraint(equalTo: self.isPrivateLabel.centerYAnchor),
            self.isPrivateSwitch.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

	private func setupLabelsRow() {
		self.labelsLabel.translatesAutoresizingMaskIntoConstraints = false
		self.labelsLabel.text = "Labels"
		self.labelsLabel.textColor = UIDesign.Colors.label
		self.scrollView.addSubview(self.labelsLabel)

		NSLayoutConstraint.activate([
			self.labelsLabel.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
			self.labelsLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
			self.labelsLabel.topAnchor.constraint(equalTo: self.isPrivateLabel.bottomAnchor, constant: 8),
			self.labelsLabel.heightAnchor.constraint(equalToConstant: 20)
		])

		self.labelsValueText.translatesAutoresizingMaskIntoConstraints = false
		self.labelsValueText.borderStyle = .roundedRect
		self.labelsValueText.text = self.oldGroup?.settings.labels.joined(separator: ",")
		self.labelsValueText.placeholder = "label1,label2"
		self.scrollView.addSubview(self.labelsValueText)
		NSLayoutConstraint.activate([
			self.labelsValueText.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8),
			self.labelsValueText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
			self.labelsValueText.topAnchor.constraint(equalTo: self.labelsLabel.bottomAnchor, constant: 4),
			self.labelsValueText.heightAnchor.constraint(equalToConstant: 30)
		])
	}

    private func setupCreateButton() {
        self.createButton.translatesAutoresizingMaskIntoConstraints = false
        self.createButton.setTitle(self.oldGroup == nil ? "Create": "Update", for: .normal)
        self.createButton.addTarget(self, action: #selector(executeCreate(sender:)), for: .touchUpInside)
        self.scrollView.addSubview(self.createButton)
        
        NSLayoutConstraint.activate([
            self.createButton.topAnchor.constraint(equalTo: self.labelsValueText.bottomAnchor, constant: 8),
            self.createButton.heightAnchor.constraint(equalToConstant: 40),
            self.createButton.widthAnchor.constraint(equalToConstant: 100),
            self.createButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.createButton.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -8)
        ])
    }
    
    @objc
    private func executeCreate(sender: UIView) {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        guard let groupId = self.idText.text, groupId.count > 0 else {
            showAlert(withText: "Group ID is mandatory!")
            return
        }
		if self.oldGroup == nil {
			guard let groupTitle = self.titleText.text, groupTitle.count > 0 else {
				showAlert(withText: "Name is mandatory!")
				return
			}
		}
        let groupContent = GroupContent(groupId: groupId)
		groupContent.title = self.titleText.text?.count == 0 ? nil : self.titleText.text
        groupContent.groupDescription = self.descriptionText.text
        if let avatarImage = self.avatarImage.image {
            groupContent.avatar = MediaAttachment.image(avatarImage)
        } else if let avatarUrl = self.avatarImageUrlText.text {
            groupContent.avatar = MediaAttachment.imageUrl(avatarUrl)
        }
        if let propertyKey = self.property1KeyText.text, let propertyValue = self.property1ValueText.text, propertyKey.count > 0, propertyValue.count > 0 {
            groupContent.properties = [propertyKey: propertyValue]
        }
        switch(self.allowPostSegmentedControl.selectedSegmentIndex) {
        case 0:
            groupContent.permissions[.post] = .owner
            break
        case 1:
            groupContent.permissions[.post] = .admin
            break
        case 2:
            groupContent.permissions[.post] = .member
            break
        default:
            groupContent.permissions[.post] = .member
            break
        }

        switch(self.allowInteractSegmentedControl.selectedSegmentIndex) {
        case 0:
            groupContent.permissions[.react] = .owner
            groupContent.permissions[.comment] = .owner
            break
        case 1:
            groupContent.permissions[.react] = .admin
            groupContent.permissions[.comment] = .admin
            break
        case 2:
            groupContent.permissions[.react] = .member
            groupContent.permissions[.comment] = .member
            break
        default:
            groupContent.permissions[.react] = .member
            groupContent.permissions[.comment] = .member
            break
        }

        groupContent.isDiscoverable = self.isDiscoverableSwitch.isOn
        groupContent.isPrivate = self.isPrivateSwitch.isOn
		if let labelsText = self.labelsValueText.text {
			groupContent.labels = labelsText.components(separatedBy: ",")
		}

        self.showActivityIndicatorView()
        self.model.createGroup(groupContent)
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
    func selectImage() {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.delegate = self
        self .present(self.imagePicker, animated: true, completion: nil)
    }
    
    @objc
    func clearImage() {
        self.avatarImage.image = nil
        self.avatarImage.isHidden = true
        self.avatarImageHeightConstraint?.constant = 0
        self.avatarClearImageButton.isHidden = true
    }
}

extension CreateGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.avatarImage.image = uiImage
            self.avatarImage.isHidden = false
            self.avatarClearImageButton.isHidden = false
            self.avatarImageHeightConstraint?.constant = 100.0
        }
        self.imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.imagePicker.dismiss(animated: true, completion: nil)
    }
}
