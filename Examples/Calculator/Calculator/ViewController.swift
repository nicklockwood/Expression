//
//  ViewController.swift
//  Calculator
//
//  Created by Nick Lockwood on 17/09/2016.
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
import Expression

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet private var inputField: UITextField!
    @IBOutlet private var outputView: UITextView!

    private var output = NSMutableAttributedString()

    private func addOutput(_ string: String, color: UIColor) {
        let text = NSAttributedString(string: string + "\n\n", attributes: [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: outputView.font!,
        ])

        output.replaceCharacters(in: NSMakeRange(0, 0), with: text)
        outputView.attributedText = output
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.append(outputView.attributedText)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, text != "" {
            do {
                let result = try Expression(text).evaluate()
                addOutput(String(format: "= %g", result), color: .black)
            } catch {
                addOutput("\(error)", color: .red)
            }
        }
        return false
    }
}
