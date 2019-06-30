# Change Log

## [0.13.2](https://github.com/nicklockwood/Expression/releases/tag/0.13.2) (2019-06-30)

- AnyExpression now supports concurrent evaluation on Linux
- Fixed NSString bug on Linux

## [0.13.1](https://github.com/nicklockwood/Expression/releases/tag/0.13.1) (2019-06-05)

- Fixed error in Swift 5.1 beta

## [0.13.0](https://github.com/nicklockwood/Expression/releases/tag/0.13.0) (2019-05-10)

- Fixed Xcode 10.2 warnings
- Expression now requires a minimum Swift version of 4.2

## [0.12.12](https://github.com/nicklockwood/Expression/releases/tag/0.12.12) (2019-03-26)

- Expression now builds correctly on Linux, including the test suite
- Fixed bug where whitespace around operators could affect the precedence
- Fixed a bug where numeric values could incorrectly be printed as a boolean

## [0.12.11](https://github.com/nicklockwood/Expression/releases/tag/0.12.11) (2018-06-15)

- Fixed all warnings in Xcode 10 beta
- Expression now requires Xcode 9.3 or higher

## [0.12.10](https://github.com/nicklockwood/Expression/releases/tag/0.12.10) (2018-06-05)

- Fixed compilation errors in Xcode 10 beta (but not warnings, yet)
- Fixed slow-compiling unit tests

## [0.12.9](https://github.com/nicklockwood/Expression/releases/tag/0.12.9) (2018-03-07)

- AnyExpression now works on Linux, with a couple of caveats (see README for details)
- Fixed Swift Package Manager integration

## [0.12.8](https://github.com/nicklockwood/Expression/releases/tag/0.12.8) (2018-02-26)

- Pure function symbols now take precedence over impure SymbolEvaluator symbols of the same name

## [0.12.7](https://github.com/nicklockwood/Expression/releases/tag/0.12.7) (2018-02-26)

- Anonymous function syntax now works with all symbol types
- AnyExpression `evaluate()` now supports CGFloat values
- AnyExpression now correctly handles `NSArray` and `NSDictionary` values
- Improved AnyExpression stringifying of array, dictionary and partial range values
- Improved error messages for invalid range and type mismatch
- Added AnyExpression REPL example project

## [0.12.6](https://github.com/nicklockwood/Expression/releases/tag/0.12.6) (2018-02-22)

- AnyExpression now supports calling functions stored in a constant or variable
- AnyExpression now supports calling anonymous functions returned by a sub-expression
- Fixed some bugs with array constants incorrectly shadowing symbols

## [0.12.5](https://github.com/nicklockwood/Expression/releases/tag/0.12.5) (2018-02-13)

- Added Benchmark app for comparing Expression performance against NSExpression and JavaScriptCore
- Added support for partial ranges (e.g. `array[startIndex...]`, `string[...upperBound]`, etc)
- Fixed crash when accessing string with an out-of-bounds range

## [0.12.4](https://github.com/nicklockwood/Expression/releases/tag/0.12.4) (2018-02-12)

- Array subscripting operator can now be used with array literals and the result of expressions
- Added support for subscripting strings using either `String.Index` or `Int` character offsets
- AnyExpression now supports range literals using the `...` and `..<` operators
- You can now create substrings or sub-arrays using subscript syntax with range values
- Added automatic casting between `String` and `Substring` within expressions
- AnyExpression's + operator can now concatenate arrays as well as strings

## [0.12.3](https://github.com/nicklockwood/Expression/releases/tag/0.12.3) (2018-02-06)

- AnyExpression now supports array literals like `[1,2,3]` and `["hello", "world"]`
- AnyExpression can now automatically cast between numeric arrays of different types
- Improved messaging for function arity errors and some types of syntax error
- Fixed Swift 3.2 compatibility issues

## [0.12.2](https://github.com/nicklockwood/Expression/releases/tag/0.12.2) (2018-02-05)

- AnyExpression now supports subscripting of `ArraySlice` and `Dictionary` values
- AnyExpression's `evaluate()` type casting now supports almost all numeric types
- Improved AnyExpression error messaging, especially array subscripting errors

## [0.12.1](https://github.com/nicklockwood/Expression/releases/tag/0.12.1) (2018-01-31)

- Reduced initialization time for `Expression` and `AnyExpression` instances

## [0.12.0](https://github.com/nicklockwood/Expression/releases/tag/0.12.0) (2018-01-25)

- An `AnyExpression` instance can now be evaluated concurrently on multiple threads (`Expression` instances were already thread-safe)
- Using the AnyExpression == operator with unsupported types now throws an error instead of returning false
- Significantly reduced initialization time for Expression and AnyExpression instances
- The `boolSymbols` and `noOptimize` options now work correctly for AnyExpression
- Removed all deprecated APIs and deprecation warnings

## [0.11.4](https://github.com/nicklockwood/Expression/releases/tag/0.11.4) (2018-01-24)

- Improved AnyExpression == operator implementation, now supports equating tuples and dictionaries
- Array symbols implemented using `symbols` dictionary are no longer inlined by optimizer, in accordance with documentation
- Deprecated the `Evaluator` function and provided alternative initializers for `Expression` and `AnyExpression`
- Removed deferred optimization. Expressions using a custom `Evaluator` function may now run slower as a result

## [0.11.3](https://github.com/nicklockwood/Expression/releases/tag/0.11.3) (2018-01-22)

- Added new initializers for Expression and AnyExpression to simplify and improve performance when using advanced features
- Attempting to index an array with a non-numeric type in AnyExpression now produces a more meaningful error message
- Fixed optimization bug when using the built-in `pi` constant

## [0.11.2](https://github.com/nicklockwood/Expression/releases/tag/0.11.2) (2018-01-18)

- Significantly improved AnyExpression evaluation performance
- The `pureSymbols` option is now taken into account when optimizing custom AnyExpression symbols
- Added `noDeferredOptimize` option to disable additional optimization of expressions during first evaluation
- Updated performance tests to include tests for boolean expressions and AnyExpression

## [0.11.1](https://github.com/nicklockwood/Expression/releases/tag/0.11.1) (2018-01-17)

- Fixed optimization bug where custom symbols could unexpectedly produce NaN output in AnyExpression
- The `pureSymbols` option now has no effect for AnyExpression (regular Expression is unaffected)

## [0.11.0](https://github.com/nicklockwood/Expression/releases/tag/0.11.0) (2018-01-16)

- Added `AnyExpression` extension for dealing with arbitrary data types
- Renamed `Symbol.Evaluator` to `SymbolEvaluator` (the old name is now deprecated)
- Improved error messages for missing function arguments

## [0.10.0](https://github.com/nicklockwood/Expression/releases/tag/0.10.0) (2017-12-28)

- Added support for variadic functions. This may cause minor breaking changes to custom Evaluator functions
- The built-in `min()` and `max()` functions now both support more than two arguments (using the new variadics support) 

## [0.9.3](https://github.com/nicklockwood/Expression/releases/tag/0.9.3) (2017-12-18)

- Hyphens are now only permitted at the start of an operator, which solves an ambiguity with unary minus
- Dots are now only permitted at the start of an operator, which solves an ambiguity with float literals

## [0.9.2](https://github.com/nicklockwood/Expression/releases/tag/0.9.2) (2017-12-15)

- A dot followed by a digit is now treated as a floating point literal instead of an identifier
- Parens are no longer stripped around function arguments containing a comma operator (tuples)
- Fixed edge case when printing description for operators containing special characters
- Refactored parser implementation to removed unreachable code and improve test coverage
- Improved error message when trying to pass multiple arguments to an array subscript

## [0.9.1](https://github.com/nicklockwood/Expression/releases/tag/0.9.1) (2017-12-04)

- Expression description now correctly escapes unprintable characters in quoted symbols
- Expression description no longer adds unnecessary parens around sub-expressions
- More helpful error messages are now generated for various syntax mistakes
- Improved test coverage and fixed many other minor bugs

## [0.9.0](https://github.com/nicklockwood/Expression/releases/tag/0.9.0) (2017-12-01)

- Switched to a more conventional MIT license
- Added support for array symbols, so expressions like `foo[5]` and `bar[x + 1]` are now possible
- Enabled trailing apostrophe in symbol names, so you can use symbols like `x'`
- Added `isValidIdentifier()` and `isValidOperator()` methods for validating symbol names
- Fixed warnings in Xcode 9.1 and dropped support for Swift 3.1
- Improved cache performance

## [0.8.5](https://github.com/nicklockwood/Expression/releases/tag/0.8.5) (2017-09-04)

- Improved expression parsing performance in Swift 3.2 and 4.0
- Fixed some bugs in parsing of identifiers containing dots

## [0.8.4](https://github.com/nicklockwood/Expression/releases/tag/0.8.4) (2017-08-22)

- Fixed spurious parsing errors when expressions have leading whitespace
- The `parse(_: String.UnicodeScalarView)` method now accepts an optional list of terminating delimiters

## [0.8.3](https://github.com/nicklockwood/Expression/releases/tag/0.8.3) (2017-08-16)

- Fixed crash when parsing a malformed expression that contains just a single operator
- Internal `mathSymbols` and `boolSymbols` dictionaries are now public, so you can filter them from symbols array

## [0.8.2](https://github.com/nicklockwood/Expression/releases/tag/0.8.2) (2017-08-08)

- Xcode 9b5 compatibility fixes

## [0.8.1](https://github.com/nicklockwood/Expression/releases/tag/0.8.1) (2017-07-25)

- Now marks the correct token as unexpected when attempting to chain function calls (e.g. `foo(5)(6)`)
- Now produces a clearer error for empty expressions

## [0.8.0](https://github.com/nicklockwood/Expression/releases/tag/0.8.0) (2017-07-07)

- Added `parse(_: String.UnicodeScalarView)` method for parsing expressions embedded in an interpolated string
- Improved parsing of expressions containing ambiguous whitespace around operators
- Fixed some more bugs in the expression description logic
- Removed the deprecated `noCache` option

## [0.7.1](https://github.com/nicklockwood/Expression/releases/tag/0.7.1) (2017-07-05)

- Made `clearCache()` method public (was previously left internal by accident)
- Added additional hard-coded precedence for common operator types and names
- Now supports right-associativity for assignment and comparison operators
- Improved description logic, now correctly handles nested prefix/postfix operators
- Added support for infix alphanumeric operators, in addition to postfix
- Fixed bug when parsing a binary `?:` operator
- Swift 4 compatibility fixes

## [0.7.0](https://github.com/nicklockwood/Expression/releases/tag/0.7.0) (2017-06-03)

- Significantly improved evaluation performance of by storing functions inline inside the parsed expression
- Expressions can now contain quoted string literals, which are treated as identifiers (variable names)
- Added `pureSymbols` optimization option, allowing custom functions and operators to be inlined where possible
- Added deferred optimization, allowing functions that use a custom evaluator take advantage of optimization
- Added `parse(_, usingCache:)` method for fine-grained control of caching and pre-parsing
- The `clearCache()` method now optionally accepts a specific expression to be cleared
- Deprecated the `noCache` option. Use the new `parse(_, usingCache:)` method instead
- Added optimization guide to the README file

## [0.6.1](https://github.com/nicklockwood/Expression/releases/tag/0.6.1) (2017-05-28)

- Fixed bug where optimizer stopped as soon as it encountered a custom symbol in the expression

## [0.6.0](https://github.com/nicklockwood/Expression/releases/tag/0.6.0) (2017-05-27)

- BREAKING CHANGE: `constant` symbols have now been renamed to `variable` to more accurately reflect their behavior
- Minor breaking change: `description` now returns the optimized description
- Added built-in symbol library for boolean operations
- Added thread-safe in-memory caching of previously parsed expressions
- Improved optimizer - now pre-evaluates subexpressions with constant arguments
- Added configuration options for enabling/disabling optimizations and boolean arguments
- Added modulo `%` operator to the standard math symbol library
- Added support for hexadecimal literals

## [0.5.0](https://github.com/nicklockwood/Expression/releases/tag/0.5.0) (2017-04-12)

- Added support for multi-character operators, and precedence rules for most standard operators
- Added special-case support for implementing a ternary `?:` operator with 3 arguments
- Static constants are now replaced by their literal values at initialization time, reducing lookup overhead
- Constant expressions are now computed once at initialization time and then cached
- Numeric literals are now stored as Doubles instead of Strings, avoiding conversion overhead
- Fixed bug where printing an expression omitted the parens around sub-expressions
- Fixed crash when parsing a trailing postfix operator preceded by a space
- Fixed bug in Colors example when running on 32-bit

## [0.4.0](https://github.com/nicklockwood/Expression/releases/tag/0.4.0) (2017-03-27)

- You can now get all symbols used by an expression via the `symbols` property
- Fixed crash with postfix operators followed by comma or closing paren

## [0.3](https://github.com/nicklockwood/Expression/releases/tag/0.3) (2017-01-04)

- Fixed crash when processing malformed expression
- Added support for Swift Package Manager and Linux
- Updated for latest Xcode version

## [0.2](https://github.com/nicklockwood/Expression/releases/tag/0.2) (2016-10-15)

- `Expression.init` no longer throws. The expression will still be compiled on init, but errors won't be thrown until first evaluation
- Added optional `constants` and `symbols` arguments to `Expression.init` for simpler setup of custom functions and operators
- Removed the `constants` param from the `evaluate()` function - this can now be provided in `Expression.init`
- Added automatic error reporting for custom functions called with the wrong arity
- Improved evaluation performance for built-in symbols

## [0.1](https://github.com/nicklockwood/Expression/releases/tag/0.1) (2016-10-01)

- First release
