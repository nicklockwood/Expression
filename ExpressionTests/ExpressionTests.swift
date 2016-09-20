//
//  ExpressionTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 15/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Expression

class ExpressionTests: XCTestCase {
    
    // Parsing errors
    
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
        let input = "foo£"
        XCTAssertThrowsError(try Expression(input), "") { error in
            switch error {
            case Expression.Error.unexpectedToken(let string):
                XCTAssertEqual(string, "£")
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
    
    // Evaluation
    
    func testLiteral() {
        let expression = try! Expression("5")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 5)
    }
    
    func testNegativeLiteral() {
        let expression = try! Expression("- 12")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -12)
    }
    
    func testVariable() {
        let expression = try! Expression("foo")
        guard let result = try? expression.evaluate(["foo": 15.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 15.5)
    }
    
    func testNegativeVariable() {
        let expression = try! Expression("-foo")
        guard let result = try? expression.evaluate(["foo": 7]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -7)
    }
    
    func testLiteralAddition() {
        let expression = try! Expression("5 + 4")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 9)
    }
    
    func testLiteralPlusVariable() {
        let expression = try! Expression("3 + foo")
        guard let result = try? expression.evaluate(["foo": -7]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -4)
    }
    
    func testLiteralPlusNegativeLiteral() {
        let expression = try! Expression("5+-4")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 1)
    }
    
    func testLiteralTimesNegativeLiteral() {
        let expression = try! Expression("5*-4")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -20)
    }
    
    func testTwoAdditions() {
        let expression = try! Expression("5 + foo + 4")
        guard let result = try? expression.evaluate(["foo": 1.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 10.5)
    }
    
    func testAdditionThenMultiplication() {
        let expression = try! Expression("5 + foo * 4")
        guard let result = try? expression.evaluate(["foo": 1.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 11)
    }
    
    func testAdditionThenMultiplicationWithPrefixMinus() {
        let expression = try! Expression("5 + foo * -4")
        guard let result = try? expression.evaluate(["foo": 1.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -1)
    }
    
    func testMultiplicationThenAddition() {
        let expression = try! Expression("5 * foo + 4")
        guard let result = try? expression.evaluate(["foo": 1.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 11.5)
    }
    
    func testParenthesizedAdditionThenMultiplication() {
        let expression = try! Expression("(5 + foo) * 4")
        guard let result = try? expression.evaluate(["foo": 1.5]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 26)
    }
    
    func testNestedParenthese() {
        let expression = try! Expression("((5 + 3) * ((2 - 3) - 1))")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -16)
    }
    
    func testSqrtSymbol() {
        let expression = try! Expression("4 + √9")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 7)
    }
    
    func testModSymbol() {
        let expression = try! Expression("-4 % 2.5")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, -1.5)
    }
    
    func testSqrtFunction() {
        let expression = try! Expression("7 + sqrt(9)")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 10)
    }
    
    func testPowFunction() {
        let expression = try! Expression("7 + pow(9, 1/2)")
        guard let result = try? expression.evaluate() else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, 10)
    }
}
