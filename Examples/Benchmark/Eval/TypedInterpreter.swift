/*
 *  Copyright (c) 2018 Laszlo Teveli.
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

import Foundation

/// A type of interpreter implementation that is capable of evaluating arbitrary string expressions to strongly typed variables
public class TypedInterpreter: Interpreter, Printer {
    /// The result is a strongly typed value or `nil` (if it cannot be properly processed)
    public typealias EvaluatedType = Any?

    /// The global context used for every evaluation with this instance
    public let context: Context

    /// The interpreter used for evaluating variable values. In case of the `TypedInterpreter`, it's itself
    public lazy var interpreterForEvaluatingVariables: TypedInterpreter = { [unowned self] in self }()

    /// The data types that the expression is capable of recognise
    public let dataTypes: [DataTypeProtocol]

    /// The list of functions that are available during the evaluation to process the recognised data types
    public let functions: [FunctionProtocol]

    /// A cache of functions where expressions have matched before. This improves the performance a lot, when computing already established functions
    var functionCache: [String: FunctionProtocol] = [:]

    /// A cache of data types where expressions have matched before. This improves the performance a lot, when computing already established data types
    var dataTypeCache: [String: DataTypeProtocol] = [:]

    /// Each item of the input list (data types, functions and the context) is optional, but strongly recommended to provide them. It's usual that for every data type, there are a few functions provided, so the list can occasionally be pretty long.
    /// - parameter dataTypes: The types the interpreter should recognise the work with
    /// - parameter functions: The functions that can operate on the dataTypes
    /// - context: Global context that is going to be used with every expression evaluated with the current instance. Defaults to empty context
    public init(dataTypes: [DataTypeProtocol] = [],
                functions: [FunctionProtocol] = [],
                context: Context = Context()) {
        self.dataTypes = dataTypes
        self.functions = functions
        self.context = context
    }

    /// The evaluation method, that produces the strongly typed results. In this case, only the globally available context can be used
    /// - parameter expression: The input
    /// - returns: The output of the evaluation
    public func evaluate(_ expression: String) -> Any? {
        return evaluate(expression, context: Context())
    }

    /// The evaluation method, that produces the strongly typed results. In this case, only the context is a result of merging the global context and the one provided in the parameter
    /// - parameter expression: The input
    /// - parameter context: Local context that is going to be used with this expression only
    /// - returns: The output of the evaluation
    public func evaluate(_ expression: String, context: Context) -> Any? {
        context.merge(with: self.context) { existing, _ in existing }
        let expression = expression.trim()

        return functionFromCache(for: expression, using: context)
            ?? dataTypeFromCache(for: expression)
            ?? dataType(for: expression)
            ?? variable(for: expression, using: context)
            ?? function(for: expression, using: context)
    }

    /// If the expression belongs to a cached function, it uses the function converter to evaluate it
    /// - parameter expression: The expression to evaluate
    /// - parameter context: The context to be using when the evaluation happens
    /// - returns: The value - if the expression is interpreted. `nil` otherwise
    func functionFromCache(for expression: String, using context: Context) -> Any? {
        guard let cachedFunction = functionCache[expression],
            let value = cachedFunction.convert(input: expression, interpreter: self, context: context) else { return nil }
        return value
    }

    /// If the expression belongs to a cached data type, it uses the data type converter to evaluate it
    /// - parameter expression: The expression to evaluate
    /// - returns: The value - if the expression is interpreted. `nil` otherwise
    func dataTypeFromCache(for expression: String) -> Any? {
        guard let cachedDataType = dataTypeCache[expression],
            let value = cachedDataType.convert(input: expression, interpreter: self) else { return nil }
        return value
    }

    /// If the expression is recognised as a function, it uses that function to evaluate the value
    /// - parameter expression: The expression to evaluate
    /// - parameter context: The context to be using when the evaluation happens
    /// - returns: The value - if the expression is interpreted. `nil` otherwise
    func function(for expression: String, using context: Context) -> Any? {
        for function in functions.reversed() {
            if let value = function.convert(input: expression, interpreter: self, context: context) {
                functionCache[expression] = function
                return value
            }
        }
        return nil
    }

    /// If the expression is recognised as a data type, it uses that data type to convert its value
    /// - parameter expression: The expression to evaluate
    /// - parameter context: The context to be using when the evaluation happens
    /// - returns: The value - if the expression is interpreted. `nil` otherwise
    func dataType(for expression: String) -> Any? {
        for dataType in dataTypes {
            if let value = dataType.convert(input: expression, interpreter: self) {
                dataTypeCache[expression] = dataType
                return value
            }
        }
        return nil
    }

    /// If the expression is recognised as a variable, it uses that variable to replace its value
    /// - parameter expression: The expression to evaluate
    /// - parameter context: The context where the variables are stored
    /// - returns: The value - if the expression is interpreted. `nil` otherwise
    func variable(for expression: String, using context: Context) -> Any? {
        for variable in context.variables where expression == variable.key {
            return variable.value
        }
        return nil
    }

    /// A helper to be able to effectively print any result, coming out of the evaluation. The `print` method recognises the used data type and uses its string conversion block
    /// - parameter input: Any value that is a valid `DataType` or a `CustomStringConvertible` instance
    /// - returns: The string representation of the value or empty string if it cannot be processed
    public func print(_ input: Any) -> String {
        for dataType in dataTypes {
            if let value = dataType.print(value: input, printer: self) {
                return value
            }
        }
        if let input = input as? CustomStringConvertible {
            return input.description
        }
        return ""
    }
}

/// Data types tell the framework which kind of data can be parsed in the expressions
public protocol DataTypeProtocol {
    /// If the framework meets with some static value that hasn't been processed before, it tries to convert it with every registered data type.
    /// This method returns nil if the conversion could not have been processed with any of the type's literals.
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - returns: The value of the `DataType` or `nil` if it cannot be processed
    func convert(input: String, interpreter: TypedInterpreter) -> Any?

    /// This is a convenience method, for debugging and value printing purposes, which can return a string from the current data type.
    /// It does not need to be unique or always the same for the same input values.
    /// - parameter input: Any value that is a valid `DataType`
    /// - parameter printer: An interpreter instance if the content recursively contains further data types to print
    /// - returns: The string representation of the value or `nil` if it cannot be processed
    func print(value input: Any, printer: Printer) -> String?
}

/// The implementation of a `DataType` uses the `DataTypeProtocol` to convert input to a strongly typed data and print it if needed
public class DataType<T> : DataTypeProtocol {
    /// The existing type to map to an internal one
    let type: T.Type
    /// Array of literals that tell the framework how to transform certain types to an internal `DataType` representation
    let literals: [Literal<T>]
    /// A method to convert an internal representation to strings - for debugging and output representation purposes
    /// - parameter value: The value to print
    /// - parameter printer: An interpreter instance if the content recursively contains further data types to print
    let print: (_ value: T, _ printer: Printer) -> String

    /// To be able to bridge the outside world effectively, it needs to provide an already existing Swift or user-defined type. This can be class, struct, enum, or anything else, for example, block or function (which is not recommended).
    /// The literals tell the framework which strings can be represented in the given data type
    /// The last print block is used to convert the value of any DataType to a string value. It does not need to be unique or always the same for the same input values.
    /// - parameter type: The existing type to map to an internal one
    /// - parameter literals: Array of literals that tell the framework how to transform certain types to an internal `DataType` representation
    /// - parameter print: A method to convert an internal representation to strings - for debugging and output representation purposes
    /// - parameter value: The value to print
    /// - parameter printer: An interpreter instance if the content recursively contains further data types to print
    public init (type: T.Type,
                 literals: [Literal<T>],
                 print: @escaping (_ value: T, _ printer: Printer) -> String) {
        self.type = type
        self.literals = literals
        self.print = print
    }

    /// For the conversion it uses the registered literals, to be able to process the input and return an existing type
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - returns: The value of the `DataType` or `nil` if it cannot be processed
    public func convert(input: String, interpreter: TypedInterpreter) -> Any? {
        return literals.flatMap { $0.convert(input: input, interpreter: interpreter) }.first
    }

    /// This is a convenience method, for debugging and value printing purposes, which can return a string from the current data type.
    /// It does not need to be unique or always the same for the same input values.
    /// - parameter value: Any value that is a valid `DataType`
    /// - parameter printer: An interpreter instance if the content recursively contains further data types to print
    /// - returns: The string representation of the value or `nil` if it cannot be processed
    public func print(value input: Any, printer: Printer) -> String? {
        guard let input = input as? T else { return nil }
        return self.print(input, printer)
    }
}

/// `Literal`s are used by `DataType`s to be able to recognise static values, that can be expressed as a given type
public class Literal<T> {
    /// For the conversion it uses the registered literals, to be able to process the input and return an existing type
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - returns: The value of the `DataType` or `nil` if it cannot be processed
    let convert: (_ input: String, _ interpreter: TypedInterpreter) -> T?

    /// In case of more complicated expression, this initialiser accepts a `convert` block, which can be used to process any value. Return nil, if the input cannot be accepted and converted.
    /// - parameter convert: The conversion block to process values
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    public init(convert: @escaping (_ input: String, _ interpreter: TypedInterpreter) -> T?) {
        self.convert = convert
    }

    /// In case the literals are easily expressed, static keywords, then this initialiser is the best to use.
    /// - parameter check: The string to check for in the input string (with exact match)
    /// - parameter convertsTo: Statically typed associated value. As it is expressed as an autoclosure, the provided expression will be evaluated at recognition time, not initialisation time. For example, Date() is perfectly acceptable to use here.
    public init(_ check: String, convertsTo value: @autoclosure @escaping () -> T) {
        self.convert = { input, _ in check == input ? value() : nil }
    }

    /// For the conversion it uses the registered literals, to be able to process the input and return an existing type
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - returns: The value of the `DataType` or `nil` if it cannot be processed
    func convert(input: String, interpreter: TypedInterpreter) -> T? {
        return convert(input, interpreter)
    }
}

/// `Function`s can process values in given `DataType`s, allowing the expressions to be feature-rich
public protocol FunctionProtocol {
    /// Functions use similar conversion methods as `DataType`s. If they return `nil`, the function does not apply to the given input. Otherwise, the result is expressed as an instance of a given `DataType`
    /// It uses the interpreter the and parsing context to be able to effectively process the content
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - parameter context: The context - if vaiables need any contextual information
    /// - returns: A valid value of any `DataType` or `nil` if it cannot be processed
    func convert(input: String, interpreter: TypedInterpreter, context: Context) -> Any?
}

/// `Function`s can process values in given `DataType`s, allowing the expressions to be feature-rich
public class Function<T> : FunctionProtocol {
    /// Although `Function`s typically contain only one pattern, multiple ones can be added, for semantic grouping purposes
    public let patterns: [Pattern<T, TypedInterpreter>]

    /// If multiple patterns are provided use this initialiser. Otherwise, for only one, there is `init(_,matcher:)`
    /// - parameter patterns: The array of patterns to be able to recognise
    public init(patterns: [Pattern<T, TypedInterpreter>]) {
        self.patterns = patterns
    }

    /// In case there is only one pattern, this initialiser is the preferred one to use
    /// - parameter elements: Contains the pattern that needs to be recognised
    /// - parameter options: Options that modify the pattern matching algorithm
    /// - parameter matcher: Ending closure that transforms and processes the recognised value
    public init(_ elements: [PatternElement], options: PatternOptions = [], matcher: @escaping MatcherBlock<T, TypedInterpreter>) {
        self.patterns = [Pattern(elements, options: options, matcher: matcher)]
    }

    /// The matching of the input expression of a given `Function` happens in this method. It only accepts matches from the matcher, that are exact matches.
    /// - parameter input: The input to convert as a `DataType` value
    /// - parameter interpreter: An interpreter instance if the content needs any further evaluation
    /// - parameter context: The context - if vaiables need any contextual information
    /// - returns: A valid value of any `DataType` or `nil` if it cannot be processed
    public func convert(input: String, interpreter: TypedInterpreter, context: Context) -> Any? {
        guard case let .exactMatch(_, output, _) = matchStatement(amongst: patterns, in: input, interpreter: interpreter, context: context) else { return nil }
        return output
    }
}

/// `Variable` represents a named placeholder, so when the matcher recognises a pattern, the values of the variables are passed to them in a block.
public class Variable<T> : GenericVariable<T, TypedInterpreter> {
}
