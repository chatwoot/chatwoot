# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] 2019-12-11
## Added
- Added jest snapshot utils (#297, @dogoku)

### Changed
- Moved from BSD to MIT license

### Fixed
- No longer throw an error when calling jscodeshift on a non-existent path (#334, @threepointone)
- Preserve the original file extension in remote files (#317, @samselikoff)

## [0.6.4] 2019-04-30
### Changed
- Allow writing tests in TypeScript ([PR #308](https://github.com/facebook/jscodeshift/pull/308))
- Better handling of `.gitingore` files: Ignore comments and support `\r\n` line breaks ([PR #306](https://github.com/facebook/jscodeshift/pull/306))


## [0.6.3] 2019-01-18
### Fixed
- Don't throw an error when jscodeshift processes an empty set of files (#295, 
@skovhus).
- `renameTo` should not rename class properties (#296, @henryqdineen).
- Custom/unknown CLI parameters are parsed as JSON, just like nomnom used to 
do.


## [0.6.2] 2018-12-05
### Changed
- `@babel/register`/`@babel/preset-env` is configured to not transpile any 
language features that the running Node process supports. That means if you use 
features in your transform code supported by the Node version you are running, 
they will be left as is. Most of ES2015 is actually supported since Node v6.
- Do not transpile object rest/spread in transform code if supported by running 
Node version.

### Fixed
- Presets and plugins passed to `@babel/register` are now properly named and 
  loaded.


## [0.6.1] 2018-12-04
### Added
- Tranform files can be written in Typescript. If the file extension of the 
transform file is `.ts` or `.tsx`, `@babel/preset-typescript` is used to 
convert them. This requires the `--babel` option to be set (which it is by 
default). ( #287 , @brieb )

### Changed
- The preset and plugins for converting the transform file itself via babeljs 
have been updated to work with babel v7. This included removing 
`babel-preset-es2015` and `babel-preset-stage-1` in favor of 
`@babel/preset-env`. Only `@babel/proposal-class-properties` and 
`@babel/proposal-object-rest-spread` are enabled as experimental features. If 
you want to use other's in your transform file, please create a PR.

### Fixed
- Typescript parses use `@babel/parser` instead of Babylon ( #291, @elliottsj )

### Bumped
- `micromatch` => v3.1.10, which doesn't (indirectly) depend on `randomatic` < 
v3 anymore (see #292).
