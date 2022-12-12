# Changes to PostCSS Custom Selectors

### 5.1.2 (September 20, 2018)

- Fixed: Do not break on an empty `importFrom` object

### 5.1.1 (September 18, 2018)

- Fixed: Selectors like `.foo:--h1` become `h1.foo` instead of `.fooh1`

### 5.1.0 (September 12, 2018)

- Added: New `exportTo` function to specify where to export custom selectors
- Updated: `importFrom` option to support passing it a function

### 5.0.0 (September 7, 2018)

- Added: New `preserve` option to preserve custom selectors and rules using them
- Added: New `importFrom` option to specify where to import custom selectors
- Added: Support for PostCSS v7
- Added: Support for Node v6+

### 4.0.1 (May 15, 2017)

- Fixed: incorrect export

### 4.0.0 (May 12, 2017)

- Added: compatibility with postcss v6.x

### 3.0.0 (August 25, 2015)

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

### 2.3.0 (July 14, 2015)

* Fixed: Nested/mixed selectors now works correctly
([#19](https://github.com/postcss/postcss-custom-selectors/issues/19))
* Added: `transformMatches` option to limit transformation to :matches()
replacements.

### 2.2.0 (June 30, 2015)

* Fixed: No more useless warnings for undefined non custom selectors
([#22](https://github.com/postcss/postcss-custom-selectors/issues/22))
* Changed: warnings now use PostCSS message API

### 2.1.1 (June 30, 2015)

* Fixed: the lineBreak option keeping the selectors indent
([#18](https://github.com/postcss/postcss-custom-selectors/issues/18))
* Fixed: the tip of an undefined selector
([#20](https://github.com/postcss/postcss-custom-selectors/issues/20))

### 2.1.0 (June 4, 2015)

* Changed: use PostCSS 4.1 plugin API
([#13](https://github.com/postcss/postcss-custom-selectors/issues/13))

### 2.0.1 (June 3, 2015)

* Fixed: `(foo, bar)` conversion error exists in the selector
(See also [:matches() test](test/fixtures/matches/input.css))

### 2.0.0 (May 29, 2015)

* Removed: no longer support `::` or `--` to defined a custom selectors,
you must use the syntax `:--` to define it.
([#6](https://github.com/postcss/postcss-custom-selectors/issues/6))
* Fixed: two or more consecutive hyphens in selector don't output `undefined`
([#14](https://github.com/postcss/postcss-custom-selectors/issues/14))


### 1.1.1 (April 6, 2015)

* Fixed: add support for multilines definition

### 1.1.0 (December 6, 2014)

* Added: "lineBreak" option

### 1.0.0 (December 6, 2014)

* First release
