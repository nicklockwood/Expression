//
//  ExpressionTests.swift
//  ExpressionTests
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

import XCTest
@testable import Expression

class ExpressionTests: XCTestCase {

    // MARK: Description

    func testDescriptionSpacing() {
        let expression = Expression("a+b")
        XCTAssertEqual(expression.description, "a + b")
    }

    func testDescriptionParensAdded() {
        let expression = Expression("a+b*c")
        XCTAssertEqual(expression.description, "a + (b * c)")
    }

    func testDescriptionParensPreserved() {
        let expression = Expression("a*(b+c)")
        XCTAssertEqual(expression.description, "a * (b + c)")
    }

    func testDescriptionParensPreserved2() {
        let expression = Expression("(a+b)*c")
        XCTAssertEqual(expression.description, "(a + b) * c")
    }

    func testDescriptionRedundantParensDiscarded() {
        let expression = Expression("(a+b)+c")
        XCTAssertEqual(expression.description, "a + b + c")
    }

    func testIntExpressionDescription() {
        let expression = Expression("32 + 200014")
        XCTAssertEqual(expression.description, "200046")
    }

    func testFloatExpressionDescription() {
        let expression = Expression("2.4 + 7.65")
        XCTAssertEqual(expression.description, "10.05")
    }

    func testPrefixOperatorDescription() {
        let expression = Expression("-foo")
        XCTAssertEqual(expression.description, "-foo")
    }

    func testPrefixOperatorInsidePostfixExpressionDescription() {
        let expression = Expression("(-foo)%")
        XCTAssertEqual(expression.description, "-foo%")
    }

    func testInfixOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-(a+b)")
        XCTAssertEqual(expression.description, "-(a + b)")
    }

    func testNestedPrefixOperatorDescription() {
        let expression = Expression("- -foo")
        XCTAssertEqual(expression.description, "-(-foo)")
    }

    func testPostfixOperatorDescription() {
        let expression = Expression("foo%")
        XCTAssertEqual(expression.description, "foo%")
    }

    func testNestedPostfixOperatorDescription() {
        let expression = Expression("foo% !")
        XCTAssertEqual(expression.description, "(foo%)!")
    }

    func testPostfixOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-(foo%)")
        XCTAssertEqual(expression.description, "-(foo%)")
    }

    func testInfixOperatorInsidePostfixExpressionDescription() {
        let expression = Expression("(a+b)%")
        XCTAssertEqual(expression.description, "(a + b)%")
    }

    func testPostfixOperatorInsideInfixExpressionDescription() {
        let expression = Expression("foo% + 5")
        XCTAssertEqual(expression.description, "foo% + 5")
    }

    func testPostfixAlphanumericOperatorDescription() {
        let expression = Expression("5ms")
        XCTAssertEqual(expression.description, "5ms")
    }

    func testPostfixAlphanumericOperatorDescription2() {
        let expression = Expression("foo ms")
        XCTAssertEqual(expression.description, "(foo)ms")
    }

    func testPostfixAlphanumericOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-foo ms")
        XCTAssertEqual(expression.description, "(-foo)ms")
    }

    func testInfixAlphanumericOperatorDescription() {
        let expression = Expression("foo or bar")
        XCTAssertEqual(expression.description, "foo or bar")
    }

    func testNestedPostfixAlphanumericOperatorsDescription() {
        let expression = Expression("(foo bar) baz")
        XCTAssertEqual(expression.description, "((foo)bar)baz")
    }

    func testRightAssociativeOperatorsDescription() {
        let expression = Expression("(a = b) = c")
        XCTAssertEqual(expression.description, "(a = b) = c")
    }

    func testRightAssociativeOperatorsDescription2() {
        let expression = Expression("a == b > c")
        XCTAssertEqual(expression.description, "a == (b > c)")
    }

    func testInfixDotOperatorDescription() {
        let expression = Expression("(foo).(bar)")
        XCTAssertEqual(expression.description, "foo . bar")
    }

    func testPrefixDotOperatorDescription() {
        let expression = Expression(".(foo)")
        XCTAssertEqual(expression.description, ".(foo)")
    }

    // MARK: Numbers

    func testZero() {
        let expression = Expression("0")
        XCTAssertEqual(try expression.evaluate(), 0)
    }

    func testSmallInteger() {
        let expression = Expression("5")
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    func testLargeInteger() {
        let expression = Expression("12345678901234567890")
        XCTAssertEqual(try expression.evaluate(), 12345678901234567890)
    }

    func testNegativeInteger() {
        let expression = Expression("-7")
        XCTAssertEqual(try expression.evaluate(), -7)
    }

    func testSmallFloat() {
        let expression = Expression("0.2")
        XCTAssertEqual(try expression.evaluate(), 0.2)
    }

    func testLargeFloat() {
        let expression = Expression("1234.567890")
        XCTAssertEqual(try expression.evaluate(), 1234.567890)
    }

    func testNegativeFloat() {
        let expression = Expression("-0.34")
        XCTAssertEqual(try expression.evaluate(), -0.34)
    }

    func testExponential() {
        let expression = Expression("1234e5")
        XCTAssertEqual(try expression.evaluate(), 1234e5)
    }

    func testPositiveExponential() {
        let expression = Expression("0.123e+4")
        XCTAssertEqual(try expression.evaluate(), 0.123e+4)
    }

    func testNegativeExponential() {
        let expression = Expression("0.123e-4")
        XCTAssertEqual(try expression.evaluate(), 0.123e-4)
    }

    func testCapitalExponential() {
        let expression = Expression("0.123E-4")
        XCTAssertEqual(try expression.evaluate(), 0.123e-4)
    }

    func testInvalidExponential() {
        let expression = Expression("123.e5")
        XCTAssertThrowsError(try expression.evaluate())
    }

    func testLeadingZeros() {
        let expression = Expression("0005")
        XCTAssertEqual(try expression.evaluate(), 0005)
    }

    func testHex() {
        let expression = Expression("0x2A")
        XCTAssertEqual(try expression.evaluate(), 0x2A)
    }

    // MARK: Escaped identifiers

    func testDoubleQuotedIdentifier() {
        let expression = Expression.parse("\"foo\" + \"bar\"")
        XCTAssertEqual(expression.symbols, [.variable("\"foo\""), .infix("+"), .variable("\"bar\"")])
    }

    func testSingleQuotedIdentifier() {
        let expression = Expression.parse("'foo' + 'bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo'"), .infix("+"), .variable("'bar'")])
    }

    func testBacktickEscapedIdentifier() {
        let expression = Expression.parse("`foo` + `bar`")
        XCTAssertEqual(expression.symbols, [.variable("`foo`"), .infix("+"), .variable("`bar`")])
    }

    func testBacktickEscapedIdentifierWithEscapedChars() {
        let expression = Expression.parse("`foo\\`bar\\n`")
        XCTAssertEqual(expression.symbols, [.variable("`foo`bar\n`")])
    }

    // MARK: Ambiguous whitespace

    func testPostfixOperatorAsInfix() {
        let expression = Expression.parse("a+ b", usingCache: false)
        XCTAssertEqual(expression.description, "a + b")
    }

    func testPostfixOperatorAsInfix2() {
        let expression = Expression.parse("1+ 2", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 2")
    }

    func testParenthesizedPostfixOperator() {
        let expression = Expression.parse("(a +) b", usingCache: false)
        XCTAssertEqual(expression.description, "(a+)b")
    }

    func testParenthesizedPostfixOperator2() {
        let expression = Expression.parse("(a +) +", usingCache: false)
        XCTAssertEqual(expression.description, "(a+)+")
    }

    func testParenthesizedPrefixOperator() {
        let expression = Expression.parse("+ (+ a)", usingCache: false)
        XCTAssertEqual(expression.description, "+(+a)")
    }


    func testPrefixOperatorAsInfix() {
        let expression = Expression.parse("a +b", usingCache: false)
        XCTAssertEqual(expression.description, "a + b")
    }

    func testPrefixOperatorAsInfix2() {
        let expression = Expression.parse("1 +2", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 2")
    }

    // MARK: Syntax errors

    func testMissingCloseParen() {
        let expression = Expression("(1 + (2 + 3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter(")"))
        }
    }

    func testMissingOpenParen() {
        let expression = Expression("1 + 2)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(")"))
        }
    }

    func testMissingRHS() {
        let expression = Expression("1 + ")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix("+")))
        }
    }

    func testTrailingDot() {
        let expression = Expression("foo.", constants: ["foo": 5])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix(".")))
        }
    }

    func testTrailingDecimalPoint() {
        let expression = Expression("5.")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix(".")))
        }
    }

    func testInvalidExpression() {
        let expression = Expression("0 5")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("5"))
        }
    }

    // MARK: Arity errors

    func testTooFewArguments() {
        let expression = Expression("pow(4)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    func testTooManyArguments() {
        let expression = Expression("pow(4,5,6)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    // MARK: Function overloading

    func testOverridePow() {
        let expression = Expression("pow(3)", symbols: [.function("pow", arity: 1): { $0[0] * $0[0] }])
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testOverriddenPow() {
        let expression = Expression("pow(3,3)", symbols: [.function("pow", arity: 1): { $0[0] * $0[0] }])
        XCTAssertEqual(try expression.evaluate(), 27)
    }

    func testCustomOverriddenFunction() {
        let expression = Expression("foo(3,3)", symbols: [
            .function("foo", arity: 1): { $0[0] },
        ]) { symbol, args in
            switch symbol {
            case .function("foo", arity: 2):
                return args[0] + args[1]
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    // MARK: Function blocking

    func testDisablePow() {
        let symbol = Expression.Symbol.function("pow", arity: 2)
        let expression = Expression("pow(1,2)", symbols: [symbol: { _ in
            throw Expression.Error.undefinedSymbol(symbol)
        }])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.undefinedSymbol(.function("pow", arity: 2)):
                break
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    // MARK: Function chaining

    func testCallResultOfFunction() {
        let expression = Expression("pow(1,2)(3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.unexpectedToken("("):
                break
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    // MARK: Evaluation

    func testLiteral() {
        let expression = Expression("5")
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    func testNegativeLiteral() {
        let expression = Expression("- 12")
        XCTAssertEqual(try expression.evaluate(), -12)
    }

    func testVariable() {
        let expression = Expression("foo", constants: ["foo": 15.5])
        XCTAssertEqual(try expression.evaluate(), 15.5)
    }

    func testNegativeVariable() {
        let expression = Expression("-foo", constants: ["foo": 7])
        XCTAssertEqual(try expression.evaluate(), -7)
    }

    func testLiteralAddition() {
        let expression = Expression("5 + 4")
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testLiteralPlusVariable() {
        let expression = Expression("3 + foo", constants: ["foo": -7])
        XCTAssertEqual(try expression.evaluate(), -4)
    }

    func testLiteralPlusNegativeLiteral() {
        let expression = Expression("5+-4")
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testLiteralTimesNegativeLiteral() {
        let expression = Expression("5*-4")
        XCTAssertEqual(try expression.evaluate(), -20)
    }

    func testTwoAdditions() {
        let expression = Expression("5 + foo + 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 10.5)
    }

    func testAdditionThenMultiplication() {
        let expression = Expression("5 + foo * 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 11)
    }

    func testAdditionThenMultiplicationWithPrefixMinus() {
        let expression = Expression("5 + foo * -4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testMultiplicationThenAddition() {
        let expression = Expression("5 * foo + 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 11.5)
    }

    func testParenthesizedAdditionThenMultiplication() {
        let expression = Expression("(5 + foo) * 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 26)
    }

    func testNestedParenthese() {
        let expression = Expression("((5 + 3) * ((2 - 3) - 1))")
        XCTAssertEqual(try expression.evaluate(), -16)
    }

    func testModFunction() {
        let expression = Expression("mod(-4, 2.5)")
        XCTAssertEqual(try expression.evaluate(), -1.5)
    }

    func testSqrtFunction() {
        let expression = Expression("7 + sqrt(9)")
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    func testPowFunction() {
        let expression = Expression("7 + pow(9, 1/2)")
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    // MARK: Postfix operator parsing

    func testPostfixOperatorBeforeComma() {
        let expression = Expression("max(50%, 0.6)") { symbol, args in
            switch symbol {
            case .postfix("%"):
                return args[0] / 100
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 0.6)
    }

    func testPostfixOperatorBeforeClosingParen() {
        let expression = Expression("min(0.3, 50%)") { symbol, args in
            switch symbol {
            case .postfix("%"):
                return args[0] / 100
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 0.3)
    }

    func testWronglySpacedPostfixOperator() {
        let expression = Expression("50 % + 10%") { symbol, args in
            switch symbol {
            case .postfix("%"):
                return args[0] / 100
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 0.6)
    }

    // MARK: Alphanumeric operators

    func testPostfixAlphanumericOperator() {
        let expression = Expression("10ms + 5s") { symbol, args in
            switch symbol {
            case .postfix("ms"):
                return args[0] / 1000
            case .postfix("s"):
                return args[0]
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 5.01)
    }

    func testInfixAlphanumericOperator() {
        let expression = Expression("true or false", options: .boolSymbols) { symbol, args in
            switch symbol {
            case .infix("or"):
                return args[0] != 0 || args[1] != 0 ? 1 : 0
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    // MARK: Math errors

    func testDivideByZero() {
        let expression = Expression("1 / 0")
        XCTAssertEqual(try expression.evaluate(), Double.infinity)
    }

    func testHugeNumber() {
        let expression = Expression("19911919912912919291291291921929123")
        XCTAssertEqual(try expression.evaluate(), 19911919912912919291291291921929123)
    }

    // MARK: Symbols

    func testModExpressionSymbols() {
        let expression = Expression("mod(foo, bar)", symbols: [
            .variable("foo"): { _ in 5 },
            .variable("bar"): { _ in 2.5 },
        ])
        let expected: Set<Expression.Symbol> = [.function("mod", arity: 2), .variable("foo"), .variable("bar")]
        XCTAssertEqual(expression.symbols, expected)
    }

    // MARK: Optimization

    func testConstantSymbolsInlined() {
        let expression = Expression("foo(bar, baz)", constants: ["bar": 5, "baz": 2.5])
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 2)])
        XCTAssertEqual(expression.description, "foo(5, 2.5)")
    }

    func testConstantExpressionEvaluatedCorrectly() {
        let expression = Expression("5 + foo", constants: ["foo": 5])
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    func testConstantInlined() {
        let expression = Expression("5 + foo", constants: ["foo": 5])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    func testConstantInlined2() {
        let expression = Expression("5 + foo", constants: ["foo": 5], symbols: [.variable("bar"): { _ in 6 }])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    func testPotentiallyImpureConstantNotInlined() {
        let expression = Expression("5 + foo", symbols: [.variable("foo"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + foo")
    }

    func testPureExpressionInlined() {
        let expression = Expression("min(5, 6) + a")
        XCTAssertEqual(expression.symbols, [.variable("a"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + a")
    }

    func testPotentiallyImpureExpressionNotInlined() {
        let expression = Expression("min(5, 6) + a", symbols: [.function("min", arity: 2): { min($0[0], $0[1]) }])
        XCTAssertEqual(expression.symbols, [.function("min", arity: 2), .variable("a"), .infix("+")])
        XCTAssertEqual(expression.description, "min(5, 6) + a")
    }

    func testPotentiallyImpureExpressionNotInlined2() {
        let expression = Expression("min(5, 6) + a", evaluator: { symbol, args in
            if case .function("min", 2) = symbol {
                return min(args[0], args[1])
            }
            return nil
        })
        XCTAssertEqual(expression.symbols, [.function("min", arity: 2), .variable("a"), .infix("+")])
        XCTAssertEqual(expression.description, "min(5, 6) + a")
    }

    func testBooleanExpressionsInlined() {
        let expression = Expression("1 || 1 ? 3 * 5 : 2 * 3", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "15")
    }

    func testVariableDoesntBreakOptimizer() {
        let expression = Expression(
            "foo ? bar : baz",
            options: .boolSymbols,
            constants: ["bar": 5, "baz": 6],
            symbols: [.variable("foo"): { _ in 1 }]
        )
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("?:")])
        XCTAssertEqual(expression.description, "foo ? 5 : 6")
    }

    // MARK: Pure symbols

    func testOverriddenBuiltInConstantNotInlined() {
        let expression = Expression("5 + pi", symbols: [.variable("pi"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testOverriddenBuiltInConstantNotInlinedWithPureSymbols() {
        let expression = Expression("5 + pi", options: .pureSymbols, symbols: [.variable("pi"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testOverriddenBuiltInConstantNotInlinedWithPureEvaluator() {
        let expression = Expression("5 + pi", options: .pureSymbols) { symbol, _ in
            if case .variable("pi") = symbol {
                return 4
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testOverriddenBuiltInFunctionNotInlined() {
        let expression = Expression("5 + floor(1.5)", symbols: [
            .function("floor", arity: 1): { args in ceil(args[0]) },
        ])
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1.5)")
    }

    func testOverriddenBuiltInFunctionInlinedWithPureSymbols() {
        let expression = Expression("5 + floor(1.5)", options: .pureSymbols, symbols: [
            .function("floor", arity: 1): { args in ceil(args[0]) },
        ])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "7")
    }

    func testCustomFunctionNotInlined() {
        let expression = Expression("5 + foo()", symbols: [.function("foo", arity: 0): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("foo", arity: 0)])
        XCTAssertEqual(expression.description, "5 + foo()")
    }

    func testCustomFunctionInlinedWithPureSymbols() {
        let expression = Expression("5 + foo()", options: .pureSymbols, symbols: [.function("foo", arity: 0): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    // MARK: Deferred optimization

    func testBuiltInConstantInlinedAfterEvaluationWithEmptyEvaluator() {
        let expression = Expression("5 + pi") { _, _ in nil }
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
        XCTAssertEqual(try expression.evaluate(), 5 + .pi)
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "\(5.0 + .pi)")
    }

    func testOverriddenBuiltInConstantNotInlinedWithEvaluator() {
        let expression = Expression("5 + pi") { symbol, _ in
            if case .variable("pi") = symbol {
                return 4
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
        XCTAssertEqual(try expression.evaluate(), 9)
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testBuiltInFunctionInlinedAfterEvaluationWithEmptyEvaluator() {
        let expression = Expression("5 + floor(1.5)") { _, _ in nil }
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1.5)")
        XCTAssertEqual(try expression.evaluate(), 6)
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "6")
    }

    func testOverriddenBuiltInFunctionNotInlinedWithEvaluator() {
        let expression = Expression("5 + floor(1.5)") { symbol, args in
            if case .function("floor", arity: 1) = symbol {
                return ceil(args[0])
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1.5)")
        XCTAssertEqual(try expression.evaluate(), 7)
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1.5)")
    }

    func testConditionallyOverriddenBuiltInFunctionInlinedWithEvaluatorAndConstantArg() {
        let expression = Expression("5 + floor(1)") { symbol, args in
            if case .function("floor", arity: 1) = symbol {
                return args[0] == 1 ? nil : ceil(args[0])
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1)")
        XCTAssertEqual(try expression.evaluate(), 6)
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "6")
    }

    func testConditionallyOverriddenBuiltInFunctionNotInlinedWithEvaluatorAndVariableArg() {
        var x: Double = 1
        let expression = Expression("5 + floor(x)", symbols: [.variable("x"): { _ in x }]) { symbol, args in
            if case .function("floor", arity: 1) = symbol {
                return args[0] == 1 ? nil : ceil(args[0])
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
        XCTAssertEqual(try expression.evaluate(), 6)
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
        x = 1.5
        XCTAssertEqual(try expression.evaluate(), 7)
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
    }

    func testConditionallyOverriddenBuiltInFunctionNotInlinedWithEvaluatorAndVariableArg2() {
        var x: Double = 1.5
        let expression = Expression("5 + floor(x)", symbols: [.variable("x"): { _ in x }]) { symbol, args in
            if case .function("floor", arity: 1) = symbol {
                return args[0] == 1 ? nil : ceil(args[0])
            }
            return nil
        }
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
        XCTAssertEqual(try expression.evaluate(), 7)
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
        x = 1
        XCTAssertEqual(try expression.evaluate(), 6)
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("x"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(x)")
    }

    // MARK: Dot operators

    func testDotInsideIdentifier() {
        let expression = Expression("foo.bar", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo.bar")])
    }

    func testDotBetweenParens() {
        let expression = Expression("(foo).(bar)", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("."), .variable("bar")])
    }

    func testIdentifierWithLeadingDot() {
        let expression = Expression(".foo", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable(".foo")])
    }

    func testRangeOperator() {
        let expression = Expression("foo..bar", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix(".."), .variable("bar")])
    }

    // MARK: Ternary operator

    func testTernaryTrue() {
        let expression = Expression("0 ? 1 : 2", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 2)
    }

    func testTernaryFalse() {
        let expression = Expression("1 ? 1 : 2", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testTernaryPrecedence() {
        let expression = Expression("1 - 1 ? 3 * 5 : 2 * 3", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    func testUndefinedTernaryOperator() {
        let symbols: [Expression.Symbol: Expression.Symbol.Evaluator] = [
            .infix("?"): { $0[0] != 0 ? $0[1] : 0 },
            .infix(":"): { $0[0] != 0 ? $0[0] : $0[1] },
        ]
        let expression = Expression("1 - 1 ? 3 * 5 : 2 * 3", symbols: symbols)
        XCTAssertEqual(expression.description, "0 ? 15 : 6")
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    func testTernaryWith2Arguments() {
        let expression1 = Expression("5 ?: 4", options: .boolSymbols)
        XCTAssertEqual(try expression1.evaluate(), 5)
        let expression2 = Expression("0 ?: 4", options: .boolSymbols)
        XCTAssertEqual(try expression2.evaluate(), 4)
    }

    // MARK: Modulo operator

    func testPostiveIntegerModulo() {
        let expression = Expression("5 % 2")
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testNegativeIntegerModulo() {
        let expression = Expression("5 % -2")
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testNegativeIntegerModulo2() {
        let expression = Expression("-5 % 2")
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testNegativeIntegerModulo3() {
        let expression = Expression("-5 % -2")
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testPostiveFloatModulo() {
        let expression = Expression("5.5 % 2")
        XCTAssertEqual(try expression.evaluate(), 1.5)
    }

    func testNegativeFloatModulo() {
        let expression = Expression("5.5 % -2")
        XCTAssertEqual(try expression.evaluate(), 1.5)
    }

    // MARK: Assignment

    func testAssignmentAssociativity() {
        var variables: [Double] = [0, 0]
        let expression = Expression("a = b = 5") { symbol, args in
            switch symbol {
            case .infix("="):
                variables[Int(args[0])] = args[1]
                return args[1]
            case .variable("a"):
                return 0
            case .variable("b"):
                return 1
            default:
                return nil
            }
        }
        XCTAssertEqual(try expression.evaluate(), 5)
        XCTAssertEqual(variables[0], 5)
        XCTAssertEqual(variables[1], 5)
    }
}
