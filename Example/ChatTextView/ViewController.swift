//
//  ViewController.swift
//  ChatTextView
//
//  Created by abeyuya on 12/27/2019.
//  Copyright (c) 2019 abeyuya. All rights reserved.
//

import UIKit
import UnderKeyboard

class ViewController: UIViewController {

    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!

    let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()

    override func viewDidLoad() {
        super.viewDidLoad()
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

