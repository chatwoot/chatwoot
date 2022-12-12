# Changes to PostCSS Custom Media

### 7.0.8 (March 30, 2019)

- Fixed: Issue importing from `.pcss` files
- Updated: `postcss` to 7.0.14 (patch)

### 7.0.7 (October 19, 2018)

- Fixed: Issue combining custom media media queries with `and`

### 7.0.6 (October 12, 2018)

- Fixed: Issue combining multiple custom media

### 7.0.5 (October 5, 2018)

- Fixed: Possible issues resolving paths to imports and exports
- Added: Imports from `customMedia` and `custom-media` simultaneously
- Updated: `postcss` to 7.0.5

### 7.0.4 (September 23, 2018)

- Added: `importFromPlugins` option to process imports

### 7.0.3 (September 20, 2018)

- Fixed: Do not break on an empty `importFrom` object

### 7.0.2 (September 15, 2018)

- Fixed: An issue with re-assigning params as a non-string

### 7.0.1 (September 14, 2018)

- Fixed: An issue with how opposing queries are resolved.

### 7.0.0 (September 14, 2018)

- Added: New `preserve` option to preserve custom media and atrules using them
- Added: New `exportTo` function to specify where to export custom media
- Added: New `importFrom` option to specify where to import custom media
- Added: Support for PostCSS v7
- Added: Support for Node v6+

# 6.0.0 (May 12, 2017)

- Added: compatibility with postcss v6.x

# 5.0.1 (February 3, 2016)

- Fixed: circular dependencies are properly detected
([#17](https://github.com/postcss/postcss-custom-media/pull/17))

# 5.0.0 (August 25, 2015)

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

# 4.1.0 (06 30, 2015)

- Added: Allow custom media to reference each other
([#10](https://github.com/postcss/postcss-custom-media/pull/10))

# 4.0.0 (May 17, 2015)

- Changed: warning messages are now sent via postcss messages api (^4.1.0)
- Added: automatic custom media `--` prefixing
([#11](https://github.com/postcss/postcss-custom-media/issues/11))
- Added: `preserve` allows you to preserve custom media query defintions
- Added: `appendExtensions` allows you (when `preserve` is truthy) to append your extensions as media queries

# 3.0.0 (January 29, 2015)

- Added: compatibility with postcss v4.x
- Removed: compatibility with postcss v3.x

# 2.0.0 [Yanked]

_You never saw this version (this is a bad release that points to 1.0.0)._

# 1.3.0 (November 25, 2014)

- Changed: better gnu message

# 1.2.1 (October 9, 2014)

- Fixed: npm description

# 1.2.0 (October 1, 2014)

- Added: support for multiples media in query list (ref [#rework-custom-media/5](https://github.com/reworkcss/rework-custom-media/pull/5))

# 1.1.0 (September 30, 2014)

- Added: support for js-defined media queries (fix [#3](https://github.com/postcss/postcss-custom-media/issues/3))

# 1.0.1 (September 16, 2014)

- Added: Allow whitespace around custom media name (fix [#2](https://github.com/postcss/postcss-custom-media/issues/2))

# 1.0.0 (August 12, 2014)

✨ First release based on [rework-custom-media](https://github.com/reworkcss/rework-custom-media) v0.1.1
