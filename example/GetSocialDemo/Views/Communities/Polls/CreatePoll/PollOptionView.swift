//
//  PollOptionView.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 26/04/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit
import GetSocialSDK

class PollOptionView: UIView {
	var onRemoveTap: (() -> Void)?

	let optionIdLabel = UILabel()
	let textLabel = UILabel()
	let imageUrlLabel = UILabel()
	let videoUrlLabel = UILabel()
	let attachImageLabel = UILabel()
	let attachVideoLabel = UILabel()

	let optionId = UITextFieldWithCopyPaste()
	let text = UITextFieldWithCopyPaste()
	let imageUrl = UITextFieldWithCopyPaste()
	let videoUrl = UITextFieldWithCopyPaste()
	let attachImage = UISwitch()
	let attachVideo = UISwitch()

	let removeButton = UIButton(type: .roundedRect)

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func collectData() -> Result<PollOptionContent, Error> {
		let content = PollOptionContent()
		content.optionId = self.optionId.text?.count == 0 ? nil : self.optionId.text
		content.text = self.text.text
		if self.attachImage.isOn {
			if let path = Bundle.main.path(forResource: "activityImage", ofType: "png") {
				if let image = UIImage.init(contentsOfFile: path) {
					content.attachment = MediaAttachment.image(image)
				}
			}
		}
		if self.attachVideo.isOn {
			if let path = Bundle.main.url(forResource: "giphy", withExtension: "mp4") {
				if let video = try? Data.init(contentsOf: path) {
					content.attachment = MediaAttachment.video(video)
				}
			}
		}
		if let imageUrl = self.imageUrl.text, imageUrl.count > 0 {
			content.attachment = MediaAttachment.imageUrl(self.imageUrl.text!)
		}
		if let videoUrl = self.videoUrl.text, videoUrl.count > 0 {
			content.attachment = MediaAttachment.videoUrl(self.videoUrl.text!)
		}
		if content.attachment == nil && content.text?.count == 0 {
			return .failure(GetSocialDemoError.missingParameter("Text or Attachment is mandatory"))
		}

		return .success(content)
	}

	private func setup() {
		self.layer.borderColor = UIColor.black.cgColor
		self.layer.borderWidth = 1.0
		self.backgroundColor = UIDesign.Colors.viewBackground

		let stack = UIStackView()
		stack.translatesAutoresizingMaskIntoConstraints = false
		stack.axis = .vertical
		stack.alignment = .fill
		stack.spacing = 4

		self.addSubview(stack)
		NSLayoutConstraint.activate([
			stack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			stack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			stack.topAnchor.constraint(equalTo: self.topAnchor),
			stack.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])

		optionIdLabel.text = "Option Id"
		textLabel.text = "Text"
		imageUrlLabel.text = "Image Url"
		videoUrlLabel.text = "Video Url"
		attachImageLabel.text = "Attach Image"
		attachVideoLabel.text = "Attach Video"
		removeButton.setTitle("Remove", for: .normal)
		removeButton.addTarget(self, action: #selector(remove(sender:)), for: .touchUpInside)

		optionId.textColor = UIDesign.Colors.inputText
		optionId.backgroundColor = .lightGray

		text.textColor = UIDesign.Colors.inputText
		text.backgroundColor = .lightGray

		imageUrl.textColor = UIDesign.Colors.inputText
		imageUrl.backgroundColor = .lightGray
		imageUrl.delegate = self

		videoUrl.textColor = UIDesign.Colors.inputText
		videoUrl.backgroundColor = .lightGray
		videoUrl.delegate = self

		attachImage.addTarget(self, action: #selector(attachImageValueChanged), for: .valueChanged)
		attachVideo.addTarget(self, action: #selector(attachVideoValueChanged), for: .valueChanged)

		stack.addFormRow(elements: [optionIdLabel, optionId])
		stack.addFormRow(elements: [textLabel, text])
		stack.addFormRow(elements: [imageUrlLabel, imageUrl])
		stack.addFormRow(elements: [videoUrlLabel, videoUrl])
		stack.addFormRow(elements: [attachImageLabel, attachImage])
		stack.addFormRow(elements: [attachVideoLabel, attachVideo])
		stack.addArrangedSubview(removeButton)
	}

	@objc
	private func attachImageValueChanged() {
		if self.attachImage.isOn {
			self.attachVideo.isOn = false
		}
	}

	@objc
	private func attachVideoValueChanged() {
		if self.attachVideo.isOn {
			self.attachImage.isOn = false
		}
	}

	@objc
	private func remove(sender: UIView) {
		self.onRemoveTap?()
	}

}

extension PollOptionView: UITextFieldDelegate {
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		if textField == imageUrl {
			videoUrl.text = nil
		} else if textField == videoUrl {
			imageUrl.text = nil
		}
		return true
	}
}
