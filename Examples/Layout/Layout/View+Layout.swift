//
//  View+Layout.swift
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
import Expression

fileprivate var layoutKey: UInt8 = 0

class LayoutData: NSObject {
    var key: String?
    var left: String? {
        didSet { props.removeAll() }
    }
    var top: String? {
        didSet { props.removeAll() }
    }
    var width: String? {
        didSet { props.removeAll() }
    }
    var height: String? {
        didSet { props.removeAll() }
    }
    var props: [String: Expression] = [:]
}

@IBDesignable
extension UIView {

    var layout: LayoutData {
        if let layout = objc_getAssociatedObject(self, &layoutKey) as? LayoutData {
            return layout
        }
        let layout = LayoutData()
        objc_setAssociatedObject(self, &layoutKey, layout, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return layout
    }
    
    @IBInspectable var key: String? {
        get { return layout.key }
        set { layout.key = newValue }
    }
    
    @IBInspectable var left: String? {
        get { return layout.left }
        set { layout.left = newValue }
    }
    
    @IBInspectable var top: String? {
        get { return layout.top }
        set { layout.top = newValue }
    }
    
    @IBInspectable var width: String? {
        get { return layout.width }
        set { layout.width = newValue }
    }
    
    @IBInspectable var height: String? {
        get { return layout.height }
        set { layout.height = newValue }
    }
    
    func subview(forKey key: String) -> UIView? {
        if self.key == key {
            return self
        }
        for view in subviews {
            if let match = view.subview(forKey: key) {
                return match
            }
        }
        return nil
    }
    
    func computedValue(forKey key: String) throws -> Double? {
        if let expression = layout.props[key] {
            return try expression.evaluate()
        }
        return nil
    }

    func updateLayout() throws {
        if layout.props.isEmpty {
            var inProgress = Set<String>()
            
            func beginEvaluating(_ key: String) throws {
                if inProgress.contains(key) {
                    throw Expression.Error.message("Circular reference: \(key) depends on itself")
                }
                inProgress.insert(key)
            }
            
            let common: Expression.Evaluator = { [unowned self] symbol, args in
                switch symbol {
                case .constant(let name):
                    let parts = name.components(separatedBy: ".")
                    if parts.count == 2 {
                        if let view = self.window?.subview(forKey: parts[0]) {
                            return try view.computedValue(forKey: parts[1])
                        }
                        throw Expression.Error.message("No view found for key `\(parts[0])`")
                    }
                    return try self.computedValue(forKey: parts[0])
                default:
                    return nil
                }
            }
            
            layout.props["left"] = try Expression(left ?? "0") { [unowned self] symbol, args in
                try beginEvaluating("left")
                defer { inProgress.remove("left") }
                
                switch symbol {
                case .postfix("%"):
                    return self.superview.map { Double($0.frame.width) / 100 * args[0] }
                case .constant("auto"):
                    throw Expression.Error.message("`auto` can only be used for width or height")
                default:
                    return try common(symbol, args)
                }
            }
            layout.props["top"] = try Expression(top ?? "0") { [unowned self] symbol, args in
                try beginEvaluating("top")
                defer { inProgress.remove("top") }
                
                switch symbol {
                case .postfix("%"):
                    return self.superview.map { Double($0.frame.height) / 100 * args[0] }
                case .constant("auto"):
                    throw Expression.Error.message("`auto` can only be used for width or height")
                default:
                    return try common(symbol, args)
                }
            }
            layout.props["width"] = try Expression(width ?? "100%") { [unowned self] symbol, args in
                try beginEvaluating("width")
                defer { inProgress.remove("width") }
                
                switch symbol {
                case .postfix("%"):
                    return self.superview.map { Double($0.frame.width) / 100 * args[0] }
                case .constant("auto"):
                    let frame = self.frame
                    self.frame = self.superview?.bounds ?? frame
                    self.sizeToFit()
                    let width = self.frame.size.width
                    self.frame = frame
                    return Double(width)
                default:
                    return try common(symbol, args)
                }
            }
            layout.props["height"] = try Expression(height ?? "100%") { [unowned self] symbol, args in
                try beginEvaluating("height")
                defer { inProgress.remove("height") }
                
                switch symbol {
                case .postfix("%"):
                    return self.superview.map { Double($0.frame.height) / 100 * args[0] }
                case .constant("auto"):
                    let frame = self.frame
                    self.frame.size.width = CGFloat(try self.layout.props["width"]!.evaluate())
                    self.sizeToFit()
                    let height = self.frame.size.height
                    self.frame = frame
                    return Double(height)
                default:
                    return try common(symbol, args)
                }
            }
            layout.props["right"] = try Expression("left + width") { symbol, args in
                try beginEvaluating("right")
                defer { inProgress.remove("right") }
                return try common(symbol, args)
            }
            layout.props["bottom"] = try Expression("top + height") { symbol, args in
                try beginEvaluating("bottom")
                defer { inProgress.remove("bottom") }
                return try common(symbol, args)
            }
        }

        // calculate frame
        frame = CGRect(x: try layout.props["left"]!.evaluate(),
                       y: try layout.props["top"]!.evaluate(),
                       width: try layout.props["width"]!.evaluate(),
                       height: try layout.props["height"]!.evaluate())
        
        for view in subviews {
            try view.updateLayout()
        }
    }
}
