# Changes to PostCSS Nesting

### 7.0.1 (July 29, 2018)

- Fixed: Non-breaking issue with rules being unnecessarily split

### 7.0.0 (September 17, 2018)

- Updated: Support for PostCSS v7+
- Updated: Support for Node v6+

In a comment, a CSSWG member expressed interest in handling nested `@media`
while handling selector nesting. Since the specification has yet to be added
to the official CSSWG repository, nested at-rule deprecation is further delayed.

### 6.0.0 (June 9, 2018)

- Deprecated: Nested at-rules like `@media` will no longer work in 7.0.0
- Refactored code to improve efficiency

### 5.0.0 (March 24, 2018)

- Refactored code to use Imports babel-transformed for Node v4 compatibility

### 4.2.1 (September 19, 2017)

- Updated: Exposing the transform function as its own for postcss-extend

### 4.2.0 (September 18, 2017)

- Added: Reduced splitting of rules

### 4.1.0 (August 19, 2017)

- Added: Mutation-safe walk method
- Improved: Complex selector validity testing
- Thanks: A special thanks to @JLHwung for these improvements

### 4.0.1 (May 22, 2017)

- Improved: Selector validity testing

### 4.0.0 (May 20, 2017)

- Changed: Transform only compliant nesting
- Added: Preserve more raws formatting

### 3.0.0 (May 8, 2017)

- Added: Node 4.x support
- Added: PostCSS 6 support
- Added: Preserved ordering
- Removed: Node 0.12 support

### 2.3.1 (March 16, 2016)

- Updated: Allow any direct nesting that follows the syntactic constraints
- Updated: PostCSS 5.0.6
- Updated: Tests
- Updated: Dependencies
- Updated: Project configuration

### 2.3.0 (February 20, 2016)

- Updated: JavaScript formatting, linting, tests, and documentation
- Updated: Properly concatenate at-rules with or expressions
- Updated: Update internal plugin name to postcss-nesting

### 2.2.0 (January 30, 2016)

- Added: Nesting of all at-rules
- Updated: Direct nesting order maintains order
- Updated: Tests and documentation

### 2.1.1 (January 3, 2016)

- Updated: Project conventions

### 2.1.0 (January 3, 2016)

- Added: Support for valid direct nesting

### 2.0.6 (October 15, 2015)

- Fixed: Issue with new PostCSS rules

### 2.0.5 (October 12, 2015)

- Updated: Nested rules source map to the parent rule
- Updated: PostCSS 5.0.9
- Updated: Tests and documentation
- Updated: Project configuration

### 2.0.4 (September 23, 2015)

- Updated: Map source raws

### 2.0.3 (September 22, 2015)

- Updated: Refactored plugin
- Updated: Tests
- Updated: PostCSS 5.0.6

### 2.0.2 (September 16, 2015)

- Fixed: Issue where the new rule’s children were not mapped to the parent internally

### 2.0.1 (September 16, 2015)

- Fixed: Issue where  a `@nest` rule followed by another bubbling at-rule would not bubble
- Added: CONTRIBUTING.md

### 2.0.0 (September 16, 2015)

- Added: Requirement of `&` per the specification
- Added: New prefix option
- Added: `@document` and `@supports` as bubbles
- Updated: Documentation

### 1.0.0 (September 15, 2015)

- Added: New `@nest` at-rule syntax
- Updated: PostCSS 5
- Removed: Old inner bracket syntax

### 0.1.0 (June 17, 2015)

- Added: Initial release
