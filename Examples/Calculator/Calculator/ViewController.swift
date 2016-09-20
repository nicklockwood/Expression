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
        do {
            if let text = textField.text, text != "" {
                let expression = try Expression(text)
                if let result = expression.evaluate() as Float? {
                    outputView.text = String(result) + "\n" + outputView.text
                } else {
                    outputView.text = "Invalid expression\n" + outputView.text
                }
            }
        } catch {
             outputView.text = "\(error)\n" + outputView.text
        }
        return false
    }
}

