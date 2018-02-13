//
//  Benchmarks.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 13/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
import Expression
import JavaScriptCore

let parseRepetitions = 50
let evalRepetitions = 500

class Benchmarks: XCTestCase {

    // MARK: End-to-end

    func testEndToEndShortExpressions() {
        var result: Double?
        measure {
            result = evaluateExpressions(shortExpressions)
        }
        XCTAssertEqual(result, Double.pi)
    }

    func testEndToEndShortAnyExpressions() {
        var result: Double?
        measure {
            result = evaluateAnyExpressions(shortExpressions)
        }
        XCTAssertEqual(result, Double.pi)
    }

    func testEndToEndShortNSExpressions() {
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(shortNSExpressions)
        }
        XCTAssertEqual(result, Double.pi as NSNumber)
    }

    func testEndToEndShortJSExpressions() {
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(shortExpressions)
        }
        XCTAssertEqual(result?.toNumber(), Double.pi as NSNumber)
    }

    func testEndToEndMediumExpressions() {
        var result: Double?
        measure {
            result = evaluateExpressions(mediumExpressions)
        }
        XCTAssertEqual(result, Double.pi + 15)
    }

    func testEndToEndMediumAnyExpressions() {
        var result: Double?
        measure {
            result = evaluateAnyExpressions(mediumExpressions)
        }
        XCTAssertEqual(result, Double.pi + 15)
    }

    func testEndToEndMediumNSExpressions() {
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(mediumNSExpressions)
        }
        XCTAssertEqual(result, (Double.pi + 15) as NSNumber)
    }

    func testEndToEndMediumJSExpressions() {
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(mediumExpressions)
        }
        XCTAssertEqual(result?.toNumber(), (Double.pi + 15) as NSNumber)
    }

    func testEndToEndLongExpressions() {
        var result: Double?
        measure {
            result = evaluateExpressions(longExpressions)
        }
        XCTAssertEqual(result, Double.pi * -56.4 + 9)
    }

    func testEndToEndLongAnyExpressions() {
        var result: Double?
        measure {
            result = evaluateAnyExpressions(longExpressions)
        }
        XCTAssertEqual(result, Double.pi * -56.4 + 9)
    }

    func testEndToEndLongNSExpressions() {
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(longNSExpressions)
        }
        XCTAssertEqual(result, (Double.pi * -56.4 + 9) as NSNumber)
    }

    func testEndToEndLongJSExpressions() {
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(longExpressions)
        }
        XCTAssertEqual(result?.toNumber(), (Double.pi * -56.4 + 9) as NSNumber)
    }

    // MARK: Evaluation

    func testEvaluateShortExpressions() {
        let expressions = buildExpressions(shortExpressions)
        var result: Double?
        measure {
            result = evaluateExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi)
    }

    func testEvaluateShortAnyExpressions() {
        let expressions = buildAnyExpressions(shortExpressions)
        var result: Double?
        measure {
            result = evaluateAnyExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi)
    }

    func testEvaluateShortNSExpressions() {
        let expressions = buildNSExpressions(shortNSExpressions)
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi as NSNumber)
    }

    func testEvaluateShortJSExpressions() {
        let expressions = buildJSExpressions(shortExpressions)
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(expressions)
        }
        XCTAssertEqual(result?.toNumber(), Double.pi as NSNumber)
    }

    func testEvaluateMediumExpressions() {
        let expressions = buildExpressions(mediumExpressions)
        var result: Double?
        measure {
            result = evaluateExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi + 15)
    }

    func testEvaluateMediumAnyExpressions() {
        let expressions = buildAnyExpressions(mediumExpressions)
        var result: Double?
        measure {
            result = evaluateAnyExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi + 15)
    }

    func testEvaluateMediumNSExpressions() {
        let expressions = buildNSExpressions(mediumNSExpressions)
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(expressions)
        }
        XCTAssertEqual(result, (Double.pi + 15) as NSNumber)
    }

    func testEvaluateMediumJSExpressions() {
        let expressions = buildJSExpressions(mediumExpressions)
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(expressions)
        }
        XCTAssertEqual(result?.toNumber(), (Double.pi + 15) as NSNumber)
    }

    func testEvaluateLongExpressions() {
        let expressions = buildExpressions(longExpressions)
        var result: Double?
        measure {
            result = evaluateExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi * -56.4 + 9)
    }

    func testEvaluateLongAnyExpressions() {
        let expressions = buildAnyExpressions(longExpressions)
        var result: Double?
        measure {
            result = evaluateAnyExpressions(expressions)
        }
        XCTAssertEqual(result, Double.pi * -56.4 + 9)
    }

    func testEvaluateLongNSExpressions() {
        let expressions = buildNSExpressions(longNSExpressions)
        var result: NSNumber?
        measure {
            result = evaluateNSExpressions(expressions)
        }
        XCTAssertEqual(result, (Double.pi * -56.4 + 9) as NSNumber)
    }

    func testEvaluateLongJSExpressions() {
        let expressions = buildJSExpressions(longExpressions)
        var result: JSValue?
        measure {
            result = evaluateJSExpressions(expressions)
        }
        XCTAssertEqual(result?.toNumber(), (Double.pi * -56.4 + 9) as NSNumber)
    }
}
