# Change Log

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [4.5.2](https://github.com/jantimon/html-webpack-plugin/compare/v4.5.1...v4.5.2) (2021-02-18)


### Bug Fixes

* more robust variable value extraction to add support for webpack >= 5.22.0 ([1aabaf9](https://github.com/jantimon/html-webpack-plugin/commit/1aabaf99820257cbe7d3efccb62b42254ad35e04))



## [4.5.1](https://github.com/jantimon/html-webpack-plugin/compare/v4.5.0...v4.5.1) (2021-01-03)


### Bug Fixes

* inject javascripts in the <head> tag for inject:true and scriptLoading:'defer' ([4f7064e](https://github.com/jantimon/html-webpack-plugin/commit/4f7064ee56fe710e8f416018956647a72c270fb1))

# [4.5.0](https://github.com/jantimon/html-webpack-plugin/compare/v4.4.1...v4.5.0) (2020-09-21)


### Features

* Add publicPath option to overrule the default path generation ([#1516](https://github.com/jantimon/html-webpack-plugin/issues/1516)) ([19b5122](https://github.com/jantimon/html-webpack-plugin/commit/19b5122))
* update webpack dependency range to allow installing webpack 5 beta  ([f3ccdd5](https://github.com/jantimon/html-webpack-plugin/commit/f3ccdd5)), closes [#1504](https://github.com/jantimon/html-webpack-plugin/issues/1504)



## [4.4.1](https://github.com/jantimon/html-webpack-plugin/compare/v4.4.0...v4.4.1) (2020-08-30)


### Bug Fixes

* broken typings.d.ts in v4.4.0 ([#1503](https://github.com/jantimon/html-webpack-plugin/issues/1503)) ([98ad756](https://github.com/jantimon/html-webpack-plugin/commit/98ad756))



# [4.4.0](https://github.com/jantimon/html-webpack-plugin/compare/v4.3.0...v4.4.0) (2020-08-30)


### Bug Fixes

* fix typos in comments ([#1484](https://github.com/jantimon/html-webpack-plugin/issues/1484)) ([6b0711e](https://github.com/jantimon/html-webpack-plugin/commit/6b0711e))


### Features

* added v5 compilation support and deleted depreciation warnings ([4ae7be8](https://github.com/jantimon/html-webpack-plugin/commit/4ae7be8)), closes [#1454](https://github.com/jantimon/html-webpack-plugin/issues/1454)



# [4.3.0](https://github.com/jantimon/html-webpack-plugin/compare/v4.2.2...v4.3.0) (2020-04-30)


### Features

* Allow to use console.log inside templates ([c3f2fdc](https://github.com/jantimon/html-webpack-plugin/commit/c3f2fdc))



## [4.2.2](https://github.com/jantimon/html-webpack-plugin/compare/v4.2.1...v4.2.2) (2020-04-30)


### Bug Fixes

* Prevent "cannot read property info of undefined" when reading meta information from assets ([253ce30](https://github.com/jantimon/html-webpack-plugin/commit/253ce30))
* use modern icon tag rel attribute for favicons ([c40dd85](https://github.com/jantimon/html-webpack-plugin/commit/c40dd85))



## [4.2.1](https://github.com/jantimon/html-webpack-plugin/compare/v4.2.0...v4.2.1) (2020-04-28)


### Bug Fixes

* don't add dependencies twice to the webpack 5 watcher api ([ceafe14](https://github.com/jantimon/html-webpack-plugin/commit/ceafe143650749a5f53a14411dc1b762e252ec44))
* prevent scripts marked as hotModuleReplacement from being added to the html file ([119252a](https://github.com/jantimon/html-webpack-plugin/commit/119252a381bf43dea37c1be64f90c10bebc21302))



# [4.2.0](https://github.com/jantimon/html-webpack-plugin/compare/v4.1.0...v4.2.0) (2020-04-09)


### Features

* Add template content ([#1401](https://github.com/jantimon/html-webpack-plugin/issues/1401)) ([4740bf7](https://github.com/jantimon/html-webpack-plugin/commit/4740bf7))



# [4.1.0](https://github.com/jantimon/html-webpack-plugin/compare/v4.0.4...v4.1.0) (2020-04-09)


### Features

* Add webpack 5 support ([39c38a4](https://github.com/jantimon/html-webpack-plugin/commit/39c38a4))
* Allow webpack 5 as peer dependency ([9c571e2](https://github.com/jantimon/html-webpack-plugin/commit/9c571e2))



## [4.0.4](https://github.com/jantimon/html-webpack-plugin/compare/v4.0.3...v4.0.4) (2020-04-01)


### Bug Fixes

* Fix querystring encoding ([#1386](https://github.com/jantimon/html-webpack-plugin/issues/1386)) ([4f48a39](https://github.com/jantimon/html-webpack-plugin/commit/4f48a39e5738a5d431be2bec39c1b1f0de800d57)), closes [#1355](https://github.com/jantimon/html-webpack-plugin/issues/1355)



## [4.0.3](https://github.com/jantimon/html-webpack-plugin/compare/v4.0.2...v4.0.3) (2020-03-28)


### Bug Fixes

* add webpack, tapable and html-minifier-terser as dependencies because of types.d.ts ([238da81](https://github.com/jantimon/html-webpack-plugin/commit/238da8123950f87267954fd448f3e6b0fb1ead17))



## [4.0.2](https://github.com/jantimon/html-webpack-plugin/compare/v4.0.1...v4.0.2) (2020-03-26)


### Bug Fixes

* don't remove trailing slashes from self closing tags by default ([2281e4b](https://github.com/jantimon/html-webpack-plugin/commit/2281e4bfda9b91c4a83d63bfc8df8372d1e6ae9e))



## [4.0.1](https://github.com/jantimon/html-webpack-plugin/compare/v4.0.0...v4.0.1) (2020-03-23)


### Bug Fixes

* update typedefs to match with html-minifier-terser ([2698c7e](https://github.com/jantimon/html-webpack-plugin/commit/2698c7e45a7f12113a07b256dc400ec89666130d))



# [4.0.0](https://github.com/jantimon/html-webpack-plugin/compare/v3.2.0...v4.0.0) (2020-03-23)

The summary can be found in the [**release blog post**](https://dev.to/jantimon/html-webpack-plugin-4-has-been-released-125d).

### Bug Fixes

* Add dependencies from the child compilation to the main compilation ([27c3e72](https://github.com/jantimon/html-webpack-plugin/commit/27c3e727b073701bfc739859d8325435d27cbf35))
* Add typing for assets(Close jantimon[#1243](https://github.com/jantimon/html-webpack-plugin/issues/1243)) ([9fef060](https://github.com/jantimon/html-webpack-plugin/commit/9fef0603eb532b3e6a1e8871b4568e62f9bba1a3))
* allow `contenthash` along with `templatehash` ([049d4d3](https://github.com/jantimon/html-webpack-plugin/commit/049d4d3436092b8beff3f5745e77b20f1c168c4c)), closes [#1033](https://github.com/jantimon/html-webpack-plugin/issues/1033)
* Catch and ignore pretty-error errors ([2056139](https://github.com/jantimon/html-webpack-plugin/commit/2056139a9533ff9487506531491c0e5a94003607)), closes [#921](https://github.com/jantimon/html-webpack-plugin/issues/921)
* Drop @types/webpack dependency ([d4eb1c7](https://github.com/jantimon/html-webpack-plugin/commit/d4eb1c749316af3964126606fe6c70a233c30fef))
* Ignore foreign child compilers ([1422664](https://github.com/jantimon/html-webpack-plugin/commit/14226649aa1bbaf7b174bcacafdbe47d8ba6c851))
* Improve perfomance for appcache files ([b94e043](https://github.com/jantimon/html-webpack-plugin/commit/b94e0434f5dbb06ee2179e91ebaa2ce7801937e0))
* load script files before style files files in defer script loading mode ([97f9fb9](https://github.com/jantimon/html-webpack-plugin/commit/97f9fb9a68e4d3c3c9453296c352e831f7546937))
* Prevent chunks from beeing added multiple times ([d65b37d](https://github.com/jantimon/html-webpack-plugin/commit/d65b37d2c588047e0d81a38f4645fcdb3ead0b9e))
* Prevent lodash from being inlined to work around a babel-loader incompatibility ([7f21910](https://github.com/jantimon/html-webpack-plugin/commit/7f21910707a2b53a9a5da3ac9e4b01e36147402f)), closes [#1223](https://github.com/jantimon/html-webpack-plugin/issues/1223)
* Remove compilation.getStats() call for performance reasons ([7005a55](https://github.com/jantimon/html-webpack-plugin/commit/7005a557529bee948c5ef0a1b8b44a1a41a28417))
* remove useless links for options ([#1153](https://github.com/jantimon/html-webpack-plugin/issues/1153)) ([267e0e0](https://github.com/jantimon/html-webpack-plugin/commit/267e0e0eac155569c822c34f120490bdf3f56d43))
* Update references to html-minifier ([24bf1b5](https://github.com/jantimon/html-webpack-plugin/commit/24bf1b5e2a0d087b30d057d1780d8f495aa01e26)), closes [#1311](https://github.com/jantimon/html-webpack-plugin/issues/1311)
* **typings.d.ts:** added apply method type to HtmlWwbpackPlugin class definitoin ([8b7255f](https://github.com/jantimon/html-webpack-plugin/commit/8b7255f555423dd1bfa51a3c28700e4bd116f97b)), closes [jantimon#1244](https://github.com/jantimon/issues/1244)
* rename `contenthash` to `templatehash` ([4c11c5d](https://github.com/jantimon/html-webpack-plugin/commit/4c11c5dfde9d87d71dce9cf51864648f8e42b912))
* Repair typings ([#1166](https://github.com/jantimon/html-webpack-plugin/issues/1166)) ([f4cb241](https://github.com/jantimon/html-webpack-plugin/commit/f4cb241157a9a1fed4721b1abc1f390b09595494))
* small type. minifcation instead of minification ([#1154](https://github.com/jantimon/html-webpack-plugin/issues/1154)) ([56037a6](https://github.com/jantimon/html-webpack-plugin/commit/56037a6b2ae4a7606b54f5af213b6a2b8145f95e))
* Use src/index.ejs by default if present ([#1167](https://github.com/jantimon/html-webpack-plugin/issues/1167)) ([c27e5e4](https://github.com/jantimon/html-webpack-plugin/commit/c27e5e46a334d9c1e177a521ea7c9a5ba3c6d980))
* **chunksorter:** Don't sort chunks by default ([22fb03f](https://github.com/jantimon/html-webpack-plugin/commit/22fb03fb17fdb37d5ce6de00af154b5575a02d3a))
* **loader:** switch to loaderUtils.getOptions ([a0a0f0d](https://github.com/jantimon/html-webpack-plugin/commit/a0a0f0dc755fbc3249aa2e1d1c6a4dd307ab8e8a))
* **README:** adds a link to template option documentation ([f40aeae](https://github.com/jantimon/html-webpack-plugin/commit/f40aeae312af73c6c5263cd99e81069f41d3b699))
* **tests:** Upgrade webpack-recompilation-simulator ([dfe1d10](https://github.com/jantimon/html-webpack-plugin/commit/dfe1d10c4511b0da4354cacf79ca0d5ac7baf862))
* Update lodash to 4.17.10 ([cc3bf49](https://github.com/jantimon/html-webpack-plugin/commit/cc3bf4909605879993c22e3048ee520dbdc8fa49))


### Code Refactoring

* Change the structure of the internal assets object ([37db086](https://github.com/jantimon/html-webpack-plugin/commit/37db0868efdbf334a1b60003fe5bd376cfd8ae01))
* Changed hook names and arguments - the hook order is 'beforeAssetTagGeneration', 'alterAssetTags', 'alterAssetTagGroups', 'afterTemplateExecution', 'beforeEmit', 'afterEmit' ([14b4456](https://github.com/jantimon/html-webpack-plugin/commit/14b4456ba67a5b85421b558bbd5f1d59c7b410b3))
* Use Webpack 4 APIs ([47efdea](https://github.com/jantimon/html-webpack-plugin/commit/47efdeaf17806f7d4e26aefacc748a92077f904a))


### Features

* add `.toString` implementation to htmlTags to allow easier rendering ([34d8aa5](https://github.com/jantimon/html-webpack-plugin/commit/34d8aa572c7acc59c26f3b5d15bf489a07aa4c24))
* Add default viewport meta tag for default template ([302e39e](https://github.com/jantimon/html-webpack-plugin/commit/302e39e30013b5828bb6c9e7036db951f70d0cf5)), closes [#897](https://github.com/jantimon/html-webpack-plugin/issues/897) [#978](https://github.com/jantimon/html-webpack-plugin/issues/978)
* Add defer script loading ([de315eb](https://github.com/jantimon/html-webpack-plugin/commit/de315eb98497f3e5f517d59dbbe120b48c9b8db9))
* Add support for relative publicPath   ([dbbdd81](https://github.com/jantimon/html-webpack-plugin/commit/dbbdd81de570dd181ea0905a6445fdeb5a784912))
* Add support for <base> tag ([#1160](https://github.com/jantimon/html-webpack-plugin/issues/1160)) ([c5d4b86](https://github.com/jantimon/html-webpack-plugin/commit/c5d4b869c196c59cdd6a9c30db58f1f8be07a820))
* Add support for minifying inline ES6 inside html templates ([c66766c](https://github.com/jantimon/html-webpack-plugin/commit/c66766cdae3593091dee413b9c585359c24ef068)), closes [#1262](https://github.com/jantimon/html-webpack-plugin/issues/1262)
* Add support for the [contenthash] placeholder inside htm file names ([ae8233a](https://github.com/jantimon/html-webpack-plugin/commit/ae8233a04d4105b6e970feaa2c5e11c0b48fd4b7))
* Add typings to package.json ([a524e8f](https://github.com/jantimon/html-webpack-plugin/commit/a524e8f24e905d5e51fedd50d33a41328a9b87eb)), closes [#1132](https://github.com/jantimon/html-webpack-plugin/issues/1132)
* Allow to return async template parameters ([99f9362](https://github.com/jantimon/html-webpack-plugin/commit/99f9362703055baf0029b8852cb5339b6218829d))
* drop workaround for "Uncaught TypeError: __webpack_require__(...) is not a function" to be compatible with webpack 5 ([15ad0d2](https://github.com/jantimon/html-webpack-plugin/commit/15ad0d260443edfdcc953fa08c675c90c063bac7))
* Export major version of this plugin ([6ae6f48](https://github.com/jantimon/html-webpack-plugin/commit/6ae6f48ecf92b080809d68092ee8c6825edfe5a4))
* merge templateParameters with default template parameters ([1d66e53](https://github.com/jantimon/html-webpack-plugin/commit/1d66e5333bc2aeb8caadf96e572af756d3708d19))
* Provide a verbose error message if html minification failed ([7df269f](https://github.com/jantimon/html-webpack-plugin/commit/7df269fd2a840d0800cb259bd559edb0b766e7ab))
* **compiler:** Add file dependencies ([bbc07a3](https://github.com/jantimon/html-webpack-plugin/commit/bbc07a3a214e3b693e6c9e3d6404e146a0fc023a))
* **compiler:** Use a single compiler for multiple plugin instances ([f29ae88](https://github.com/jantimon/html-webpack-plugin/commit/f29ae886d7fad50e7fbb78ac7ff7d5bd9bc47f49))
* **compiler:** Use timestamps to verify cache validity ([0ebcd17](https://github.com/jantimon/html-webpack-plugin/commit/0ebcd1776132262b799f2814659f4d90c3f3c1b3))
* Remove selfClosingTag ([5d3d8e4](https://github.com/jantimon/html-webpack-plugin/commit/5d3d8e4b73b7b97dba8bdf5fe1ecf50598040b54))
* Remove type="text/javascript" from injected script tags ([b46bf67](https://github.com/jantimon/html-webpack-plugin/commit/b46bf67ae4492a12b60c42c7d26831e480522b49))
* Replace jade with pug in examples ([d7ec407](https://github.com/jantimon/html-webpack-plugin/commit/d7ec4078c85b3ed9c2ff84e10fe75392f26a6130))
* Switch from jasmine to jest ([ae1f435](https://github.com/jantimon/html-webpack-plugin/commit/ae1f43527945c8ae953c2ba549631f2d090e003a))
* **hooks:** Add a helper for easier hook access ([b6dec4b](https://github.com/jantimon/html-webpack-plugin/commit/b6dec4bf1072509282756e8d83ef6ee447485f3a))
* **hooks:** Provide static getHook method for access to all html-webpack-plugin hooks ([#995](https://github.com/jantimon/html-webpack-plugin/issues/995)) ([82b34a1](https://github.com/jantimon/html-webpack-plugin/commit/82b34a1dd2e96cbcd715fafe4e97073efd30cc9f))
* Simplify <meta> element and charset attribute ([55313be](https://github.com/jantimon/html-webpack-plugin/commit/55313bee9b82ea79157085e48bba4fa2ebfef6a4))
* support ES6 template string in default loader ([d6b65dd](https://github.com/jantimon/html-webpack-plugin/commit/d6b65dd1531038deac1be87c2087da5955903d24)), closes [#950](https://github.com/jantimon/html-webpack-plugin/issues/950)
* Use jsdoc for static typing ([a6b8d2d](https://github.com/jantimon/html-webpack-plugin/commit/a6b8d2dcf3b1183d50589b869162b972ad32de4d))
* Use webpack 4 entries api to extract asset information ([342867e](https://github.com/jantimon/html-webpack-plugin/commit/342867e1edb7c2a8748b0aca396f160f0b13d42e))
* **html-tags:** Add a helper to create html-tags ([ee6a165](https://github.com/jantimon/html-webpack-plugin/commit/ee6a165425a6b47dff341fb651848ec5727d7f7e))


### BREAKING CHANGES

* **defaults:** Use src/index.ejs if no template option is set.
* **defaults:** The default template has now a predefined viewport meta tag
* **defaults:** The default meta utf-8 declaration was changed to <meta charset="utf-8"/>
* **hooks:** Renamed beforeHtmlGeneration hook to beforeAssetTagGeneration
* **hooks:** Renamed beforeHtmlProcessing hook to alterAssetTags
* **hooks:** Renamed afterHtmlProcessing hook to beforeEmit
* **hooks:** The html-webpack-plugin doesn't add its hooks to the compilation object anymore
* The assets object which is used for the template parameters and inside hooks was changed. The chunks property was removed and the js and css property was converted from a string into an object `{ entryName: string, path: string}`
* The mimetype information "text/javascript" is removed from all generated script
tags
* Remove selfClosingTag attribute
* Template strings inside templates are now disabled by default
* Dropped support for Webpack 1 - 3
* Template variable webpack was removed
* **chunksorter:** Chunks aren't sorted anymore by default


<a name="3.2.0"></a>
# [3.2.0](https://github.com/jantimon/html-webpack-plugin/compare/v3.1.0...v3.2.0) (2018-04-03)


### Bug Fixes

* **loader:** Allow to add new template parameters ([f7eac19](https://github.com/jantimon/html-webpack-plugin/commit/f7eac19)), closes [#915](https://github.com/jantimon/html-webpack-plugin/issues/915)
* **loader:** Use lodash inside the loader directly ([7b4eb7f](https://github.com/jantimon/html-webpack-plugin/commit/7b4eb7f)), closes [#786](https://github.com/jantimon/html-webpack-plugin/issues/786)


### Features

* Add meta tag option ([a7d37ca](https://github.com/jantimon/html-webpack-plugin/commit/a7d37ca))
* Support node 6.9 ([74a22c4](https://github.com/jantimon/html-webpack-plugin/commit/74a22c4)), closes [#918](https://github.com/jantimon/html-webpack-plugin/issues/918)



<a name="3.1.0"></a>
# [3.1.0](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.8...v3.1.0) (2018-03-22)


### Features

* Allow to overwrite the templateParameter [#830](https://github.com/jantimon/html-webpack-plugin/issues/830) ([c5e32d3](https://github.com/jantimon/html-webpack-plugin/commit/c5e32d3))



<a name="3.0.8"></a>
## [3.0.8](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.7...v3.0.8) (2018-03-22)


### Bug Fixes

* **compiler:** Fallback to 3.0.7 because of [#900](https://github.com/jantimon/html-webpack-plugin/issues/900) ([05ee29b](https://github.com/jantimon/html-webpack-plugin/commit/05ee29b))



<a name="3.0.7"></a>
## [3.0.7](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.6...v3.0.7) (2018-03-19)


### Bug Fixes

* **compiler:** Set single entry name [#895](https://github.com/jantimon/html-webpack-plugin/issues/895) ([26dcb98](https://github.com/jantimon/html-webpack-plugin/commit/26dcb98))



<a name="3.0.6"></a>
## [3.0.6](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.5...v3.0.6) (2018-03-06)


### Bug Fixes

* **hooks:** Call tapable.apply directly [#879](https://github.com/jantimon/html-webpack-plugin/issues/879) ([bcbb036](https://github.com/jantimon/html-webpack-plugin/commit/bcbb036))



<a name="3.0.5"></a>
## [3.0.5](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.2...v3.0.5) (2018-03-06)


### Bug Fixes

* **entries:** do not ignore JS if there is also CSS ([020b714](https://github.com/jantimon/html-webpack-plugin/commit/020b714))
* **entries:** Don't add css entries twice ([0348d6b](https://github.com/jantimon/html-webpack-plugin/commit/0348d6b))
* **hooks:** Remove deprecated tapable calls [#879](https://github.com/jantimon/html-webpack-plugin/issues/879) ([2288f20](https://github.com/jantimon/html-webpack-plugin/commit/2288f20))



<a name="3.0.4"></a>
## [3.0.4](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.2...v3.0.4) (2018-03-01)


### Bug Fixes

* **entries:** Don't add css entries twice ([e890f23](https://github.com/jantimon/html-webpack-plugin/commit/e890f23))



<a name="3.0.3"></a>
## [3.0.3](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.2...v3.0.3) (2018-03-01)


### Refactor

* **performance:** Reduce the amount of chunk information gathered based on #825 ([06c59a7](https://github.com/jantimon/html-webpack-plugin/commit/06c59a7))


<a name="3.0.2"></a>
## [3.0.2](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.1...v3.0.2) (2018-03-01)


### Bug Fixes

* **query-loader:** In case no query is provided, return an empty object. This fixes #727 ([7587754](https://github.com/jantimon/html-webpack-plugin/commit/7587754))



<a name="3.0.1"></a>
## [3.0.1](https://github.com/jantimon/html-webpack-plugin/compare/v3.0.0...v3.0.1) (2018-03-01)


### Bug Fixes

* **package:** Remove the extract-text-webpack-plugin peer dependency ([57411a9](https://github.com/jantimon/html-webpack-plugin/commit/57411a9))

<a name="3.0.0"></a>
## [3.0.0](https://github.com/jantimon/html-webpack-plugin/compare/v2.30.1...v3.0.0) (2018-28-02)

### Features

* Add support for the new [webpack tapable](https://github.com/webpack/tapable) to be compatible with webpack 4.x
* Remove bluebird dependency

### BREAKING CHANGES

* Similar to webpack 4.x the support for node versions older than 6 are no longer supported

<a name="2.30.1"></a>
## 2.30.1

* Revert part the performance optimization ([#723](https://github.com/jantimon/html-webpack-plugin/pull/723)) because of [#753](https://github.com/jantimon/html-webpack-plugin/issues/753).

<a name="2.30.0"></a>
## 2.30.0

* Add manual sort
* Performance improvements ([#723](https://github.com/jantimon/html-webpack-plugin/pull/723))

<a name="2.29.0"></a>
## 2.29.0

* Add support for Webpack 3

<a name="2.28.0"></a>
## 2.28.0

* Backport 3.x void tag for plugin authors

<a name="2.27.1"></a>
## 2.27.1

* Revert 2.25.0 loader resolving

<a name="2.27.0"></a>
## 2.27.0

* Fix a chunksorter webpack 2 issue ([#569](https://github.com/jantimon/html-webpack-plugin/pull/569))
* Fix template path resolving ([#542](https://github.com/jantimon/html-webpack-plugin/pull/542))

<a name="2.26.0"></a>
## 2.26.0

* Allow plugins to add attributes without values to the `<script>` and `<link>` tags

<a name="2.25.0"></a>
## 2.25.0

* Clearer loader output
* Add basic support for webpack 2

<a name="2.24.1"></a>
## 2.24.1

* Hide event deprecated warning of 'applyPluginsAsyncWaterfall' for html-webpack-plugin-after-emit and improve the warning message.

<a name="2.24.0"></a>
## 2.24.0

* Update dependencies
* Add deprecate warning for plugins not returning a result
* Add [path] for favicons

<a name="2.23.0"></a>
## 2.23.0

* Update dependencies
* Stop automated tests for webpack 2 beta because of [#401](https://github.com/jantimon/html-webpack-plugin/issues/401)

<a name="2.22.0"></a>
## 2.22.0

* Update dependencies

<a name="2.21.1"></a>
## 2.21.1

* Better error handling ([#354](https://github.com/jantimon/html-webpack-plugin/pull/354))

<a name="2.21.0"></a>
## 2.21.0

* Add `html-webpack-plugin-alter-asset-tags` event to allow plugins to adjust the script/link tags

<a name="2.20.0"></a>
## 2.20.0

* Exclude chunks works now even if combined with dependency sort

<a name="2.19.0"></a>
## 2.19.0

* Add `html-webpack-plugin-alter-chunks` event for custom chunk sorting and interpolation

<a name="2.18.0"></a>
## 2.18.0

* Updated all dependencies

<a name="2.17.0"></a>
## 2.17.0

* Add `type` attribute to `script` element to prevent issues in Safari 9.1.1

<a name="2.16.2"></a>
## 2.16.2

* Fix bug introduced by 2.16.2. Fixes  [#315](https://github.com/jantimon/html-webpack-plugin/issues/315)

<a name="2.16.1"></a>
## 2.16.1

* Fix hot module replacement for webpack 2.x

<a name="2.16.0"></a>
## 2.16.0

* Add support for dynamic filenames like index[hash].html

<a name="2.15.0"></a>
## 2.15.0

* Add full unit test coverage for the webpack 2 beta version
* For webpack 2 the default sort will be 'dependency' instead of 'id'
* Upgrade dependencies

<a name="2.14.0"></a>
## 2.14.0

* Export publicPath to the template
* Add example for inlining css and js

<a name="2.13.0"></a>
## 2.13.0

* Add support for absolute output file names
* Add support for relative file names outside the output path

<a name="2.12.0"></a>
## 2.12.0

* Basic Webpack 2.x support #225

<a name="2.11.0"></a>
## 2.11.0

* Add `xhtml` option which is turned of by default. When activated it will inject self closed `<link href=".." />` tags instead of unclosed `<link href="..">` tags. ([#255](https://github.com/ampedandwired/html-webpack-plugin/pull/255))
* Add support for webpack placeholders inside the public path e.g. `'/dist/[hash]/'`. ([#249](https://github.com/ampedandwired/html-webpack-plugin/pull/249))

<a name="2.10.0"></a>
## 2.10.0

* Add `hash` field to the chunk object
* Add `compilation` field to the templateParam object ([#237](https://github.com/ampedandwired/html-webpack-plugin/issues/237))
* Add `html-webpack-plugin-before-html-generation` event
* Improve error messages

<a name="2.9.0"></a>
## 2.9.0

* Fix favicon path ([#185](https://github.com/ampedandwired/html-webpack-plugin/issues/185), [#208](https://github.com/ampedandwired/html-webpack-plugin/issues/208), [#215](https://github.com/ampedandwired/html-webpack-plugin/pull/215))

<a name="2.8.2"></a>
## 2.8.2

* Support relative URLs on Windows ([#205](https://github.com/ampedandwired/html-webpack-plugin/issues/205))

<a name="2.8.1"></a>
## 2.8.1

* Caching improvements ([#204](https://github.com/ampedandwired/html-webpack-plugin/issues/204))

<a name="2.8.0"></a>
## 2.8.0

* Add `dependency` mode for `chunksSortMode` to sort chunks based on their dependencies with each other

<a name="2.7.2"></a>
## 2.7.2

* Add support for require in js templates

<a name="2.7.1"></a>
## 2.7.1

* Refactoring
* Fix relative windows path

<a name="2.6.5"></a>
## 2.6.5

* Minor refactoring

<a name="2.6.4"></a>
## 2.6.4

* Fix for `"Uncaught TypeError: __webpack_require__(...) is not a function"`
* Fix incomplete cache modules causing "HtmlWebpackPlugin Error: No source available"
* Fix some issues on Windows

<a name="2.6.3"></a>
## 2.6.3

* Prevent parsing the base template with the html-loader

<a name="2.6.2"></a>
## 2.6.2

* Fix `lodash` resolve error ([#172](https://github.com/ampedandwired/html-webpack-plugin/issues/172))

<a name="2.6.1"></a>
## 2.6.1

* Fix missing module ([#164](https://github.com/ampedandwired/html-webpack-plugin/issues/164))

<a name="2.6.0"></a>
## 2.6.0

* Move compiler to its own file
* Improve error messages
* Fix global HTML_WEBPACK_PLUGIN variable

<a name="2.5.0"></a>
## 2.5.0

* Support `lodash` template's HTML _"escape"_ delimiter (`<%- %>`)
* Fix bluebird warning ([#130](https://github.com/ampedandwired/html-webpack-plugin/issues/130))
* Fix an issue where incomplete cache modules were used

<a name="2.4.0"></a>
## 2.4.0

* Don't recompile if the assets didn't change

<a name="2.3.0"></a>
## 2.3.0

* Add events `html-webpack-plugin-before-html-processing`, `html-webpack-plugin-after-html-processing`, `html-webpack-plugin-after-emit` to allow other plugins to alter the html this plugin executes

<a name="2.2.0"></a>
## 2.2.0

* Inject css and js even if the html file is incomplete ([#135](https://github.com/ampedandwired/html-webpack-plugin/issues/135))
* Update dependencies

<a name="2.1.0"></a>
## 2.1.0

* Synchronize with the stable `@1` version

<a name="2.0.4"></a>
## 2.0.4

* Fix `minify` option
* Fix missing hash interpolation in publicPath

<a name="2.0.3"></a>
## 2.0.3

* Add support for webpack.BannerPlugin

<a name="2.0.2"></a>
## 2.0.2

* Add support for loaders in templates ([#41](https://github.com/ampedandwired/html-webpack-plugin/pull/41))
* Remove `templateContent` option from configuration
* Better error messages
* Update dependencies


<a name="1.7.0"></a>
## 1.7.0

* Add `chunksSortMode` option to configuration to control how chunks should be sorted before they are included to the html
* Don't insert async chunks into html ([#95](https://github.com/ampedandwired/html-webpack-plugin/issues/95))
* Update dependencies

<a name="1.6.2"></a>
## 1.6.2

* Fix paths on Windows
* Fix missing hash interpolation in publicPath
* Allow only `false` or `object` in `minify` configuration option

<a name="1.6.1"></a>
## 1.6.1

* Add `size` field to the chunk object
* Fix stylesheet `<link>`s being discarded when used with `"inject: 'head'"`
* Update dependencies

<a name="1.6.0"></a>
## 1.6.0

* Support placing templates in subfolders
* Don't include chunks with undefined name ([#60](https://github.com/ampedandwired/html-webpack-plugin/pull/60))
* Don't include async chunks

<a name="1.5.2"></a>
## 1.5.2

* Update dependencies (lodash)

<a name="1.5.1"></a>
## 1.5.1

* Fix error when manifest is specified ([#56](https://github.com/ampedandwired/html-webpack-plugin/issues/56))

<a name="1.5.0"></a>
## 1.5.0

* Allow to inject javascript files into the head of the html page
* Fix error reporting

<a name="1.4.0"></a>
## 1.4.0

* Add `favicon.ico` option
* Add html minifcation

<a name="1.2.0"></a>
## 1.2.0

* Set charset using HTML5 meta attribute
* Reload upon change when using webpack watch mode
* Generate manifest attribute when using
  [appcache-webpack-plugin](https://github.com/lettertwo/appcache-webpack-plugin)
* Optionally add webpack hash as a query string to resources included in the HTML
  (`hash: true`) for cache busting
* CSS files generated using webpack (for example, by using the
  [extract-text-webpack-plugin](https://github.com/webpack/extract-text-webpack-plugin))
  are now automatically included into the generated HTML
* More detailed information about the files generated by webpack is now available
  to templates in the `o.htmlWebpackPlugin.files` attribute. See readme for more
  details. This new attribute deprecates the old `o.htmlWebpackPlugin.assets` attribute.
* The `templateContent` option can now be a function that returns the template string to use
* Expose webpack configuration to templates (`o.webpackConfig`)
* Sort chunks to honour dependencies between them (useful for use with CommonsChunkPlugin).
