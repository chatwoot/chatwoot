# Changes to Media Query List Parser

### 2.1.1 (June 21, 2023)

- Fix parsing of `(width == 100px)`. This was erroneously parsed as a range query and will now instead be a general enclosed node.

### 2.1.0 (June 1, 2023)

- Fix `walk` for `MediaFeatureValue` with complex component values.
- Add `state` to `walk` methods.

This makes it possible pass down information from a parent structure to children.  
e.g. you can set `entry.state.inInPrintQuery = true` for `print and (min-width: 30cm)`.

### 2.0.4 (April 10, 2023)

- Updated `@csstools/css-tokenizer` to `2.1.1` (patch)
- Updated `@csstools/css-parser-algorithms` to `2.1.1` (patch)

### 2.0.3 (April 10, 2023)

- Add support for `env()` functions as values in media queries.
- Improve the detection of math function as values in media queries.

### 2.0.2 (March 25, 2023)

- Improve case insensitive string matching.

### 2.0.1 (January 28, 2023)

- Improve `types` declaration in `package.json`

### 2.0.0 (January 19, 2023)

- Refactor `MediaFeatureBoolean` so that it follows the same structure as `MediaFeaturePlain` (breaking)
- Change the `ParseError` interface, this is now a subclass of `Error` (breaking)
- Add `getName` and `getNameToken` to all nodes that have a feature name.
- Add `@custom-media` parsing.

### 1.0.0 (November 14, 2022)

- Initial version
