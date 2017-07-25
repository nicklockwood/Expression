# Change Log

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
- Added additional hard-coded precendence for common operator types and names
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
