//
//  ViewController.swift
//  Layout
//
//  Created by Nick Lockwood on 21/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet private var leftField: UITextField!
    @IBOutlet private var topField: UITextField!
    @IBOutlet private var widthField: UITextField!
    @IBOutlet private var heightField: UITextField!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var layoutView: UIView!

    var selectedView: UIView? {
        didSet {
            oldValue?.layer.borderWidth = 0
            selectedView?.layer.borderWidth = 2
            selectedView?.layer.borderColor = UIColor.black.cgColor
            leftField.isEnabled = true
            leftField.text = selectedView?.left
            topField.isEnabled = true
            topField.text = selectedView?.top
            widthField.isEnabled = true
            widthField.text = selectedView?.width
            heightField.isEnabled = true
            heightField.text = selectedView?.height
        }
    }

    @IBAction func didTap(sender: UITapGestureRecognizer) {
        let point = sender.location(in: layoutView)
        if let view = layoutView.hitTest(point, with: nil), view != layoutView {
            selectedView = view
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }

    func updateLayout() {
        do {
            for view in layoutView.subviews {
                try view.updateLayout()
            }
            errorLabel.text = nil
        } catch {
            errorLabel.text = "\(error)"
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_: UITextField) {
        selectedView?.left = leftField.text
        selectedView?.top = topField.text
        selectedView?.width = widthField.text
        selectedView?.height = heightField.text
        updateLayout()
    }
}
