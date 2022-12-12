# Changes to PostCSS Dir Pseudo Class

### 5.0.0 (September 17, 2018)

- Updated: Support for PostCSS v7+
- Updated: Support for Node v6+
- Updated: `postcss-selector-parser` to v5.0.0-rc.3+ (major)

### 4.0.0 (May 8, 2018)

- Updated: `postcss-selector-parser` to v4.0.0 (major)
- Updated: `postcss` to v6.0.22 (patch)

### 3.0.0 (March 21, 2018)

- Added: `preserve` option to preserve the original `:dir()` rule
- Updated: `postcss-selector-parser` to v3 (major)
- Removed: `browsers` option which is better covered by
  [PostCSS Preset Env](https://github.com/jonathantneal/postcss-preset-env/)

### 2.1.0 (September 19, 2017)

- Fixed: Enforcement of presumed direction, e.g. `html:dir([dir="rtl"])`
- Updated: Browserslist and PostCSS
- Improved: How options are safely called, i.e. `Object(opts)`

### 2.0.0 (July 24, 2017)

- Changed: Method of presumed direction from `:root` to `html:not([dir])`

### 1.1.0 (June 2, 2017)

- Added: Support for browserslist and a 'browsers' option
- Added: Support for a presumed direction via the 'browsers' option

### 1.0.0 (May 30, 2017)

- Initial version
