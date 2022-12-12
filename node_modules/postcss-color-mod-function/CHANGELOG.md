# Changes to PostCSS color-mod() Function

### 3.0.3 (September 23, 2018)

- Fixed an issue with certain colors not being tranformed from variables

### 3.0.2 (September 23, 2018)

- Fixed an incompatibility with other `importFrom` plugins

### 3.0.1 (September 18, 2018)

- Fixed an issue with using the `transparent` color keyword
- Updated to PostCSS Values Parser 2

### 3.0.0 (August 30, 2018)

- Added `importFrom` option which allows you to import Custom Properties from
CSS, JS, and JSON files, and directly passed objects
- Fixed an issue where multiple variables could not be used in `color-mod()`
- Updated to support Node v6+

### 2.4.3 (July 21, 2018)

- Fixed issue with color-mod not being converted within function

### 2.4.2 (February 27, 2018)

- Fixed issue with converting colorspaces

### 2.4.1 (February 21, 2018)

- Fixed issue with spacing around `color-mod` (credit: [@leesdolphin])

### 2.4.0 (February 16, 2018)

- Added build-time support for Custom Properties and Variables
- Updated `@csstools/convert-colors` to 1.4 (minor update)
- Updated tests to reflect variable support

### 2.3.0 (January 25, 2018)

- Updated `@csstools/convert-colors` to 1.3 (minor update)
- Updated tests to reflect more accurate color conversions

### 2.2.0 (January 22, 2018)

- Added `@csstools/convert-colors` to convert between color spaces

### 2.1.0 (January 20, 2018)

- Added support for legacy (comma-separated) `hsl()` colors
- Added support for all `<hue>` units
- Added use of legacy (comma-separated) `hsl()` colors when appropriate
- Improved color conversions
- Improved support for all `rgb()` colors
- Removed external math and color dependencies

### 2.0.0 (January 17, 2018)

- Reverse blend/blenda percentage calculations (breaking change)
- Other improvements (see 4e4de6e)

### 1.1.0 (January 17, 2018)

- Round stringified color values

### 1.0.0 (January 16, 2018)

- Initial version

[@leesdolphin]: https://github.com/leesdolphin
