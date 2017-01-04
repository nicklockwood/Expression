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
            throw Expression.Error.undefinedSymbol(.constant(key))
        }
    }

    private func common(_ symbol: Expression.Symbol, _ args: [Double]) throws -> Double? {
        switch symbol {
        case .constant("auto"):
            throw Expression.Error.message("`auto` can only be used for width or height")
        case .constant(let name):
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
                case .constant("auto"):
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
                case .constant("auto"):
                    if let superview = self.view.superview {
                        return Double(self.view.systemLayoutSizeFitting(superview.frame.size).height)
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
