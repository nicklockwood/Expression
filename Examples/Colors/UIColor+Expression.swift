//
//  UIColor+Expression.swift
//  Colors
//
//  Created by Nick Lockwood on 30/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import UIKit
import Expression

private let colors: [String: Double] = [
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

private let functions: [Expression.Symbol: Expression.Symbol.Evaluator] = [
    .function("rgb", arity: 3): { args in
        let red = UInt32(min(255, max(0, args[0]))) << 24
        let green = UInt32(min(255, max(0, args[1]))) << 16
        let blue = UInt32(min(255, max(0, args[2]))) << 8
        return Double(red + green + blue + 255)
    },
    .function("rgba", arity: 4): { args in
        let red = UInt32(min(255, max(0, args[0]))) << 24
        let green = UInt32(min(255, max(0, args[1]))) << 16
        let blue = UInt32(min(255, max(0, args[2]))) << 8
        let alpha = UInt32(min(1, max(0, args[3])) * 255)
        return Double(red + green + blue + alpha)
    },
]

public extension UIColor {

    public convenience init(rgba: UInt32) {
        let red = CGFloat((rgba & 0xFF000000) >> 24) / 255
        let green = CGFloat((rgba & 0x00FF0000) >> 16) / 255
        let blue = CGFloat((rgba & 0x0000FF00) >> 8) / 255
        let alpha = CGFloat((rgba & 0x000000FF) >> 0) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public convenience init(expression: String) throws {
        let parsedExpression = Expression.parse(expression)
        var constants = [String: Double]()
        for symbol in parsedExpression.symbols {
            if case let .variable(name) = symbol {
                if name.hasPrefix("#") {
                    var string = String(name.dropFirst())
                    switch string.count {
                    case 3:
                        string += "f"
                        fallthrough
                    case 4:
                        let chars = Array(string)
                        let red = chars[0]
                        let green = chars[1]
                        let blue = chars[2]
                        let alpha = chars[3]
                        string = "\(red)\(red)\(green)\(green)\(blue)\(blue)\(alpha)\(alpha)"
                    case 6:
                        string += "ff"
                    case 8:
                        break
                    default:
                        // unsupported format
                        continue
                    }
                    constants[name] = Double("0x" + string)
                } else if let value = colors[name.lowercased()] {
                    constants[name] = value
                }
            }
        }
        let expression = Expression(
            expression,
            constants: constants,
            symbols: functions
        )
        self.init(rgba: UInt32(try expression.evaluate()))
    }
}
