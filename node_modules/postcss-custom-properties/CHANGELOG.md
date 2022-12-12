# Changes to PostCSS Custom Properties

### 8.0.11 (June 20, 2019)

- Added: Synchronous transforms when async is unnecessary (thank @eteeselink)
- Fixed: Unexpected mutations to imported Custom Properties (thank @EECOLOR)
- Fixed: Transforms throwing over unknown Custom Properties

### 8.0.10 (April 1, 2019)

- Added: Support for ignoring lines and or blocks using
  `postcss-custom-properties` comments.
- Updated: `postcss` to 7.0.14 (patch)
- Updated: `postcss-values-parser` to 2.0.1 (patch)

### 8.0.9 (November 5, 2018)

- Fixed: Issue with duplicate custom property usage within a declaration

### 8.0.8 (October 2, 2018)

- Fixed: Issue with nested fallbacks

### 8.0.7 (October 2, 2018)

- Fixed: Issue with parsing custom properties that are not strings
- Updated: `postcss` to 7.0.5 (patch)

### 8.0.6 (September 21, 2018)

- Fixed: Issue with regular `:root` and `html` properties not getting polyfilled
- Updated: `postcss` to 7.0.3 (patch)

### 8.0.5 (September 21, 2018)

- Fixed: Issue with multiple `importFrom` not getting combined

### 8.0.4 (September 18, 2018)

- Fixed: Do not break on an empty `importFrom` object

### 8.0.3 (September 18, 2018)

- Updated: PostCSS Values Parser 2

### 8.0.2 (September 17, 2018)

- Fixed: Spacing is preserved before replaced variables.

### 8.0.1 (September 17, 2018)

- Fixed: Workaround issue in `postcss-values-parser` incorrectly cloning nodes.

### 8.0.0 (September 16, 2018)

- Added: New `exportTo` function to specify where to export custom properties to.
- Added: New `importFrom` option to specify where to import custom properties from.
- Added: Support for variables written within `html`
- Added: Support for PostCSS v7.
- Added: Support for Node v6+.
- Removed: `strict` option, as using the fallback value isn’t necessarily more valid.
- Removed: `preserve: "computed"` option, as there seems to be little use in preserving custom property declarations while removing all usages of them.
- Removed: `warnings` and `noValueNotifications` options, as this should be the job of a linter tool.
- Removed: `variables` option, which is now replaced by `importFrom`
- Removed: `appendVariables` option, which is now replaced by `exportTo`
- Fixed: Custom Properties in `:root` are not also transformed.
- Fixed: Declarations that do not change are not duplicated during preserve.

### 7.0.0 (February 16, 2018)

- Changed: `preserve` option defaults as `true` to reflect the browser climate
- Changed: `warnings` option defaults to `false` to reflect the browser climate

### 6.3.1 (February 16, 2018)

- Reverted: `preserve` and `warnings` option to be added in major release

### 6.3.0 (February 15, 2018)

- Fixed: `var()` captures strictly `var()` functions and not `xvar()`, etc
- Fixed: `var()` better captures whitespace within the function
- Fixed: comments within declarations using `var()` are now preserved
- Changed: `preserve` option defaults as `true` to reflect the browser climate
- Changed: `warnings` option defaults to `false` to reflect the browser climate
- Updated documentation

### 6.2.0 (October 6, 2017)

- Added: `noValueNotifications` option (#71)
- Fixed: Typo in `prefixedVariables` variable name (#77)

### 6.1.0 (June 28, 2017)

- Added: Let "warnings" option silence all warnings
([#67](https://github.com/postcss/postcss-custom-properties/pull/67))
- Dependencies update (postcss, balanced-match)

### 6.0.1 (May 15, 2017)

- Fixed: incorrect export ([#69](https://github.com/postcss/postcss-custom-properties/issues/69))

### 6.0.0 (May 12, 2017)

- Added: compatibility with postcss v6.x

### 5.0.2 (February 1, 2017)

- Minor dependency update
  ([#57](https://github.com/postcss/postcss-custom-properties/pull/57))

### 5.0.1 (April 22, 2016)

- Fixed: trailing space after custom property name causes duplicate empty
  property
  ([#43](https://github.com/postcss/postcss-custom-properties/pull/43))

### 5.0.0 (August 25, 2015)

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

### 4.2.0 (July 21, 2015)

- Added: `warnings` option allows you to disable warnings.
([cssnext#186](https://github.com/cssnext/cssnext/issues/186))

### 4.1.0 (July 14, 2015)

- Added: plugin now returns itself in order to expose a `setVariables` function
that allow you to programmatically change the variables.
([#35](https://github.com/postcss/postcss-custom-properties/pull/35))

### 4.0.0 (June 17, 2015)

- Changed: messages and exceptions are now sent using postcss message API.

### 3.3.0 (April 8, 2015)

- Added: `preserve` now support `"computed"` so only preserve resolved custom properties (see new option below)
- Added: `appendVariables` allows you (when `preserve` is truthy) to append your variables as custom properties
- Added: `strict: false` allows your to avoid too many fallbacks added in your CSS.

### 3.2.0 (03 31, 2015)

- Added: JS defined variables are now resolved too ([#22](https://github.com/postcss/postcss-custom-properties/issues/22))

### 3.1.0 (03 16, 2015)

- Added: variables defined in JS are now automatically prefixed with `--`
  ([0691784](https://github.com/postcss/postcss-custom-properties/commit/0691784ed2218d7e6b16da8c4df03e2ca0c4798c))

### 3.0.1 (February 6, 2015)

- Fixed: logs now have filename back ([#19](https://github.com/postcss/postcss-custom-properties/issues/19))

### 3.0.0 (January 20, 2015)

- Changed: upgrade to postcss 4 ([#18](https://github.com/postcss/postcss-custom-properties/pull/18))
- Removed: some code that seems to be useless ([16ff3c2](https://github.com/postcss/postcss-custom-properties/commit/16ff3c22fe0563a1283411d7866791966fff4c58))

### 2.1.1 (December 2, 2014)

- Fixed: issue when multiples undefined custom properties are referenced ([#16](https://github.com/postcss/postcss-custom-properties/issues/16))

### 2.1.0 (November 25, 2014)

- Added: enhanced exceptions & messages

### 2.0.0 (November 12, 2014)

- Changed: upgrade to postcss 3

### 1.0.2 (November 4, 2014)

- Fixed: more clear message for warning about custom prop used in non top-level :root

### 1.0.1 (November 3, 2014)

- Fixed: warning about custom prop used in non :root

### 1.0.0 (November 2, 2014)

- Added: warning when a custom prop is used in another place than :root
- Added: handle !important

### 0.4.0 (September 30, 2014)

- Added: JS-defined properties override CSS-defined

### 0.3.1 (August 27, 2014)

- Added: nested custom properties usages are now correctly resolved
- Changed: undefined var doesn't throw error anymore (just a console warning) & are kept as is in the output

### 0.3.0 (August 26, 2014)

- Changed: fallback now are always added by default ([see why](http://www.w3.org/TR/css-variables/#invalid-variables))
- Changed: `map` option renamed to `variables`

### 0.2.0 (August 22, 2014)

- Added: `map` option
- Changed: GNU style error message

### 0.1.0 (August 1, 2014)

✨ First release based on [rework-vars](https://github.com/reworkcss/rework-vars) v3.1.1
