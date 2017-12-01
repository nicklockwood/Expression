//
//  View+Layout.swift
//  Layout
//
//  Created by Nick Lockwood on 21/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Expression
import UIKit

fileprivate class LayoutData: NSObject {

    private weak var view: UIView!
    private var inProgress = Set<String>()

    func computedValue(forKey key: String) throws -> Double {
        if inProgress.contains(key) {
            throw Expression.Error.message("Circular reference: \(key) depends on itself")
        }
        defer { inProgress.remove(key) }
        inProgress.insert(key)

        if let expression = props[key] {
            return try expression.evaluate()
        }
        switch key {
        case "right":
            return try computedValue(forKey: "left") + computedValue(forKey: "width")
        case "bottom":
            return try computedValue(forKey: "top") + computedValue(forKey: "height")
        default:
            throw Expression.Error.undefinedSymbol(.variable(key))
        }
    }

    private func common(_ symbol: Expression.Symbol, _: [Double]) throws -> Double? {
        switch symbol {
        case .variable("auto"):
            throw Expression.Error.message("`auto` can only be used for width or height")
        case let .variable(name):
            let parts = name.components(separatedBy: ".")
            if parts.count == 2 {
                if let sublayout = view.window?.subview(forKey: parts[0])?.layout {
                    return try sublayout.computedValue(forKey: parts[1])
                }
                throw Expression.Error.message("No view found for key `\(parts[0])`")
            }
            return try computedValue(forKey: parts[0])
        default:
            return nil
        }
    }

    var key: String?
    var left: String? {
        didSet {
            props["left"] = Expression(left ?? "0") { [unowned self] symbol, args in
                switch symbol {
                case .postfix("%"):
                    return self.view.superview.map { Double($0.frame.width) / 100 * args[0] }
                default:
                    return try self.common(symbol, args)
                }
            }
        }
    }

    var top: String? {
        didSet {
            props["top"] = Expression(top ?? "0") { [unowned self] symbol, args in
                switch symbol {
                case .postfix("%"):
                    return self.view.superview.map { Double($0.frame.height) / 100 * args[0] }
                default:
                    return try self.common(symbol, args)
                }
            }
        }
    }

    var width: String? {
        didSet {
            props["width"] = Expression(width ?? "100%") { [unowned self] symbol, args in
                switch symbol {
                case .postfix("%"):
                    return self.view.superview.map { Double($0.frame.width) / 100 * args[0] }
                case .variable("auto"):
                    if let superview = self.view.superview {
                        return Double(self.view.systemLayoutSizeFitting(superview.frame.size).width)
                    }
                    return 0
                default:
                    return try self.common(symbol, args)
                }
            }
        }
    }

    var height: String? {
        didSet {
            props["height"] = Expression(height ?? "100%") { [unowned self] symbol, args in
                switch symbol {
                case .postfix("%"):
                    return self.view.superview.map { Double($0.frame.height) / 100 * args[0] }
                case .variable("auto"):
                    if let superview = self.view.superview {
                        var size = superview.frame.size
                        size.width = CGFloat(try self.computedValue(forKey: "width"))
                        return Double(self.view.systemLayoutSizeFitting(size).height)
                    }
                    return 0
                default:
                    return try self.common(symbol, args)
                }
            }
        }
    }

    private var props: [String: Expression] = [:]

    init(_ view: UIView) {
        self.view = view
        left = nil
        top = nil
        width = nil
        height = nil
    }
}

@IBDesignable
public extension UIView {

    fileprivate var layout: LayoutData? {
        return layout(create: false)
    }

    private func layout(create: Bool) -> LayoutData! {
        let layout = layer.value(forKey: "layout") as? LayoutData
        if layout == nil && create {
            let layout = LayoutData(self)
            layer.setValue(layout, forKey: "layout")
            return layout
        }
        return layout
    }

    @IBInspectable var key: String? {
        get { return layout?.key }
        set { layout(create: true).key = newValue }
    }

    @IBInspectable var left: String? {
        get { return layout?.left }
        set { layout(create: true).left = newValue }
    }

    @IBInspectable var top: String? {
        get { return layout?.top }
        set { layout(create: true).top = newValue }
    }

    @IBInspectable var width: String? {
        get { return layout?.width }
        set { layout(create: true).width = newValue }
    }

    @IBInspectable var height: String? {
        get { return layout?.height }
        set { layout(create: true).height = newValue }
    }

    fileprivate func subview(forKey key: String) -> UIView? {
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

    public func updateLayout() throws {
        guard let layout = self.layout(create: true) else {
            return
        }
        frame = CGRect(x: try layout.computedValue(forKey: "left"),
                       y: try layout.computedValue(forKey: "top"),
                       width: try layout.computedValue(forKey: "width"),
                       height: try layout.computedValue(forKey: "height"))

        for view in subviews {
            try view.updateLayout()
        }
    }
}
