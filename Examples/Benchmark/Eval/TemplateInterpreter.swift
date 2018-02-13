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

/// This interpreter is used to evaluate string expressions and return a transformed string, replacing the content where it matches certain patterns.
/// Typically used in web applications, where the rendering of an HTML page is provided as a template, and the application replaces certain statements, based on input parameters.
open class TemplateInterpreter<T> : Interpreter {
    /// The statements (patterns) registered to the interpreter. If found, these are going to be processed and replaced with the evaluated value
    public let statements: [Pattern<T, TemplateInterpreter<T>>]

    /// The context used when evaluating the expressions. These context variables are global, used in every evaluation processed with this instance.
    public let context: Context

    /// The `StringTemplateInterpreter` contains a `TypedInterpreter`, as it is quite common practice to evaluate strongly typed expression as s support for the template language.
    /// Common examples are: condition part of an if statement, or body of a print statement
    public let typedInterpreter: TypedInterpreter

    /// The evaluator type that is being used to process variables. By default, the TypedInterpreter is being used
    public typealias VariableEvaluator = TypedInterpreter

    /// The result type of a template evaluation
    public typealias EvaluatedType = T

    /// The evaluator, that is being used to process variables
    public lazy var interpreterForEvaluatingVariables: TypedInterpreter = { [unowned self] in typedInterpreter }()

    /// The statements, and context parameters are optional, but highly recommended to use with actual values.
    /// In order to properly initialise a `StringTemplateInterpreter`, you'll need a `TypedInterpreter` instance as well.
    /// - parameter statements: The patterns that the interpreter should recognise
    /// - parameter interpreter: A `TypedInterpreter` instance to evaluate typed expressions appearing in the template
    /// - parameter context: Global context that is going to be used with every expression evaluated with the current instance. Defaults to empty context
    public init(statements: [Pattern<T, TemplateInterpreter<T>>] = [],
                interpreter: TypedInterpreter = TypedInterpreter(),
                context: Context = Context()) {
        self.statements = statements
        self.typedInterpreter = interpreter
        self.context = context
    }

    /// The main part of the evaluation happens here. In this case, only the global context variables are going to be used
    /// - parameter expression: The input
    /// - returns: The output of the evaluation
    public func evaluate(_ expression: String) -> T {
        return evaluate(expression, context: Context())
    }

    /// The main part of the evaluation happens here. In this case, the global context variables merged with the provided context are going to be used.
    /// - parameter expression: The input
    /// - parameter context: Local context that is going to be used with this expression only
    /// - returns: The output of the evaluation
    open func evaluate(_ expression: String, context: Context) -> T {
        fatalError("Shouldn't instantiate `TemplateInterpreter` directly. Please subclass with a dedicated type instead")
    }

    /// Reduce block can convet a stream of values into one, by calling this block for every element, returning a single value at the end. The concept is usually used in functional environments
    /// - parameter existing: The previously computed value. In case the current iteration is the first, it's the inital value.
    /// - parameter next: The value of the current element in the iteration
    /// - returns: The a combined value based on the previous and the new value
    public typealias Reducer<T, K> = (_ existing: T, _ next: K) -> T

    /// In order to support generic types, not just plain String objects, a reducer helps to convert the output to the dedicated output type
    /// - parameter initialValue: based on the type, an initial value must to be provided which can serve as a base of the output
    /// - parameter reduceValue: during template execution, if there is some template to replace, the output value can be used to append to the previously existing output
    /// - parameter reduceCharacter: during template execution, if there is nothing to replace, the value is computed by the character-by-character iteration, appending to the previously existing output
    public typealias TemplateReducer = (initialValue: T, reduceValue: Reducer<T, T>, reduceCharacter: Reducer<T, Character>)

    /// The main part of the evaluation happens here. In this case, the global context variables merged with the provided context are going to be used.
    /// - parameter expression: The input
    /// - parameter context: Local context that is going to be used with this expression only
    /// - parameter reducer: In order to support generic types, not just plain String objects, a reducer helps to convert the output to the dedicated output type
    /// - returns: The output of the evaluation
    public func evaluate(_ expression: String, context: Context = Context(), reducer: TemplateReducer) -> T {
        context.merge(with: self.context) { existing, _ in existing }
        var output = reducer.initialValue

        var position = 0
        repeat {
            let result = matchStatement(amongst: statements, in: expression, from: position, interpreter: self, context: context)
            switch result {
            case .noMatch, .possibleMatch:
                output = reducer.reduceCharacter(output, expression[position])
                position += 1
            case let .exactMatch(length, matchOutput, _):
                output = reducer.reduceValue(output, matchOutput)
                position += length
            default:
                assertionFailure("Invalid result")
            }
        } while position < expression.count

        return output
    }
}

/// This interpreter is used to evaluate string expressions and return a transformed string, replacing the content where it matches certain patterns.
/// Typically used in web applications, where the rendering of an HTML page is provided as a template, and the application replaces certain statements, based on input parameters.
public class StringTemplateInterpreter: TemplateInterpreter<String> {
    /// The result of a template evaluation is a String
    public typealias EvaluatedType = String

    /// The main part of the evaluation happens here. In this case, the global context variables merged with the provided context are going to be used.
    /// - parameter expression: The input
    /// - parameter context: Local context that is going to be used with this expression only
    /// - returns: The output of the evaluation
    public override func evaluate(_ expression: String, context: Context) -> String {
        guard !expression.isEmpty else { return "" }
        return evaluate(expression, context: context, reducer: (initialValue: "", reduceValue: { existing, next in existing + next }, reduceCharacter: { existing, next in existing + String(next) }))
    }
}

/// A special kind of variable that is used in case of `StringTemplateInterpreter`s. It does not convert its content using the `interpreterForEvaluatingVariables` but always uses the `StringTemplateInterpreter` instance.
/// It's perfect for expressions, that have a body, that needs to be further interpreted, such as an if or while statement.
public class TemplateVariable: GenericVariable<String, StringTemplateInterpreter> {
    /// No changes compared to the initialiser of the superclass `Variable`, uses the same parameters
    /// - parameter name: `GenericVariable`s have a name (unique identifier), that is used when matching and returning them in the matcher.
    /// - parameter options: Options that modify the behaviour of the variable matching, and the output that the framework provides
    /// - parameter map: If provided, then the result of the evaluated variable will be running through this map function
    /// Whether the processed variable sould be trimmed (removing whitespaces from both sides). Defaults to `true`
    public override init(_ name: String, options: VariableOptions = [], map: @escaping VariableMapper<String, StringTemplateInterpreter> = { (value, _) in value as? String }) {
        super.init(name, options: options.union(.notInterpreted)) { value, interpreter in
            guard let stringValue = value as? String else { return "" }
            let result = options.interpreted ? interpreter.evaluate(stringValue) : stringValue
            return map(result, interpreter)
        }
    }
}

