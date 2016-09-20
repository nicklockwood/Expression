//
//  ViewController.swift
//  Calculator
//
//  Created by Nick Lockwood on 17/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import UIKit
import Expression

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet private var inputField: UITextField!
    @IBOutlet private var outputView: UITextView!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if  let text = textField.text, text != "" {
            do {
                let expression = try Expression(text)
                let result = try expression.evaluate()
                outputView.text = String(format: "%g\n", result) + outputView.text
            } catch {
                outputView.text = "\(error)\n" + outputView.text
            }
        }
        return false
    }
}

