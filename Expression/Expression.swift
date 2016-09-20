//
//  Expression.swift
//  Expression
//
//  Created by Nick Lockwood on 15/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

// MARK: Public interface

public typealias Evaluator<T> = (_ symbol: Expression.Symbol, _ args: [T]) -> T?

/// Default evaluator for numeric arguments
public func defaultEvaluator(_ symbol: Expression.Symbol, _ args: [Double]) -> Double? {
    switch symbol {
        
    // MARK: infix operators
    case .infix("+"):
        return args[0] + args[1]
    case .infix("-"):
        return args[0] - args[1]
    case .infix("*"):
        return args[0] * args[1]
    case .infix("/"):
        return args[0] / args[1]
    case .infix("%"):
        guard args.count == 2 else { return nil }
        return fmod(args[0], args[1])
        
    // MARK: prefix operators
    case .prefix("-"):
        return -args[0]
    case .prefix("√"):
        return sqrt(args[0])
    case .prefix("∛"):
        return pow(args[0], 1/3)
    case .prefix("∜"):
        return pow(args[0], 1/4)
        
    // MARK: functions (arity: 1)
    case .function("sqrt"):
        guard args.count == 1 else { return nil }
        return sqrt(args[0])
    case .function("floor"):
        guard args.count == 1 else { return nil }
        return floor(args[0])
    case .function("ceil"):
        guard args.count == 1 else { return nil }
        return ceil(args[0])
    case .function("round"):
        guard args.count == 1 else { return nil }
        return round(args[0])
    case .function("cos"):
        guard args.count == 1 else { return nil }
        return cos(args[0])
    case .function("acos"):
        guard args.count == 1 else { return nil }
        return acos(args[0])
    case .function("sin"):
        guard args.count == 1 else { return nil }
        return sin(args[0])
    case .function("asin"):
        guard args.count == 1 else { return nil }
        return asin(args[0])
    case .function("tan"):
        guard args.count == 1 else { return nil }
        return tan(args[0])
    case .function("atan"):
        guard args.count == 1 else { return nil }
        return atan(args[0])
    case .function("abs"):
        guard args.count == 1 else { return nil }
        return abs(args[0])
        
    // MARK: functions (arity: 2)
    case .function("pow"):
        guard args.count == 2 else { return nil }
        return pow(args[0], args[1])
    case .function("max"):
        guard args.count == 2 else { return nil }
        return max(args[0], args[1])
    case .function("min"):
        guard args.count == 2 else { return nil }
        return min(args[0], args[1])
    case .function("atan"):
        guard args.count == 2 else { return nil }
        return atan2(args[0], args[1])
    case .function("mod"):
        guard args.count == 2 else { return nil }
        return fmod(args[0], args[1])
        
    default:
        return nil
    }
}

/// Default evaluator for String arguments
public func defaultEvaluator(_ symbol: Expression.Symbol, _ args: [String]) -> String? {
    if case .infix("+") = symbol {
        if let lhs = Double(String(args[0])), let rhs = Double(String(args[1])) {
            return String(lhs + rhs)
        } else {
            return args[0] + args[1]
        }
    }
    return nil
}

public class Expression {
    private let root: Subexpression
    
    /// Symbols that make up an expression
    public enum Symbol: CustomStringConvertible {
        case variable(String)
        case infix(String)
        case prefix(String)
        case postfix(String)
        case function(String)
        
        public var name: String {
            switch self {
            case .variable(let string),
                 .infix(let string),
                 .prefix(let string),
                 .postfix(let string),
                 .function(let string):
                return string
            }
        }
        
        public var description: String {
            switch self {
            case .variable:
                return "variable `\(name)`"
            case .infix:
                return "infix operator `\(name)`"
            case .prefix:
                return "prefix operator `\(name)`"
            case .postfix:
                return "postfix operator `\(name)`"
            case .function:
                return "function `\(name)()`"
            }
        }
    }
    
    /// Runtime error when parsing or evaluating an expression
    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedToken(String)
        case missingDelimiter(String)
        case undefinedSymbol(Expression.Symbol)

        public var description: String {
            switch self {
            case .unexpectedToken(let string):
                return "Unexpected symbol `\(string)`"
            case .missingDelimiter(let string):
                return "Missing `\(string)`"
            case .undefinedSymbol(let symbol):
                return "Undefined \(symbol)"
            }
        }
    }
    
    // Default constructor - creates an Expression object from a string
    public init(_ expression: String) throws {
        var characters = expression.characters
        root = try characters.parseSubexpression()
    }
    
    public func evaluate<T: LosslessStringConvertible>(_ evaluator: Evaluator<T>) -> T? {
        return root.evaluate { symbol, args in
            if let value = evaluator(symbol, args) {
                return value
            }
            // Treat as Double
            let doubles: [Double] = args.flatMap { $0 as? Double ?? Double(String($0)) }
            if doubles.count == args.count {
                return defaultEvaluator(symbol, doubles).map { $0 as? T ?? T(String($0))! }
            }
            // Treat as String
            let strings: [String] = args.flatMap { $0 as? String ?? String($0) }
            if strings.count == args.count {
                return defaultEvaluator(symbol, strings).map { $0 as? T ?? T($0)! }
            }
            // Handle error
            
            return nil
        }
    }
    
    public func evaluate<T: LosslessStringConvertible>(_ constants: [String: T]) -> T? {
        return evaluate { symbol, args in
            if case .variable(let name) = symbol {
                return constants[name]
            }
            return nil
        }
    }
    
    public func evaluate<T: LosslessStringConvertible>() -> T? {
        let evaluator: Evaluator<T> = { _ in nil }
        return self.evaluate(evaluator)
    }
}

// MARK: Parser

fileprivate enum Subexpression {
    case literal(String)
    case operand(Expression.Symbol, [Subexpression])
    case `operator`(String)
    
    func evaluate<T: LosslessStringConvertible>(_ evaluator: Evaluator<T>) -> T? {
        switch self {
        case .literal(let value):
            return T(value)
        case .operand(let symbol, let args):
            var argValues: [T] = []
            for arg in args {
                guard let value = arg.evaluate(evaluator) else {
                    return nil // error
                }
                argValues.append(value)
            }
            return evaluator(symbol, argValues)
        case .operator:
            return nil // error
        }
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
        while let c = first {
            switch c {
            case " ", "\t", "\n", "\r", "\r\n":
                self = suffix(from: index(after: startIndex))
            default:
                return true // more to parse
            }
        }
        return false // end of input
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
    
    mutating func parseStringLiteral() throws -> Subexpression? {
        var string = ""
        if let delimiter = scanCharacter({ $0 == "\"" || $0 == "'" })?.characters.first! {
            while count > 0 {
                while let substring = scanCharacters({ $0 != "\\" && $0 != delimiter }) {
                    string += substring
                }
                if scanCharacter("\\") {
                    if let c = scanCharacter({ _ in true }) {
                        switch c {
                        case "t":
                            string += "\t"
                        case "n":
                            string += "\n"
                        case "r":
                            string += "\r"
                        default:
                            string += c
                        }
                    }
                }
                guard scanCharacter(delimiter) else {
                    throw Expression.Error.missingDelimiter(String(delimiter))
                }
                return .literal(string)
            }
        }
        return nil // unterminated string
    }
    
    mutating func parseOperator() -> Subexpression? {
        if let op = scanCharacter({ "(),+-*/\\=!%°^&|<>?~±‡≤≥÷√∛∜".characters.contains($0) }) {
            return .operator(op)
        }
        return nil
    }
    
    mutating func parseIdentifier() -> Subexpression? {
        
        func isHead(_ c: Character) -> Bool {
            switch c {
            case "a" ... "z", "A" ... "Z", "_", "$", "#", "@":
                return true
            default:
                return false
            }
        }
        
        func isTail(_ c: Character) -> Bool {
            if case "0" ... "9" = c {
                return true
            }
            return isHead(c)
        }
        
        func scanIdentifier() -> String? {
            if let head = scanCharacter(isHead) {
                if let tail = scanCharacters(isTail) {
                    return head + tail
                }
                return head
            }
            return nil
        }
        
        if let identifier = scanIdentifier() {
            return .operand(.variable(identifier), [])
        }
        return nil
    }
    
    mutating func parseSubexpression() throws -> Subexpression {
        var stack: [Subexpression] = []
        var scopes: [[Subexpression]] = []
        
        func canBePrefix(_ op: String) -> Bool {
            return "-&√∛∜".contains(op)
        }
        
        func precedence(_ op: String) -> Int {
            switch op {
            case "*", "/":
                return 2
            case ",":
                return -1
            default:
                return 1
            }
        }
        
        func collapseStack(from i: Int) throws {
            guard stack.count > 1 else {
                return
            }
            let lhs = stack[i]
            switch lhs {
            case .operator(let symbol):
                guard canBePrefix(symbol) else {
                    // expression cannot start with a non-prefix operator
                    throw Expression.Error.unexpectedToken(symbol)
                }
                switch stack[i + 1] {
                case .operator:
                    // nested prefix operator?
                    try collapseStack(from: i + 1)
                    return
                case .literal, .operand:
                    // prefix operator
                    stack[i ... i + 1] = [.operand(.prefix(symbol), [stack[1]])]
                    try collapseStack(from: 0)
                    return
                }
            case .literal, .operand:
                switch stack[i + 1] {
                case .literal(let value):
                    // literal cannot follow an operand
                    throw Expression.Error.unexpectedToken(value)
                case .operand(let symbol, _):
                    if case .variable(let name) = symbol {
                        // treat as a postfix operator
                        stack[i + 1] = .operand(.postfix(name), [])
                    }
                    // operand cannot follow another operand
                    // TODO: the symbol may not be the first part of the operand
                    throw Expression.Error.unexpectedToken(symbol.name)
                case .operator(let op1):
                    if stack.count == i + 2 {
                        // postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(op1), [lhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    let rhs = stack[i + 2]
                    if case .operator(let op3) = rhs {
                        if stack.count > i + 3 && canBePrefix(op3) {
                            guard case .operator = stack[3] else {
                                // treat as prefix operator
                                stack[i + 2 ... i + 3] = [.operand(.prefix(op3), [stack[3]])]
                                try collapseStack(from: 0)
                                return
                            }
                        }
                        // postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(op1), [lhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    // rhs is an operand
                    guard stack.count > i + 3 else {
                        // infix operator
                        stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    switch stack[i + 3] {
                    case .operator(let op2):
                        if stack.count > i + 4 {
                            switch stack[i + 4] {
                            case .literal, .operand:
                                //infix operator
                                if precedence(op1) >= precedence(op2) {
                                    stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                                    try collapseStack(from: 0)
                                    return
                                }
                            default:
                                break
                            }
                        }
                    default:
                        break
                    }
                    try collapseStack(from: i + 2)
                    return
                }
            }
        }
        
        
        while skipWhitespace(),
            let expression = try
                parseStringLiteral() ??
                parseNumericLiteral() ??
                parseOperator() ??
                parseIdentifier() {
            
            switch expression {
            case .operator("("):
                scopes.append(stack)
                stack = []
            case .operator(")"):
                try collapseStack(from: 0)
                guard var oldStack = scopes.last else {
                    throw Expression.Error.unexpectedToken(")")
                }
                scopes.removeLast()
                if let previous = oldStack.last {
                    if case .operand(.variable(let name), _) = previous {
                        // function call
                        oldStack.removeLast()
                        if stack.count > 0 {
                            // unwrap comma-delimited expression
                            while case .operand(.infix(","), let args) = stack.last! {
                                stack = args + stack.dropFirst()
                            }
                        }
                        stack = [.operand(.function(name), stack)]
                    }
                }
                stack = oldStack + stack
            default:
                stack.append(expression)
            }
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
