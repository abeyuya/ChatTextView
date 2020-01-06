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
            mensionButton.addTarget(self, action: #selector(didTapMensionButton), for: .touchUpInside)
        }
    }

    private let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()

    override func viewDidLoad() {
        super.viewDidLoad()
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)

        chatTextView.setup(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func didTapSendButton() {

    }

    @objc
    func didTapEmojiButton() {
        let vc = UIAlertController(title: "", message: "emoji", preferredStyle: .actionSheet)

        let parrot = UIAlertAction(title: "parrot (gif)", style: .default) { _ in
            let url = "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif"
            let image = UIImage.gifImageWithURL(url)
            let emoji = TextTypeEmoji(
                displayImage: image,
                escapedString: ":parrot:",
                size: .init(width: 14, height: 14)
            )
            self.chatTextView.insert(emoji: emoji)
        }

        let octcat = UIAlertAction(title: "octcat (png)", style: .default) { _ in
            let url = URL(string: "https://emoji.slack-edge.com/T02DMDKPY/octocat/627964d7c9.png")!
            let data = try? Data(contentsOf: url)
            let image = data == nil ? nil : UIImage(data: data!)
            let emoji = TextTypeEmoji(
                displayImage: image,
                escapedString: ":octcat:",
                size: .init(width: 14, height: 14)
            )
            self.chatTextView.insert(emoji: emoji)
        }

        let cancel = UIAlertAction(title: "cancel", style: .cancel) { _ in }

        vc.addAction(parrot)
        vc.addAction(octcat)
        vc.addAction(cancel)
        present(vc, animated: true)
    }

    @objc
    func didTapMensionButton() {

    }
}

extension ViewController: ChatTextViewDelegate {
    func didChange(textTypes: [TextType]) {
        print(textTypes)
    }
}
