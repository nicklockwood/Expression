//
//  Expression.swift
//  Expression
//
//  Version 0.2
//
//  Created by Nick Lockwood on 15/09/2016.
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

/// Immutable wrapper for a parsed expression
/// Reusing the same Expression instance for multiple evaluations is more efficient
/// than creating a new one each time you wish to evaluate an expression string.

#if SWIFT_PACKAGE
import Foundation
#endif

public class Expression: CustomStringConvertible {
    private let expression: String
    private let evaluator: Evaluator
    private var root: Subexpression?

    /// Function prototype for evaluating an expression
    /// Return nil for an unrecognized symbol, or throw an error if the symbol is recognized
    /// but there is some other problem (e.g. wrong number of arguments for a function)
    public typealias Evaluator = (_ symbol: Expression.Symbol, _ args: [Double]) throws -> Double?

    /// Symbols that make up an expression
    public enum Symbol: CustomStringConvertible, Hashable {

        /// A named constant
        case constant(String)

        /// An infix operator
        case infix(String)

        /// A prefix operator
        case prefix(String)

        /// A postfix operator
        case postfix(String)

        /// A function accepting a number of arguments specified by `arity`
        case function(String, arity: Int)

        /// Evaluator for individual symbols
        public typealias Evaluator = (_ args: [Double]) throws -> Double

        /// The human-readable name of the symbol
        public var name: String {
            switch self {
            case .constant(let name),
                 .infix(let name),
                 .prefix(let name),
                 .postfix(let name),
                 .function(let name, _):
                return name
            }
        }

        /// The human-readable description of the symbol
        public var description: String {
            switch self {
            case .constant(let name):
                return "constant `\(name)`"
            case .infix(let name):
                return "infix operator `\(name)`"
            case .prefix(let name):
                return "prefix operator `\(name)`"
            case .postfix(let name):
                return "postfix operator `\(name)`"
            case .function(let name, _):
                return "function `\(name)()`"
            }
        }

        /// Required by the hashable protocol
        public var hashValue: Int {
            return name.hashValue
        }

        /// Required by the equatable protocol
        public static func ==(lhs: Symbol, rhs: Symbol) -> Bool {
            if case .function(_, let lhsarity) = lhs,
                case .function(_, let rhsarity) = rhs,
                lhsarity != rhsarity {
                return false
            }
            return lhs.description == rhs.description
        }
    }

    /// Runtime error when parsing or evaluating an expression
    public enum Error: Swift.Error, CustomStringConvertible {

        /// An application-specific error
        case message(String)

        /// The parser encountered a sequence of characters it didn't recognize
        case unexpectedToken(String)

        /// The parser expected to find a delimiter (e.g. closing paren) but didn't
        case missingDelimiter(String)

        /// The specified constant, operator or function was not recognized
        case undefinedSymbol(Expression.Symbol)

        /// A function was called with the wrong number of arguments (arity)
        case arityMismatch(Expression.Symbol)

        /// The human-readable description of the error
        public var description: String {
            switch self {
            case .message(let message):
                return message
            case .unexpectedToken(let string):
                return "Unexpected token `\(string)`"
            case .missingDelimiter(let string):
                return "Missing `\(string)`"
            case .undefinedSymbol(let symbol):
                return "Undefined \(symbol)"
            case .arityMismatch(let symbol):
                let arity: Int
                switch symbol {
                case .constant:
                    arity = 0
                case .infix:
                    arity = 2
                case .postfix, .prefix:
                    arity = 1
                case .function(_, let requiredArity):
                    arity = requiredArity
                }
                let description = symbol.description
                return String(description.characters.first!).uppercased() +
                    String(description.characters.dropFirst()) +
                    " expects \(arity) argument\(arity == 1 ? "" : "s")"
            }
        }
    }

    /// Creates an Expression object from a string
    /// Optionally accepts some or all of:
    /// - A dictionary of constants for simple static values
    /// - A dictionary of symbols, for implementing custom functions and operators
    /// - A custom evaluator function for more complex symbol processing
    public init(_ expression: String,
        constants: [String: Double]? = nil,
        symbols: [Symbol: Symbol.Evaluator]? = nil,
        evaluator: Evaluator? = nil) {

        // Parse expression
        var characters = expression.characters
        root = try? characters.parseSubexpression()
        self.expression = root?.description ?? expression

        // Build evaluator
        self.evaluator = { symbol, args in
            // Try constants
            if let constants = constants,
                case Symbol.constant(let name) = symbol,
                let value = constants[name] {
                return value
            }
            // Try symbols
            if let symbols = symbols, let fn = symbols[symbol] {
                return try fn(args)
            }
            // Try custom evaluator
            if let value = try evaluator?(symbol, args) {
                return value
            }
            // Try default symbols
            if let fn = Expression.defaultSymbols[symbol] {
                return try fn(args)
            }
            // Check for arity mismatch
            if case .function(let called, let arity) = symbol {
                var keys = Array(Expression.defaultSymbols.keys)
                if symbols != nil {
                    keys += Array(symbols!.keys)
                }
                var expectedArity: Int?
                for case .function(let name, let requiredArity) in keys
                    where name == called && arity != requiredArity {
                    expectedArity = requiredArity
                }
                if let expectedArity = expectedArity {
                    throw Error.arityMismatch(.function(called, arity: expectedArity))
                }
            }
            return nil
        }
    }

    /// Evaluate the expression
    public func evaluate() throws -> Double {
        guard let root = root else {
            var characters = expression.characters
            _ = try characters.parseSubexpression() // Must fail or root would already be set
            preconditionFailure()
        }
        return try root.evaluate(evaluator)
    }

    // Expression's "standard library"
    private static let defaultSymbols: [Symbol: Symbol.Evaluator] = {
        var symbols: [Symbol: ([Double]) -> Double] = [:]

        // constants
        symbols[.constant("pi")] = { _ in .pi }

        // infix operators
        symbols[.infix("+")] = { $0[0] + $0[1] }
        symbols[.infix("-")] = { $0[0] - $0[1] }
        symbols[.infix("*")] = { $0[0] * $0[1] }
        symbols[.infix("/")] = { $0[0] / $0[1] }

        // prefix operators
        symbols[.prefix("-")] = { -$0[0] }

        // functions - arity 1
        symbols[.function("sqrt", arity: 1)] = { sqrt($0[0]) }
        symbols[.function("floor", arity: 1)] = { floor($0[0]) }
        symbols[.function("ceil", arity: 1)] = { ceil($0[0]) }
        symbols[.function("round", arity: 1)] = { round($0[0]) }
        symbols[.function("cos", arity: 1)] = { cos($0[0]) }
        symbols[.function("acos", arity: 1)] = { acos($0[0]) }
        symbols[.function("sin", arity: 1)] = { sin($0[0]) }
        symbols[.function("asin", arity: 1)] = { asin($0[0]) }
        symbols[.function("tan", arity: 1)] = { tan($0[0]) }
        symbols[.function("atan", arity: 1)] = { atan($0[0]) }
        symbols[.function("abs", arity: 1)] = { abs($0[0]) }

        // functions - arity 2
        symbols[.function("pow", arity: 2)] = { pow($0[0], $0[1]) }
        symbols[.function("max", arity: 2)] = { max($0[0], $0[1]) }
        symbols[.function("min", arity: 2)] = { min($0[0], $0[1]) }
        symbols[.function("atan2", arity: 2)] = { atan2($0[0], $0[1]) }
        symbols[.function("mod", arity: 2)] = { fmod($0[0], $0[1]) }

        return symbols
    }()

    /// If expression has not yet been validated, returns the input expression
    /// Once validated, returns a pretty-printed version of the expression
    public var description: String {
        return root?.description ?? expression
    }
}

fileprivate enum Subexpression: CustomStringConvertible {
    case literal(String)
    case infix(String)
    case prefix(String)
    case postfix(String)
    case operand(Expression.Symbol, [Subexpression])

    func evaluate(_ evaluator: Expression.Evaluator) throws -> Double {
        switch self {
        case .literal(let value):
            if let value = Double(value) {
                return value
            }
            throw Expression.Error.unexpectedToken(value)
        case .operand(let symbol, let args):
            let argValues = try args.map { try $0.evaluate(evaluator) }
            if let value = try evaluator(symbol, argValues) {
                return value
            }
            throw Expression.Error.undefinedSymbol(symbol)
        case .infix(let name),
             .prefix(let name),
             .postfix(let name):
            throw Expression.Error.unexpectedToken(name)
        }
    }

    var description: String {
        switch self {
        case .literal(let string),
             .infix(let string),
             .prefix(let string),
             .postfix(let string):
            return string
        case .operand(let symbol, let args):
            switch symbol {
            case .prefix(let name):
                return "\(name)\(args[0])"
            case .postfix(let name):
                return "\(args[0])\(name)"
            case .infix(let name):
                return "\(args[0]) \(name) \(args[1])"
            case .constant(let name):
                return name
            case .function(let name, _):
                return "\(name)(\(args.map({ $0.description }).joined(separator: ", ")))"
            }
        }
    }
}

fileprivate extension Character {
    var unicodeValue: UInt32 {
        return String(self).unicodeScalars.first?.value ?? 0
    }
}

fileprivate extension String.CharacterView {

    mutating func scanCharacters(_ matching: (Character) -> Bool) -> String? {
        var index = endIndex
        for (i, c) in enumerated() {
            if !matching(c) {
                index = self.index(startIndex, offsetBy: i)
                break
            }
        }
        if index > startIndex {
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }

    mutating func scanCharacter(_ matching: (Character) -> Bool) -> String? {
        if let c = first, matching(c) {
            self = suffix(from: index(after: startIndex))
            return String(c)
        }
        return nil
    }

    mutating func scanCharacter(_ character: Character) -> Bool {
        return scanCharacter({ $0 == character }) != nil
    }

    mutating func skipWhitespace() -> Bool {
        if let _ = scanCharacters({
            switch $0 {
            case " ", "\t", "\n", "\r", "\r\n":
                return true
            default:
                return false
            }
        }) {
            return true
        }
        return false
    }

    mutating func parseNumericLiteral() -> Subexpression? {

        func scanInteger() -> String? {
            return scanCharacters {
                if case "0" ... "9" = $0 {
                    return true
                }
                return false
            }
        }

        var number = ""
        if let integer = scanInteger() {
            number = integer
            let endOfInt = self
            if scanCharacter(".") {
                if let fraction = scanInteger() {
                    number += "." + fraction
                } else {
                    self = endOfInt
                }
            }
            let endOfFloat = self
            if let e = scanCharacter({ $0 == "e" || $0 == "E" }) {
                let sign = scanCharacter({ $0 == "-" || $0 == "+" }) ?? ""
                if let exponent = scanInteger() {
                    number += e + sign + exponent
                } else {
                    self = endOfFloat
                }
            }
            return .literal(number)
        }
        return nil
    }

    mutating func parseOperator() -> Subexpression? {
        if let op = scanCharacter({
            if "(),/=­-+!*%<>&|^~?".characters.contains($0) {
                return true
            }
            switch $0.unicodeValue {
            case 0x00A1 ... 0x00A7,
                 0x00A9, 0x00AB, 0x00AC, 0x00AE,
                 0x00B0 ... 0x00B1,
                 0x00B6, 0x00BB, 0x00BF, 0x00D7, 0x00F7,
                 0x2016 ... 0x2017,
                 0x2020 ... 0x2027,
                 0x2030 ... 0x203E,
                 0x2041 ... 0x2053,
                 0x2055 ... 0x205E,
                 0x2190 ... 0x23FF,
                 0x2500 ... 0x2775,
                 0x2794 ... 0x2BFF,
                 0x2E00 ... 0x2E7F,
                 0x3001 ... 0x3003,
                 0x3008 ... 0x3030:
                return true
            default:
                return false
            }
        }) {
            return .infix(op) // assume infix, will determine later
        }
        return nil
    }

    mutating func parseIdentifier() -> Subexpression? {

        func isHead(_ c: Character) -> Bool {
            switch c.unicodeValue {
            case 0x41 ... 0x5A, // A-Z
                 0x61 ... 0x7A, // a-z
                 0x5F, 0x24, // _ and $
                 0x00A8, 0x00AA, 0x00AD, 0x00AF,
                 0x00B2 ... 0x00B5,
                 0x00B7 ... 0x00BA,
                 0x00BC ... 0x00BE,
                 0x00C0 ... 0x00D6,
                 0x00D8 ... 0x00F6,
                 0x00F8 ... 0x00FF,
                 0x0100 ... 0x02FF,
                 0x0370 ... 0x167F,
                 0x1681 ... 0x180D,
                 0x180F ... 0x1DBF,
                 0x1E00 ... 0x1FFF,
                 0x200B ... 0x200D,
                 0x202A ... 0x202E,
                 0x203F ... 0x2040,
                 0x2054,
                 0x2060 ... 0x206F,
                 0x2070 ... 0x20CF,
                 0x2100 ... 0x218F,
                 0x2460 ... 0x24FF,
                 0x2776 ... 0x2793,
                 0x2C00 ... 0x2DFF,
                 0x2E80 ... 0x2FFF,
                 0x3004 ... 0x3007,
                 0x3021 ... 0x302F,
                 0x3031 ... 0x303F,
                 0x3040 ... 0xD7FF,
                 0xF900 ... 0xFD3D,
                 0xFD40 ... 0xFDCF,
                 0xFDF0 ... 0xFE1F,
                 0xFE30 ... 0xFE44,
                 0xFE47 ... 0xFFFD,
                 0x10000 ... 0x1FFFD,
                 0x20000 ... 0x2FFFD,
                 0x30000 ... 0x3FFFD,
                 0x40000 ... 0x4FFFD,
                 0x50000 ... 0x5FFFD,
                 0x60000 ... 0x6FFFD,
                 0x70000 ... 0x7FFFD,
                 0x80000 ... 0x8FFFD,
                 0x90000 ... 0x9FFFD,
                 0xA0000 ... 0xAFFFD,
                 0xB0000 ... 0xBFFFD,
                 0xC0000 ... 0xCFFFD,
                 0xD0000 ... 0xDFFFD,
                 0xE0000 ... 0xEFFFD:
                return true
            default:
                return false
            }
        }

        func isTail(_ c: Character) -> Bool {
            switch c.unicodeValue {
            case 0x30 ... 0x39, // 0-9
                 0x0300 ... 0x036F,
                 0x1DC0 ... 0x1DFF,
                 0x20D0 ... 0x20FF,
                 0xFE20 ... 0xFE2F:
                return true
            default:
                return isHead(c)
            }
        }

        func scanIdentifier() -> String? {
            if let head = scanCharacter({ isHead($0) || $0 == "@" || $0 == "#" }) {
                if let tail = scanCharacters({ isTail($0) || $0 == "." }) {
                    if tail.characters.last == "." {
                        self.insert(".", at: startIndex)
                        return head + String(tail.characters.dropLast())
                    }
                    return head + tail
                }
                return head
            }
            return nil
        }

        if let identifier = scanIdentifier() {
            return .operand(.constant(identifier), [])
        }
        return nil
    }

    mutating func parseSubexpression() throws -> Subexpression {
        var stack: [Subexpression] = []
        var scopes: [[Subexpression]] = []

        func precedence(_ op: String) -> Int {
            switch op {
            case "*", "/":
                return 1
            case ",":
                return -1
            default:
                return 0
            }
        }

        func collapseStack(from i: Int) throws {
            guard stack.count > 1 else {
                return
            }
            let lhs = stack[i]
            switch lhs {
            case .infix(let name), .postfix(let name):
                // probably miscategorized - try treating as prefix
                stack[i] = .prefix(name)
                try collapseStack(from: i)
                return
            case .prefix(let name):
                switch stack[i + 1] {
                case .literal, .operand:
                    // prefix operator
                    stack[i ... i + 1] = [.operand(.prefix(name), [stack[i + 1]])]
                    try collapseStack(from: 0)
                    return
                default:
                    // nested prefix operator?
                    try collapseStack(from: i + 1)
                    return
                }
            case .literal, .operand:
                switch stack[i + 1] {
                case .literal(let value), .prefix(let value):
                    // cannot follow an operand
                    throw Expression.Error.unexpectedToken(String(value))
                case .operand(let symbol, _):
                    if case .constant(let name) = symbol {
                        // treat as a postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(name), [stack[i]])]
                        try collapseStack(from: 0)
                        return
                    }
                    // operand cannot follow another operand
                    // TODO: the symbol may not be the first part of the operand
                    throw Expression.Error.unexpectedToken(symbol.name)
                case .postfix(let op1):
                    stack[i ... i + 1] = [.operand(.postfix(op1), [lhs])]
                    try collapseStack(from: 0)
                    return
                case .infix(let op1):
                    let rhs = stack[i + 2]
                    switch rhs {
                    case .infix, .postfix:
                        // probably miscategorized - try treating as prefix
                        fallthrough
                    case .prefix:
                        try collapseStack(from: i + 2)
                        return
                    default:
                        break
                    }
                    // rhs is an operand
                    guard stack.count > i + 3 else {
                        // infix operator
                        stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    switch stack[i + 3] {
                    case .infix(let op2):
                        if precedence(op1) >= precedence(op2) {
                            stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                            try collapseStack(from: 0)
                            return
                        }
                    default:
                        break
                    }
                    try collapseStack(from: i + 2)
                    return
                }
            }
        }

        var precededByWhitespace = true
        while let expression =
            parseNumericLiteral() ??
            parseOperator() ??
            parseIdentifier() {

            // prepare for next iteration
            let followedByWhitespace = skipWhitespace() || count == 0

            switch expression {
            case .infix("("):
                scopes.append(stack)
                stack = []
            case .infix(")"):
                try collapseStack(from: 0)
                guard var oldStack = scopes.last else {
                    throw Expression.Error.unexpectedToken(")")
                }
                scopes.removeLast()
                if let previous = oldStack.last {
                    if case .operand(.constant(let name), _) = previous {
                        // function call
                        oldStack.removeLast()
                        if stack.count > 0 {
                            // unwrap comma-delimited expression
                            while case .operand(.infix(","), let args) = stack.first! {
                                stack = args + stack.dropFirst()
                            }
                        }
                        stack = [.operand(.function(name, arity: stack.count), stack)]
                    }
                }
                stack = oldStack + stack
            case .infix(","):
                stack.append(expression)
            case .infix(let name):
                if precededByWhitespace {
                    if followedByWhitespace {
                        stack.append(expression)
                    } else {
                        stack.append(.prefix(name))
                    }
                } else if followedByWhitespace {
                    stack.append(.postfix(name))
                } else {
                    stack.append(expression)
                }
            default:
                stack.append(expression)
            }

            // next iteration
            precededByWhitespace = followedByWhitespace
        }
        if let junk = scanCharacters({
            switch $0 {
            case " ", "\t", "\n", "\r", "\r\n":
                return false
            default:
                return true
            }
        }) {
            // Unexpected token
            throw Expression.Error.unexpectedToken(junk)
        }
        if stack.count < 1 {
            // Empty expression
            throw Expression.Error.unexpectedToken("")
        }
        try collapseStack(from: 0)
        if scopes.count > 0 {
            throw Expression.Error.missingDelimiter(")")
        }
        return stack[0]
    }
}
