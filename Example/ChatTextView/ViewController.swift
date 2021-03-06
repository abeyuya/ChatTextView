//
//  ViewController.swift
//  ChatTextView
//
//  Created by abeyuya on 12/27/2019.
//  Copyright (c) 2019 abeyuya. All rights reserved.
//

import UIKit
import UnderKeyboard
import ChatTextView

class ViewController: UIViewController {

    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTextView: ChatTextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.addTarget(self, action: #selector(didTapSendButton), for: .touchUpInside)
        }
    }
    @IBOutlet weak var emojiButton: UIButton! {
        didSet {
            emojiButton.addTarget(self, action: #selector(didTapEmojiButton), for: .touchUpInside)
        }
    }
    @IBOutlet weak var mensionButton: UIButton! {
        didSet {
            mensionButton.addTarget(self, action: #selector(didTapMentionButton), for: .touchUpInside)
        }
    }

    private let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()
    private var sendTextBlocks: [[TextBlock]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)

        chatTextView.setup(delegate: self)
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func didTapSendButton() {
        let textBlocks = chatTextView.getCurrentTextBlocks()
        sendTextBlocks.append(textBlocks)
        tableView.reloadData()

        chatTextView.clear()
        chatTextView.resignFirstResponder()
    }

    @objc
    func didTapEmojiButton() {
        let vc = UIAlertController(
            title: "",
            message: "insert custom emoji",
            preferredStyle: .actionSheet
        )

        let parrot = UIAlertAction(title: "parrot (gif)", style: .default) { _ in
            let url = URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!
            let emoji = TextBlockCustomEmoji(
                displayImageUrl: url,
                escapedString: ":parrot:"
            )
            self.chatTextView.insert(emoji: emoji) {}
        }

        let octcat = UIAlertAction(title: "octcat (png)", style: .default) { _ in
            let url = URL(string: "https://emoji.slack-edge.com/T02DMDKPY/octocat/627964d7c9.png")!
            let emoji = TextBlockCustomEmoji(
                displayImageUrl: url,
                escapedString: ":octcat:"
            )
            self.chatTextView.insert(emoji: emoji) {}
        }

        let cancel = UIAlertAction(title: "cancel", style: .cancel) { _ in }

        vc.addAction(parrot)
        vc.addAction(octcat)
        vc.addAction(cancel)
        present(vc, animated: true)
    }

    @objc
    func didTapMentionButton() {
        let vc = UIAlertController(
            title: "",
            message: "insert mention",
            preferredStyle: .actionSheet
        )

        let atChannel = UIAlertAction(title: "@channel", style: .default) { _ in
            let mention = TextBlockMention(
                displayString: "@channel",
                metadata: ""
            )
            self.chatTextView.insert(mention: mention)
        }

        let atName = UIAlertAction(title: "@名前", style: .default) { _ in
            let mention = TextBlockMention(
                displayString: "@名前",
                metadata: ""
            )
            self.chatTextView.insert(mention: mention)
        }

        let cancel = UIAlertAction(title: "cancel", style: .cancel) { _ in }

        vc.addAction(atChannel)
        vc.addAction(atName)
        vc.addAction(cancel)
        present(vc, animated: true)
    }
}

extension ViewController: UITableViewDelegate {}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sendTextBlocks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let textBlocks = sendTextBlocks[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell()
        }

        guard let chatTextView = cell.viewWithTag(10) as? ChatTextView else {
            return UITableViewCell()
        }

        chatTextView.clear()
        chatTextView.render(textBlocks: textBlocks) {}
        return cell
    }
}

extension ViewController: ChatTextViewDelegate {
    func didChange(textView: ChatTextView, contentSize: CGSize) {
        print("didChange(textView: ChatTextView, contentSize: CGSize)", contentSize)
    }

    func didChange(textView: ChatTextView, textBlocks: [TextBlock]) {
        print("didChange(textView: ChatTextView, textBlocks: [TextBlocks])", textBlocks)
    }

    func didChange(textView: ChatTextView, isFocused: Bool) {
        print("didChange(textView: ChatTextView, isFocused: Bool)", isFocused)
    }
}
