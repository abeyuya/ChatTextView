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

    let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()

    override func viewDidLoad() {
        super.viewDidLoad()
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)

        chatTextView.setup(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: ChatTextViewDelegate {}

