# Change Log

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
