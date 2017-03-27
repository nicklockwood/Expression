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

    // MARK: Syntax errors

    func testMissingCloseParen() {
        let expression = Expression("(1 + (2 + 3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.missingDelimiter(let delimiter):
                XCTAssertEqual(delimiter, ")")
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    func testMissingOpenParen() {
        let expression = Expression("1 + 2)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, ")")
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    func testInvalidToken() {
        let expression = Expression("foo.")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, ".")
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    func testInvalidExpression() {
        let expression = Expression("0 5")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, "5")
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    func testMissingOperand() {
        let expression = Expression("(5+%)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, "%")
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    // MARK: Arity errors

    func testTooFewArguments() {
        let expression = Expression("pow(4)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.arityMismatch(.function("pow", arity: 2)):
                break
            default:
                print("error: \(error)")
                XCTFail()
            }
        }
    }

    func testTooManyArguments() {
        let expression = Expression("pow(4,5,6)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            switch error {
            case Expression.Error.arityMismatch(.function("pow", arity: 2)):
                break
            default:
                print("error: \(error)")
                XCTFail()
            }
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

    func testMultiplePrefixMinusOperators() {
        let expression = Expression("5---4")
        XCTAssertEqual(try expression.evaluate(), 1)
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
        let expression = Expression("mod(foo, bar)", constants: ["foo": 5, "bar": 2.5])
        let expected: Set<Expression.Symbol> = [.function("mod", arity: 2), .constant("foo"), .constant("bar")]
        XCTAssertEqual(expression.symbols, expected)
    }
}
