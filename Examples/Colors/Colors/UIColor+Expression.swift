//
//  UIColor+Expression.swift
//  Colors
//
//  Created by Nick Lockwood on 30/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import UIKit
import Expression

public extension UIColor {
    
    public convenience init(rgba: UInt32) {
        let red = CGFloat((rgba & 0xFF000000) >> 24) / 255
        let green = CGFloat((rgba & 0x00FF0000) >> 16) / 255
        let blue = CGFloat((rgba & 0x0000FF00) >> 8) / 255
        let alpha = CGFloat((rgba & 0x000000FF) >> 0) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public convenience init(expression: String) throws {
        let expression = Expression(expression) { symbol, args in
            switch symbol {
            case .constant(var string):
                if string.hasPrefix("#") {
                    string = String(string.characters.dropFirst())
                    switch (string.characters.count) {
                    case 3:
                        string += "f"
                        fallthrough
                    case 4:
                        let red = string.characters[string.index(string.startIndex, offsetBy: 0)]
                        let green = string.characters[string.index(string.startIndex, offsetBy: 1)]
                        let blue = string.characters[string.index(string.startIndex, offsetBy: 2)]
                        let alpha = string.characters[string.index(string.startIndex, offsetBy: 3)]
                        string = "\(red)\(red)\(green)\(green)\(blue)\(blue)\(alpha)\(alpha)"
                    case 6:
                        string += "ff"
                    case 8:
                        break
                    default:
                        //unsupported format
                        return nil
                    }
                    return Double("0x" + string)
                }
                let constants: [String: Double] = [
                    "red": 0xFF0000FF,
                    "green": 0x00FF00FF,
                    "blue": 0x0000FFFF,
                    "yellow": 0xFFFF00FF,
                    "purple": 0xFF00FFFF,
                    "cyan": 0x00FFFFFF,
                    "pink": 0xFF7F7FFF,
                    "orange": 0xFF7F00FF,
                    "gray": 0x7F7F7FFF,
                    "black": 0x000000FF,
                    "white": 0xFFFFFFFF,
                ]
                return constants[string.lowercased()]
            case .function("rgb", let arity):
                if arity != 3 {
                    throw Expression.Error.arityMismatch(symbol)
                }
                let red = Int(min(255, max(0, args[0]))) << 24
                let green = Int(min(255, max(0, args[1]))) << 16
                let blue = Int(min(255, max(0, args[2]))) << 8
                return Double(red + green + blue + 255)
            case .function("rgba", let arity):
                if arity != 4 {
                    throw Expression.Error.arityMismatch(symbol)
                }
                let red = Int(min(255, max(0, args[0]))) << 24
                let green = Int(min(255, max(0, args[1]))) << 16
                let blue = Int(min(255, max(0, args[2]))) << 8
                let alpha = Int(min(1, max(0, args[3])) * 255)
                return Double(red + green + blue + alpha)
            default:
                return nil
            }
        }
        self.init(rgba: UInt32(try expression.evaluate()))
    }
}
