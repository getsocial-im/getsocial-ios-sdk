//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import MobileCoreServices

class ChatMessagesViewController: UIViewController {

    var model: ChatMessagesModel?
    var loadingOlders: Bool = false
    var loadingNewer: Bool = false

    var tableView: UITableView = UITableView()
    var inputAreaView: UIView = UIView()
    var messageView: UITextField = UITextField()
    var imageSwitchLabel: UILabel = UILabel()
    var videoSwitchLabel: UILabel = UILabel()
    var imageSwitch: UISwitch = UISwitch()
    var videoSwitch: UISwitch = UISwitch()
    var sendButton: UIButton = UIButton.init(type: .roundedRect)
    var refreshButton: UIButton = UIButton.init(type: .roundedRect)
    var refreshControl = UIRefreshControl()

    let imagePicker =  UIImagePickerController()
    let imageUrlLabel = UILabel()
    let imageUrl = UITextFieldWithCopyPaste()
    let videoUrlLabel = UILabel()
    let videoUrl = UITextFieldWithCopyPaste()
    var lastScrollOffset: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(ChatMessageViewCell.self, forCellReuseIdentifier: "chatmessagecell")
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(loadOlder(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)

        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        self.model?.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
            if let model = self.model, model.numberOfEntries() > 0 {
                let index = IndexPath(row: model.numberOfEntries() - 1, section: 0)
                self.tableView.scrollToRow(at: index, at: .bottom, animated: true)
            }
        }

        self.model?.onOlderMessages = { olderMessagesCount in
            self.hideActivityIndicatorView()
            self.loadingOlders = false
            if olderMessagesCount > 0 {
                self.tableView.beginUpdates()
                var indexPathArray: [IndexPath] = []
                (0...(olderMessagesCount - 1)).forEach {
                    indexPathArray.append(IndexPath(row: $0, section: 0))
                }
                self.tableView.insertRows(at: indexPathArray, with: .top)
                self.tableView.endUpdates()
            }
        }

        self.model?.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error)
        }
        self.model?.onNothingToLoad = {
            self.hideActivityIndicatorView()
            self.loadingNewer = false
            self.loadingOlders = false
        }

        self.model?.onMessageSent = { index in
            self.hideActivityIndicatorView()
            self.messageView.text = ""
            let indexPath = IndexPath.init(row: index-1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        self.model?.onNewerMessages = { newMessagesCount in
            self.hideActivityIndicatorView()
            self.loadingNewer = false
            if newMessagesCount > 0, let model = self.model {
                let numOfEntriesBefore = model.numberOfEntries() - newMessagesCount
                self.tableView.beginUpdates()
                var indexPathArray: [IndexPath] = []
                (0..<newMessagesCount).forEach {
                    indexPathArray.append(IndexPath(row: $0 + numOfEntriesBefore, section: 0))
                }
                self.tableView.insertRows(at: indexPathArray, with: .bottom)
                self.tableView.endUpdates()
                if let lastIndex = indexPathArray.last {
                    self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
                }
            }
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = self.model?.chatTitle()
        self.executeQuery()
    }

    private func setup() {
        self.view.backgroundColor = UIDesign.Colors.viewBackground
        layoutInputView()
        layoutTableView()
    }

    internal func layoutInputView() {
        self.view.addSubview(self.inputAreaView)
        self.view.addSubview(self.tableView)
        self.inputAreaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.inputAreaView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.inputAreaView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.inputAreaView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.navigationController?.navigationBar.frame.size.height ?? 0),
            self.inputAreaView.bottomAnchor.constraint(equalTo: self.tableView.topAnchor),
            self.inputAreaView.heightAnchor.constraint(equalToConstant: 180)
        ])
        self.inputAreaView.backgroundColor = .lightGray

        self.inputAreaView.addSubview(self.messageView)
        self.messageView.translatesAutoresizingMaskIntoConstraints = false
        self.messageView.textColor = UIDesign.Colors.inputText
        NSLayoutConstraint.activate([
            self.messageView.leadingAnchor.constraint(equalTo: self.inputAreaView.leadingAnchor, constant: 4),
            self.messageView.trailingAnchor.constraint(equalTo: self.inputAreaView.trailingAnchor, constant: -4),
            self.messageView.topAnchor.constraint(equalTo: self.inputAreaView.topAnchor, constant: 4),
            self.messageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        self.messageView.backgroundColor = .white

        self.imageUrlLabel.translatesAutoresizingMaskIntoConstraints = false
        self.imageUrlLabel.font = UIFont.systemFont(ofSize: 14)
        self.imageUrlLabel.text = "Image URL"
        self.inputAreaView.addSubview(self.imageUrlLabel)

        self.imageUrl.translatesAutoresizingMaskIntoConstraints = false
        self.imageUrl.backgroundColor = .white
        self.imageUrl.textColor = UIDesign.Colors.inputText
        self.inputAreaView.addSubview(self.imageUrl)

        self.videoUrlLabel.translatesAutoresizingMaskIntoConstraints = false
        self.videoUrlLabel.font = UIFont.systemFont(ofSize: 14)
        self.videoUrlLabel.text = "Video URL"
        self.inputAreaView.addSubview(self.videoUrlLabel)

        self.videoUrl.translatesAutoresizingMaskIntoConstraints = false
        self.videoUrl.backgroundColor = .white
        self.videoUrl.textColor = UIDesign.Colors.inputText
        self.inputAreaView.addSubview(self.videoUrl)

        NSLayoutConstraint.activate([
            self.imageUrlLabel.leadingAnchor.constraint(equalTo: self.inputAreaView.leadingAnchor, constant: 4),
            self.imageUrlLabel.widthAnchor.constraint(equalToConstant: 80),
            self.imageUrlLabel.heightAnchor.constraint(equalToConstant: 30),
            self.imageUrlLabel.trailingAnchor.constraint(equalTo: self.imageUrl.leadingAnchor, constant: -4),
            self.imageUrlLabel.topAnchor.constraint(equalTo: self.messageView.bottomAnchor, constant: 4)
        ])

        NSLayoutConstraint.activate([
            self.imageUrl.leadingAnchor.constraint(equalTo: self.imageUrlLabel.trailingAnchor, constant: 4),
            self.imageUrl.trailingAnchor.constraint(equalTo: self.inputAreaView.trailingAnchor, constant: -4),
            self.imageUrl.heightAnchor.constraint(equalToConstant: 28),
            self.imageUrl.centerYAnchor.constraint(equalTo: self.imageUrlLabel.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            self.videoUrlLabel.leadingAnchor.constraint(equalTo: self.inputAreaView.leadingAnchor, constant: 4),
            self.videoUrlLabel.widthAnchor.constraint(equalToConstant: 80),
            self.videoUrlLabel.heightAnchor.constraint(equalToConstant: 30),
            self.videoUrlLabel.trailingAnchor.constraint(equalTo: self.videoUrl.leadingAnchor, constant: -4),
            self.videoUrlLabel.topAnchor.constraint(equalTo: self.imageUrlLabel.bottomAnchor, constant: 4)
        ])

        NSLayoutConstraint.activate([
            self.videoUrl.leadingAnchor.constraint(equalTo: self.videoUrlLabel.trailingAnchor, constant: 4),
            self.videoUrl.trailingAnchor.constraint(equalTo: self.inputAreaView.trailingAnchor, constant: -4),
            self.videoUrl.heightAnchor.constraint(equalToConstant: 28),
            self.videoUrl.centerYAnchor.constraint(equalTo: self.videoUrlLabel.centerYAnchor)
        ])

        self.imageSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        self.imageSwitchLabel.font = UIFont.systemFont(ofSize: 14)
        self.imageSwitchLabel.text = "Send Image"
        self.inputAreaView.addSubview(self.imageSwitchLabel)

        self.imageSwitch.translatesAutoresizingMaskIntoConstraints = false
        self.imageSwitch.isOn = false
        self.inputAreaView.addSubview(self.imageSwitch)

        self.videoSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        self.videoSwitchLabel.font = UIFont.systemFont(ofSize: 14)
        self.videoSwitchLabel.text = "Send Video"
        self.inputAreaView.addSubview(self.videoSwitchLabel)

        self.videoSwitch.translatesAutoresizingMaskIntoConstraints = false
        self.videoSwitch.isOn = false
        self.inputAreaView.addSubview(self.videoSwitch)

        NSLayoutConstraint.activate([
            self.imageSwitchLabel.leadingAnchor.constraint(equalTo: self.inputAreaView.leadingAnchor, constant: 8),
            self.imageSwitchLabel.topAnchor.constraint(equalTo: self.videoUrl.bottomAnchor, constant: 8),
            self.imageSwitchLabel.heightAnchor.constraint(equalToConstant: 20),
            self.imageSwitchLabel.widthAnchor.constraint(equalToConstant: 100),
            self.imageSwitchLabel.trailingAnchor.constraint(equalTo: self.imageSwitch.leadingAnchor, constant: -8),
            self.imageSwitch.leadingAnchor.constraint(equalTo: self.imageSwitchLabel.trailingAnchor, constant: 8),
            self.imageSwitch.centerYAnchor.constraint(equalTo: self.imageSwitchLabel.centerYAnchor, constant: 4),
        ])

        NSLayoutConstraint.activate([
            self.videoSwitchLabel.leadingAnchor.constraint(equalTo: self.inputAreaView.leadingAnchor, constant: 8),
            self.videoSwitchLabel.topAnchor.constraint(equalTo: self.imageSwitch.bottomAnchor, constant: 4),
            self.videoSwitchLabel.heightAnchor.constraint(equalToConstant: 20),
            self.videoSwitchLabel.widthAnchor.constraint(equalToConstant: 100),
            self.videoSwitchLabel.trailingAnchor.constraint(equalTo: self.videoSwitch.leadingAnchor, constant: -8),
            self.videoSwitch.leadingAnchor.constraint(equalTo: self.videoSwitchLabel.trailingAnchor, constant: 8),
            self.videoSwitch.centerYAnchor.constraint(equalTo: self.videoSwitchLabel.centerYAnchor, constant: 4),
        ])

        self.sendButton.translatesAutoresizingMaskIntoConstraints = false
        self.sendButton.setTitle("Send", for: .normal)
        self.sendButton.addTarget(self, action: #selector(sendMessage(_:)), for: .touchUpInside)
        self.inputAreaView.addSubview(self.sendButton)

        NSLayoutConstraint.activate([
            self.sendButton.topAnchor.constraint(equalTo: self.videoUrl.bottomAnchor, constant: 4),
            self.sendButton.widthAnchor.constraint(equalToConstant: 60),
            self.sendButton.heightAnchor.constraint(equalToConstant: 30),
            self.sendButton.trailingAnchor.constraint(equalTo: self.inputAreaView.trailingAnchor, constant: -8)
        ])

        self.refreshButton.translatesAutoresizingMaskIntoConstraints = false
        self.refreshButton.setTitle("Refresh", for: .normal)
        self.refreshButton.addTarget(self, action: #selector(loadNewerMessages(_:)), for: .touchUpInside)
        self.inputAreaView.addSubview(self.refreshButton)

        NSLayoutConstraint.activate([
            self.refreshButton.topAnchor.constraint(equalTo: self.sendButton.bottomAnchor, constant: 4),
            self.refreshButton.widthAnchor.constraint(equalToConstant: 60),
            self.refreshButton.heightAnchor.constraint(equalToConstant: 30),
            self.refreshButton.trailingAnchor.constraint(equalTo: self.inputAreaView.trailingAnchor, constant: -8)
        ])
    }

    internal func layoutTableView() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false

        let top = tableView.topAnchor.constraint(equalTo: self.inputAreaView.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery() {
        self.showActivityIndicatorView()
        self.model?.loadInitialChatMessages()
    }

//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let actualPosition = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height - scrollView.frame.size.height
//        let newScrollOffset = actualPosition - contentHeight
//        print("offset change \(lastScrollOffset) -> \(newScrollOffset)")
//        if lastScrollOffset > 0 || newScrollOffset > 0.0 {
//            // do not scroll
//            lastScrollOffset = newScrollOffset
//            return
//        }
//        lastScrollOffset = newScrollOffset
//
//        if actualPosition > 0 && (self.model?.numberOfEntries() ?? 0) > 0 && actualPosition > contentHeight && !self.loadingNewer {
//            self.loadingNewer = true
//            self.showActivityIndicatorView()
//            self.model?.loadNewer()
//        }
//    }

    @objc
    func loadOlder(_ sender: Any) {
        self.refreshControl.endRefreshing()
        self.showActivityIndicatorView()
        self.model?.loadOlder()
    }

    @objc
    func loadNewerMessages(_ sender: Any) {
        self.showActivityIndicatorView()
        self.model?.loadNewer()
    }



//    - (IBAction)changeVideo:(id)sender
//    {
//        [self showImagePickerViewForMediaType:(NSString *)kUTTypeMovie];
//    }
//
//    - (IBAction)changeImage:(id)sender
//    {
//        [self showImagePickerViewForMediaType:(NSString *)kUTTypeImage];
//    }
    @objc
    func selectImage(_ sender: Any) {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.delegate = self
        self.imagePicker.mediaTypes = [String(kUTTypeImage)];
        self.present(self.imagePicker, animated: true, completion: nil)
    }

    @objc
    func selectVideo(_ sender: Any) {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.delegate = self
        self.imagePicker.mediaTypes = [String(kUTTypeMovie)];
        self.present(self.imagePicker, animated: true, completion: nil)
    }

    @objc
    func sendMessage(_ sender: Any) {
        if self.messageView.text?.count == 0 && !self.imageSwitch.isOn && !self.videoSwitch.isOn
        && self.imageUrl.text?.count == 0 && self.videoUrl.text?.count == 0 {
            showAlert(withText: "Text or image is mandatory!")
            return
        }
        let content = ChatMessageContent()
        content.text = self.messageView.text
        content.setProperty(value: "test value", forKey: "property1")
        if self.imageSwitch.isOn {
            if let path = Bundle.main.path(forResource: "activityImage", ofType: "png") {
                if let image = UIImage.init(contentsOfFile: path) {
                    content.appendMediaAttachment(MediaAttachment.image(image))
                }
            }
        }
        if self.videoSwitch.isOn {
            if let path = Bundle.main.url(forResource: "giphy", withExtension: "mp4") {
                if let video = try? Data.init(contentsOf: path) {
                    content.appendMediaAttachment(MediaAttachment.video(video))
                }
            }
        }
        if let imageUrl = self.imageUrl.text, imageUrl.count > 0 {
            content.appendMediaAttachment(MediaAttachment.imageUrl(self.imageUrl.text!))
        }
        if let videoUrl = self.videoUrl.text, videoUrl.count > 0 {
            content.appendMediaAttachment(MediaAttachment.videoUrl(self.videoUrl.text!))
        }
        self.showActivityIndicatorView()
        self.model?.sendMessage(content)
    }
}

extension ChatMessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
}

extension ChatMessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model?.numberOfEntries() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatmessagecell") as? ChatMessageViewCell
        if let item = self.model?.entry(at: indexPath.row) {
            cell?.update(item)
            cell?.onShowDetails = {
                self.showAlert(withTitle: "Details", andText: item.description)
            }
        }
        return cell ?? UITableViewCell()
    }
}

extension ChatMessagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil {
            //self.attachedImage = uiImage
        }
        self.imagePicker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.imagePicker.dismiss(animated: true, completion: nil)
    }
}
