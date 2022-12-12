# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [4.2.0](https://github.com/webpack-contrib/postcss-loader/compare/v4.1.0...v4.2.0) (2021-01-21)


### Features

* added the `implementation` option ([#511](https://github.com/webpack-contrib/postcss-loader/issues/511)) ([deac978](https://github.com/webpack-contrib/postcss-loader/commit/deac9787eed614b1c445f091a2b70736a6212812))

## [4.1.0](https://github.com/webpack-contrib/postcss-loader/compare/v4.0.4...v4.1.0) (2020-11-19)


### Features

* partial compatibility with `postcss-cli`, added `api.env` (alias for `api.mode`) and `api.options` (contains options from the `postcssOptions` options), please look at the [example](https://github.com/webpack-contrib/postcss-loader#examples-of-config-files) for more details ([#498](https://github.com/webpack-contrib/postcss-loader/issues/498)) ([84a9c46](https://github.com/webpack-contrib/postcss-loader/commit/84a9c46467086df0185519ceb93bf66893af4cf2))

### [4.0.4](https://github.com/webpack-contrib/postcss-loader/compare/v4.0.3...v4.0.4) (2020-10-09)

### Chore

* update `schema-utils`

## [4.0.3](https://github.com/webpack-contrib/postcss-loader/compare/v4.0.2...v4.0.3) (2020-10-02)


### Bug Fixes

* PostCSS 8 plugin loading ([e1b82fe](https://github.com/webpack-contrib/postcss-loader/commit/e1b82feb9cc27f55953b9237708800cb8c07724e))
* error and warning messages ([#485](https://github.com/webpack-contrib/postcss-loader/issues/485)) ([4b44e01](https://github.com/webpack-contrib/postcss-loader/commit/4b44e01a323aa9d2c0965e92c1796158cb36ce5a))

### [4.0.2](https://github.com/webpack-contrib/postcss-loader/compare/v4.0.1...v4.0.2) (2020-09-15)


### Bug Fixes

* compatibility with `postcss@8` ([#479](https://github.com/webpack-contrib/postcss-loader/issues/479)) ([218b0f8](https://github.com/webpack-contrib/postcss-loader/commit/218b0f8013acfafdabea9f561d4c3d074bd2eff3))

### [4.0.1](https://github.com/webpack-contrib/postcss-loader/compare/v4.0.0...v4.0.1) (2020-09-08)


### Bug Fixes

* source map generation with the `map` option for `postcss` ([#476](https://github.com/webpack-contrib/postcss-loader/issues/476)) ([6babeb1](https://github.com/webpack-contrib/postcss-loader/commit/6babeb1d64ca1e7d3d3651cb07881e1e291fa994))

## [4.0.0](https://github.com/webpack-contrib/postcss-loader/compare/v3.0.0...v4.0.0) (2020-09-07)


### ⚠ BREAKING CHANGES

* minimum supported `Node.js` version is `10.13`
* minimum supported `webpack` version is `4`
* `postcss` was moved to `peerDependencies`, you need to install `postcss`
* `PostCSS` (`plugins`/`syntax`/`parser`/`stringifier`) options was moved to the `postcssOptions` option, please look at [docs](https://github.com/webpack-contrib/postcss-loader#postcssoptions)
* `sourceMap` default value depends on the `compiler.devtool` option
* the `inline` value was removed for the `sourceMap` option, please use `{ map: { inline: true, annotation: false } }` to achieve this
* source maps contain absolute paths in `sources`
* loader output only CSS, so you need to use `css-loader`/`file-loader`/`raw-loader` to inject code inside bundle
* `exec` option was renamed to the `execute` option
* the `config` option doesn't support `Object` type anymore, `config.path` and `config.ctx` options were removed
* argument in the config for `Function` notation (previously `config.ctx`) was changed, now it contains `{ file, mode, webpackLoaderContext }`
* loader context in the config was renamed from `webpack` to `webpackLoaderContext`

### Features

* message API for emit assets ([#443](https://github.com/webpack-contrib/postcss-loader/issues/443)) ([e966ab9](https://github.com/webpack-contrib/postcss-loader/commit/e966ab965132ca812cb50e5eaf7df5fc2ad9c137))
* reuse AST from other loaders ([#468](https://github.com/webpack-contrib/postcss-loader/issues/468)) ([9b75888](https://github.com/webpack-contrib/postcss-loader/commit/9b75888dff4957f2ef1e94eca871e329354a9f6d))
* allows to use config and loader options together, options from the loader takes precedence over the config, the `plugins` option from the config and options are merged ([0eb5aaf](https://github.com/webpack-contrib/postcss-loader/commit/0eb5aaf3d49f6d5e570a3c3fdb6b201487e503c7))
* `postcssOptions` options can be `Function`

### Bug Fixes

* compatibility with webpack@5 ([#437](https://github.com/webpack-contrib/postcss-loader/issues/437)) ([ed50491](https://github.com/webpack-contrib/postcss-loader/commit/ed504910b70b4d8b4d77084c19ad92330676433e))
* `default` export for plugins ([#465](https://github.com/webpack-contrib/postcss-loader/issues/465)) ([3d32c35](https://github.com/webpack-contrib/postcss-loader/commit/3d32c35c5c911d6bd25dc0c4b5b3cd11408632d7))
* avoid mutations of loader options and config ([#470](https://github.com/webpack-contrib/postcss-loader/issues/470)) ([cad6f07](https://github.com/webpack-contrib/postcss-loader/commit/cad6f07c7f4923e8ef69ecb402b10bbd08d09530))
* respect the `map` option from loader options and config ([#458](https://github.com/webpack-contrib/postcss-loader/issues/458)) ([98441ff](https://github.com/webpack-contrib/postcss-loader/commit/98441ff87e51b58e9322d1bebb5eefc5ba417e24))

### Notes

* you don't need `ident` option for loader
* `Object` syntax for the `plugin` option is soft deprecated, please migrate on `Array` syntax (`plugins: ['postcss-preset-env', ['cssnano', options]]`)

<a name="3.0.0"></a>
# [3.0.0](https://github.com/postcss/postcss-loader/compare/v2.1.6...v3.0.0) (2018-08-08)


### Bug Fixes

* **index:** add ast version (`meta.ast`) ([f34954f](https://github.com/postcss/postcss-loader/commit/f34954f))
* **index:** emit `warnings` as an instance of `{Error}` ([8ac6fb5](https://github.com/postcss/postcss-loader/commit/8ac6fb5))
* **options:** improved `ValidationError` messages ([549ea08](https://github.com/postcss/postcss-loader/commit/549ea08))


### Chores

* **package:** update `postcss` v6.0.0...7.0.0 (`dependencies`) ([#375](https://github.com/postcss/postcss-loader/issues/375)) ([daa0da8](https://github.com/postcss/postcss-loader/commit/daa0da8))


### BREAKING CHANGES

* **package:** requires `node >= v6.0.0`



<a name="2.1.6"></a>
## [2.1.6](https://github.com/postcss/postcss-loader/compare/v2.1.5...v2.1.6) (2018-07-10)


### Bug Fixes

* **package:** config memory leak, updates `postcss-load-config` v1.2.0...2.0.0 (`dependencies`) ([0547b12](https://github.com/postcss/postcss-loader/commit/0547b12))



<a name="2.1.5"></a>
## [2.1.5](https://github.com/postcss/postcss-loader/compare/v2.1.4...v2.1.5) (2018-05-04)


### Bug Fixes

* **index:** remove `sourceMap` warning ([#361](https://github.com/postcss/postcss-loader/issues/361)) ([4416791](https://github.com/postcss/postcss-loader/commit/4416791))



<a name="2.1.4"></a>
## [2.1.4](https://github.com/postcss/postcss-loader/compare/v2.1.3...v2.1.4) (2018-04-16)


### Bug Fixes

* restore loader object in postcss config context ([#355](https://github.com/postcss/postcss-loader/issues/355)) ([2ff1735](https://github.com/postcss/postcss-loader/commit/2ff1735))



<a name="2.1.3"></a>
## [2.1.3](https://github.com/postcss/postcss-loader/compare/v2.1.2...v2.1.3) (2018-03-20)


### Bug Fixes

* **options:** revert additionalProperties changes to keep SemVer ([bd7fc38](https://github.com/postcss/postcss-loader/commit/bd7fc38))



<a name="2.1.2"></a>
## [2.1.2](https://github.com/postcss/postcss-loader/compare/v2.1.1...v2.1.2) (2018-03-17)


### Bug Fixes

* **options:** disallow additional properties and add `ident` to validation ([#346](https://github.com/postcss/postcss-loader/issues/346)) ([82ef553](https://github.com/postcss/postcss-loader/commit/82ef553))



<a name="2.1.1"></a>
## [2.1.1](https://github.com/postcss/postcss-loader/compare/v2.1.0...v2.1.1) (2018-02-26)


### Bug Fixes

* **index:** don't set `to` value (`options`) ([#339](https://github.com/postcss/postcss-loader/issues/339)) ([cdbb8b6](https://github.com/postcss/postcss-loader/commit/cdbb8b6))



<a name="2.1.0"></a>
# [2.1.0](https://github.com/postcss/postcss-loader/compare/v2.0.10...v2.1.0) (2018-02-02)


### Bug Fixes

* **index:** continue watching after dependency `{Error}` ([#332](https://github.com/postcss/postcss-loader/issues/332)) ([a8921cc](https://github.com/postcss/postcss-loader/commit/a8921cc))


### Features

* **index:** pass AST (`result.root`) && Messages (`result.messages`) as metadata to other loaders ([#322](https://github.com/postcss/postcss-loader/issues/322)) ([56232e7](https://github.com/postcss/postcss-loader/commit/56232e7))



<a name="2.0.10"></a>
## [2.0.10](https://github.com/postcss/postcss-loader/compare/v2.0.9...v2.0.10) (2018-01-03)


### Bug Fixes

* **index:** copy loader `options` before modifying ([#326](https://github.com/postcss/postcss-loader/issues/326)) ([61ff03c](https://github.com/postcss/postcss-loader/commit/61ff03c))



<a name="2.0.9"></a>
## [2.0.9](https://github.com/postcss/postcss-loader/compare/v2.0.8...v2.0.9) (2017-11-24)


### Bug Fixes

* **index:** filter `ident` (`options.ident`) ([#315](https://github.com/postcss/postcss-loader/issues/315)) ([3e1c7fa](https://github.com/postcss/postcss-loader/commit/3e1c7fa))



<a name="2.0.8"></a>
## [2.0.8](https://github.com/postcss/postcss-loader/compare/v2.0.6...v2.0.8) (2017-10-14)


### Bug Fixes

* **lib/options:** handle `{Object}` return (`options.plugins`) ([#301](https://github.com/postcss/postcss-loader/issues/301)) ([df010a7](https://github.com/postcss/postcss-loader/commit/df010a7))
* **schema:** allow to pass an `{Object}` (`options.syntax/options.stringifier`) ([#300](https://github.com/postcss/postcss-loader/issues/300)) ([58e9996](https://github.com/postcss/postcss-loader/commit/58e9996))



<a name="2.0.7"></a>
## [2.0.7](https://github.com/postcss/postcss-loader/compare/v2.0.6...v2.0.7) (2017-10-10)


### Bug Fixes

* sanitizing `from` and `to` options (`postcss.config.js`) ([#260](https://github.com/postcss/postcss-loader/issues/260)) ([753dea7](https://github.com/postcss/postcss-loader/commit/753dea7))
* **index:** runaway promise ([#269](https://github.com/postcss/postcss-loader/issues/269)) ([8df20ce](https://github.com/postcss/postcss-loader/commit/8df20ce))



<a name="2.0.6"></a>
## [2.0.6](https://github.com/postcss/postcss-loader/compare/v2.0.5...v2.0.6) (2017-06-14)


### Bug Fixes

* allow to pass an `{Object}` (`options.parser`) ([#257](https://github.com/postcss/postcss-loader/issues/257)) ([4974607](https://github.com/postcss/postcss-loader/commit/4974607))
* misspelling in warnings ([#237](https://github.com/postcss/postcss-loader/issues/237)) ([adcbb2e](https://github.com/postcss/postcss-loader/commit/adcbb2e))
* **index:** simplify config loading behaviour ([#259](https://github.com/postcss/postcss-loader/issues/259)) ([b313478](https://github.com/postcss/postcss-loader/commit/b313478))



<a name="2.0.5"></a>
## [2.0.5](https://github.com/postcss/postcss-loader/compare/v2.0.4...v2.0.5) (2017-05-10)


### Bug Fixes

* regression with `options.plugins` `{Function}` (`webpack.config.js`) (#229) ([dca52a9](https://github.com/postcss/postcss-loader/commit/dca52a9))



<a name="2.0.4"></a>
## [2.0.4](https://github.com/postcss/postcss-loader/compare/v2.0.3...v2.0.4) (2017-05-10)


### Bug Fixes

* **index:** `postcss.config.js` not resolved correctly (`options.config`) ([faaeee4](https://github.com/postcss/postcss-loader/commit/faaeee4))
* **index:** update validation schema, better warning message ([4f20c99](https://github.com/postcss/postcss-loader/commit/4f20c99))



<a name="2.0.3"></a>
## [2.0.3](https://github.com/postcss/postcss-loader/compare/v2.0.2...v2.0.3) (2017-05-09)


### Bug Fixes

* **index:** don't fail on 'sourceMap: false' && emit a warning instead, when previous map found (`options.sourceMap`) ([159b66a](https://github.com/postcss/postcss-loader/commit/159b66a))



<a name="2.0.2"></a>
## [2.0.2](https://github.com/postcss/postcss-loader/compare/v2.0.1...v2.0.2) (2017-05-09)


### Bug Fixes

* **index:** 'No PostCSS Config found' (`options.config`) (#215) ([e764761](https://github.com/postcss/postcss-loader/commit/e764761))



<a name="2.0.1"></a>
## [2.0.1](https://github.com/postcss/postcss-loader/compare/v2.0.0...v2.0.1) (2017-05-08)


### Bug Fixes

* **index:** 'Cannot create property `prev` on boolean `false`' (`options.sourceMap`) ([c4f0064](https://github.com/postcss/postcss-loader/commit/c4f0064))



<a name="2.0.0"></a>
# [2.0.0](https://github.com/postcss/postcss-loader/compare/1.2.2...v2.0.0) (2017-05-08)


### Features

* **index:** add ctx, ctx.file, ctx.options ([0dceb2c](https://github.com/postcss/postcss-loader/commit/0dceb2c))
* **index:** add options validation ([2b76df8](https://github.com/postcss/postcss-loader/commit/2b76df8))



## 1.3.3
* Remove `postcss-loader-before-processing` warning (by Michael Ciniawsky).

## 1.3.2
* Fix deprecated warning (by Xiaoyu Zhai).

## 1.3.1
* Fix conflict with CLI `--config` argument (by EGOIST).

## 1.3
* Allow object in syntax options, not only path for require (by Jeff Escalante).

## 1.2.2
* Watch `postcss.config.js` for changes (by Michael Ciniawsky).

## 1.2.1
* Fix relative `config` parameter resolving (by Simen Bekkhus).

## 1.2
* Add `config` parameter (by sainthkh).

## 1.1.1
* Fix `this` in options function (by Jeff Escalante).

## 1.1
* PostCSS common config could be placed to subdirs.
* Add webpack instance to PostCSS common config context.

## 1.0
* Add common PostCSS config support (by Mateusz Derks).
* Add Webpack 2 support with `plugins` query option (by Izaak Schroeder).
* Add `dependency` message support.
* Rewrite docs (by Michael Ciniawsky).

## 0.13
* Add `exec` parameter (by Neal Granger).

## 0.12
* Add CSS syntax highlight to syntax error code frame.

## 0.11.1
* Fix Promise API (by Daniel Haus).

## 0.11
* Add `postcss-loader-before-processing` webpack event (by Jan Nicklas).

## 0.10.1
* Better syntax error message (by Andrey Popp).

## 0.10.0
* Add `sourceMap` parameter to force inline maps (by 雪狼).

## 0.9.1
* Fix plugin in simple array config.

## 0.9
* Allow to pass syntax, parser or stringifier as function (by Jeff Escalante).

## 0.8.2
* Fix source map support (by Andrew Bradley).

## 0.8.1
* Fix resource path.

## 0.8
* Add postcss-js support (by Simon Degraeve).

## 0.7
* Added argument with webpack instance to plugins callback (by Maxime Thirouin).

## 0.6
* Use PostCSS 5.0.
* Remove `safe` parameter. Use Safe Parser.
* Add `syntax`, `parser` and `stringifier` parameters.

## 0.5.1
* Fix string source map support (by Jan Nicklas).

## 0.5.0
* Set plugins by function for hot reload support (by Stefano Brilli).

## 0.4.4
* Fix error on empty PostCSS config.

## 0.4.3
* Better check for `CssSyntaxError`.

## 0.4.2
* Fixed invalid sourcemap exception (by Richard Willis).

## 0.4.1
* Use only Promise API to catch PostCSS errors.

## 0.4
* Add PostCSS asynchronous API support.
* Fix source map support (by Richard Willis).
* Add warnings API support.
* Better output for CSS syntax errors.

## 0.3
* Use PostCSS 4.0.

## 0.2
* Use PostCSS 3.0.

## 0.1
* Initial release.
