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
    
    // MARK: Parsing errors
    
    func testMissingCloseParen() {
        let input = "(1 + (2 + 3)"
        XCTAssertThrowsError(try Expression(input), "") { error in
            switch error {
            case Expression.Error.missingDelimiter(let delimiter):
                XCTAssertEqual(delimiter, ")")
            default:
                XCTFail()
            }
        }
    }
    
    func testMissingOpenParen() {
        let input = "1 + 2)"
        XCTAssertThrowsError(try Expression(input), "") { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, ")")
            default:
                XCTFail()
            }
        }
    }
    
    func testInvalidToken() {
        let input = "foo."
        XCTAssertThrowsError(try Expression(input), "") { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, ".")
            default:
                XCTFail()
            }
        }
    }
    
    func testInvalidExpression() {
        let input = "0 5"
        XCTAssertThrowsError(try Expression(input), "") { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, "5")
            default:
                XCTFail()
            }
        }
    }
    
    // MARK: Evaluation errors
    
    func testTooFewArguments() {
        let expression = try! Expression("pow(4)")
        XCTAssertThrowsError(try expression.evaluate(), "") { error in
            switch error {
            case Expression.Error.arityMismatch(.function("pow", arity: 2)):
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testTooManyArguments() {
        let expression = try! Expression("pow(4,5,6)")
        XCTAssertThrowsError(try expression.evaluate(), "") { error in
            switch error {
            case Expression.Error.arityMismatch(.function("pow", arity: 2)):
                break
            default:
                XCTFail()
            }
        }
    }
    
    // MARK: Evaluation
    
    func testLiteral() {
        let expression = try! Expression("5")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 5)
    }
    
    func testNegativeLiteral() {
        let expression = try! Expression("- 12")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, -12)
    }
    
    func testVariable() {
        let expression = try! Expression("foo")
        let result = try! expression.evaluate(["foo": 15.5])
        XCTAssertEqual(result, 15.5)
    }
    
    func testNegativeVariable() {
        let expression = try! Expression("-foo")
        let result = try! expression.evaluate(["foo": 7])
        XCTAssertEqual(result, -7)
    }
    
    func testLiteralAddition() {
        let expression = try! Expression("5 + 4")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 9)
    }
    
    func testLiteralPlusVariable() {
        let expression = try! Expression("3 + foo")
        let result = try! expression.evaluate(["foo": -7])
        XCTAssertEqual(result, -4)
    }
    
    func testLiteralPlusNegativeLiteral() {
        let expression = try! Expression("5+-4")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 1)
    }
    
    func testLiteralTimesNegativeLiteral() {
        let expression = try! Expression("5*-4")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, -20)
    }
    
    func testMultiplePrefixMinusOperators() {
        let expression = try! Expression("5---4")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 1)
    }
    
    func testTwoAdditions() {
        let expression = try! Expression("5 + foo + 4")
        let result = try! expression.evaluate(["foo": 1.5])
        XCTAssertEqual(result, 10.5)
    }
    
    func testAdditionThenMultiplication() {
        let expression = try! Expression("5 + foo * 4")
        let result = try! expression.evaluate(["foo": 1.5])
        XCTAssertEqual(result, 11)
    }
    
    func testAdditionThenMultiplicationWithPrefixMinus() {
        let expression = try! Expression("5 + foo * -4")
        let result = try! expression.evaluate(["foo": 1.5])
        XCTAssertEqual(result, -1)
    }
    
    func testMultiplicationThenAddition() {
        let expression = try! Expression("5 * foo + 4")
        let result = try! expression.evaluate(["foo": 1.5])
        XCTAssertEqual(result, 11.5)
    }
    
    func testParenthesizedAdditionThenMultiplication() {
        let expression = try! Expression("(5 + foo) * 4")
        let result = try! expression.evaluate(["foo": 1.5])
        XCTAssertEqual(result, 26)
    }
    
    func testNestedParenthese() {
        let expression = try! Expression("((5 + 3) * ((2 - 3) - 1))")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, -16)
    }

    func testModFunction() {
        let expression = try! Expression("mod(-4, 2.5)")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, -1.5)
    }
    
    func testSqrtFunction() {
        let expression = try! Expression("7 + sqrt(9)")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 10)
    }
    
    func testPowFunction() {
        let expression = try! Expression("7 + pow(9, 1/2)")
        let result = try! expression.evaluate()
        XCTAssertEqual(result, 10)
    }
}
