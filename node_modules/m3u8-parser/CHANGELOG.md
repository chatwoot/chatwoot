<a name="4.7.0"></a>
# [4.7.0](https://github.com/videojs/m3u8-parser/compare/v4.6.0...v4.7.0) (2021-05-19)

### Features

* add key property to init segment/map ([#141](https://github.com/videojs/m3u8-parser/issues/141)) ([ae5fa64](https://github.com/videojs/m3u8-parser/commit/ae5fa64))

### Bug Fixes

* ignore fairplay content protection ([#140](https://github.com/videojs/m3u8-parser/issues/140)) ([9f62c85](https://github.com/videojs/m3u8-parser/commit/9f62c85))

<a name="4.6.0"></a>
# [4.6.0](https://github.com/videojs/m3u8-parser/compare/v4.5.2...v4.6.0) (2021-03-04)

### Features

* add support for #EXT-X-PART ([#127](https://github.com/videojs/m3u8-parser/issues/127)) ([9f5a224](https://github.com/videojs/m3u8-parser/commit/9f5a224)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3282436](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3282436) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add support for #EXT-X-PART-INF ([#126](https://github.com/videojs/m3u8-parser/issues/126)) ([985ab68](https://github.com/videojs/m3u8-parser/commit/985ab68)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3282434](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3282434) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add support for #EXT-X-PRELOAD-HINT ([#123](https://github.com/videojs/m3u8-parser/issues/123)) ([4fd693a](https://github.com/videojs/m3u8-parser/commit/4fd693a)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3526694](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3526694) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add support for #EXT-X-RENDITION-REPORT ([#124](https://github.com/videojs/m3u8-parser/issues/124)) ([03f4345](https://github.com/videojs/m3u8-parser/commit/03f4345)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3282435](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3282435) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add support for #EXT-X-SERVER-CONTROL ([#121](https://github.com/videojs/m3u8-parser/issues/121)) ([7f82f53](https://github.com/videojs/m3u8-parser/commit/7f82f53)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3281374](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3281374) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add support for #EXT-X-SKIP ([#122](https://github.com/videojs/m3u8-parser/issues/122)) ([9cebc86](https://github.com/videojs/m3u8-parser/commit/9cebc86)), closes [/developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls#3282433](https://github.com//developer.apple.com/documentation/http_live_streaming/enabling_low-latency_hls/issues/3282433) [/tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//tools.ietf.org/html/draft-pantos-hls-rfc8216bis-08/issues/section-4)
* add version parsing and remove totalduration ([#135](https://github.com/videojs/m3u8-parser/issues/135)) ([98f0421](https://github.com/videojs/m3u8-parser/commit/98f0421))
* add warn/info triggers and defaults for ll-hls tags ([#131](https://github.com/videojs/m3u8-parser/issues/131)) ([4f4da3d](https://github.com/videojs/m3u8-parser/commit/4f4da3d))
* **llhls:** preloadSegment, associate parts/preloadHints with segments, unify byterange handling ([#137](https://github.com/videojs/m3u8-parser/issues/137)) ([2c2dffe](https://github.com/videojs/m3u8-parser/commit/2c2dffe))

### Chores

* lint fixtures ([#134](https://github.com/videojs/m3u8-parser/issues/134)) ([e09c7ed](https://github.com/videojs/m3u8-parser/commit/e09c7ed))
* remove unused and non-standard tag #ZEN-TOTAL-DURATION ([#133](https://github.com/videojs/m3u8-parser/issues/133)) ([fb3b629](https://github.com/videojs/m3u8-parser/commit/fb3b629))
* switch to rollup-plugin-data-files ([#130](https://github.com/videojs/m3u8-parser/issues/130)) ([8f69b45](https://github.com/videojs/m3u8-parser/commit/8f69b45))

### Code Refactoring

* llhls attributes to camel case ([#138](https://github.com/videojs/m3u8-parser/issues/138)) ([31ed052](https://github.com/videojs/m3u8-parser/commit/31ed052))

### Tests

* add llhls manifests for incoming features ([#125](https://github.com/videojs/m3u8-parser/issues/125)) ([0823ea8](https://github.com/videojs/m3u8-parser/commit/0823ea8))
* move tests around ([#129](https://github.com/videojs/m3u8-parser/issues/129)) ([e86dcae](https://github.com/videojs/m3u8-parser/commit/e86dcae))

<a name="4.5.2"></a>
## [4.5.2](https://github.com/videojs/m3u8-parser/compare/v4.5.1...v4.5.2) (2021-01-12)

### Bug Fixes

* cjs dist should import only cjs ([#120](https://github.com/videojs/m3u8-parser/issues/120)) ([a58149d](https://github.com/videojs/m3u8-parser/commit/a58149d))

<a name="4.5.1"></a>
## [4.5.1](https://github.com/videojs/m3u8-parser/compare/v4.5.0...v4.5.1) (2021-01-11)

### Chores

* update to vhs-utils[@3](https://github.com/3) ([#118](https://github.com/videojs/m3u8-parser/issues/118)) ([f701c0f](https://github.com/videojs/m3u8-parser/commit/f701c0f))

<a name="4.5.0"></a>
# [4.5.0](https://github.com/videojs/m3u8-parser/compare/v4.4.3...v4.5.0) (2020-11-03)

### Chores

* **package:** update to vhs-utils[@2](https://github.com/2) ([#117](https://github.com/videojs/m3u8-parser/issues/117)) ([57ac9d2](https://github.com/videojs/m3u8-parser/commit/57ac9d2))

<a name="4.4.3"></a>
## [4.4.3](https://github.com/videojs/m3u8-parser/compare/v4.4.2...v4.4.3) (2020-08-12)

### Bug Fixes

* fix default EXT-X-BYTERANGE offset to start after the previous segment ([#98](https://github.com/videojs/m3u8-parser/issues/98)) ([08aca73](https://github.com/videojs/m3u8-parser/commit/08aca73))

### Tests

* run tests on node ([#97](https://github.com/videojs/m3u8-parser/issues/97)) ([4ad5c2d](https://github.com/videojs/m3u8-parser/commit/4ad5c2d))

<a name="4.4.2"></a>
## [4.4.2](https://github.com/videojs/m3u8-parser/compare/v4.4.1...v4.4.2) (2019-08-30)

### Chores

* **package:** update [@videojs](https://github.com/videojs)/vhs-utils ([651b4ae](https://github.com/videojs/m3u8-parser/commit/651b4ae))

<a name="4.4.1"></a>
## [4.4.1](https://github.com/videojs/m3u8-parser/compare/v4.4.0...v4.4.1) (2019-08-21)

### Chores

* update generator version and use [@videojs](https://github.com/videojs)/vhs-utils ([#95](https://github.com/videojs/m3u8-parser/issues/95)) ([7985794](https://github.com/videojs/m3u8-parser/commit/7985794))

<a name="4.4.0"></a>
# [4.4.0](https://github.com/videojs/m3u8-parser/compare/v4.3.0...v4.4.0) (2019-06-25)

### Features

* parse key attributes for Widevine HLS ([#88](https://github.com/videojs/m3u8-parser/issues/88)) ([d835fa8](https://github.com/videojs/m3u8-parser/commit/d835fa8))

### Chores

* **package:** update all dev dependencies ([#89](https://github.com/videojs/m3u8-parser/issues/89)) ([e991447](https://github.com/videojs/m3u8-parser/commit/e991447))

<a name="4.3.0"></a>
# [4.3.0](https://github.com/videojs/m3u8-parser/compare/v4.2.0...v4.3.0) (2019-01-10)

### Features

* custom tag mapping ([#73](https://github.com/videojs/m3u8-parser/issues/73)) ([0ef040a](https://github.com/videojs/m3u8-parser/commit/0ef040a))

### Chores

* Update to plugin generator 7 standards ([#53](https://github.com/videojs/m3u8-parser/issues/53)) ([35ff471](https://github.com/videojs/m3u8-parser/commit/35ff471))
* **package:** update rollup to version 0.66.0 ([#55](https://github.com/videojs/m3u8-parser/issues/55)) ([2407466](https://github.com/videojs/m3u8-parser/commit/2407466))
* Update videojs-generate-karma-config to the latest version 🚀 ([#59](https://github.com/videojs/m3u8-parser/issues/59)) ([023c6c9](https://github.com/videojs/m3u8-parser/commit/023c6c9))
* Update videojs-generate-karma-config to the latest version 🚀 ([#60](https://github.com/videojs/m3u8-parser/issues/60)) ([2773819](https://github.com/videojs/m3u8-parser/commit/2773819))
* Update videojs-generate-rollup-config to the latest version 🚀 ([#58](https://github.com/videojs/m3u8-parser/issues/58)) ([8c28a8b](https://github.com/videojs/m3u8-parser/commit/8c28a8b))

<a name="4.2.0"></a>
# [4.2.0](https://github.com/videojs/m3u8-parser/compare/v4.1.0...v4.2.0) (2018-02-23)

### Features

* add program-date-time tag info to parsed segments ([#27](https://github.com/videojs/m3u8-parser/issues/27)) ([44fc6f8](https://github.com/videojs/m3u8-parser/commit/44fc6f8))

<a name="4.1.0"></a>
# [4.1.0](https://github.com/videojs/m3u8-parser/compare/v4.0.0...v4.1.0) (2018-01-24)

<a name="4.0.0"></a>
# [4.0.0](https://github.com/videojs/m3u8-parser/compare/v3.0.0...v4.0.0) (2017-11-21)

### Features

* added ability to parse EXT-X-START tags [#31](https://github.com/videojs/m3u8-parser/pull/31)

### BREAKING CHANGES

* camel case module name in rollup config to work with latest rollup [#32](https://github.com/videojs/m3u8-parser/pull/32)

<a name="3.0.0"></a>
# 3.0.0 (2017-06-09)

### Features

* Rollup ([#24](https://github.com/videojs/m3u8-parser/issues/24)) ([47ef11f](https://github.com/videojs/m3u8-parser/commit/47ef11f))


### BREAKING CHANGES

* drop bower support.

## 2.1.0 (2017-02-23)
* parse FORCED attribute of media-groups [#15](https://github.com/videojs/m3u8-parser/pull/15)
* Pass any CHARACTERISTICS value of a track with the track object [#14](https://github.com/videojs/m3u8-parser/pull/14)

## 2.0.1 (2017-01-20)
* Fix: Include the babel ES3 tranform to support IE8 [#13](https://github.com/videojs/m3u8-parser/pull/13)

## 2.0.0 (2017-01-13)
* Manifest object is now initialized with an empty segments arrays
* moved to latest videojs-standard version, brought code into
compliance with the latest eslint rules.

## 1.0.2 (2016-06-07)
* fix the build pipeline
* removed video.js css/js inclusion during tests

## 1.0.1 (2016-06-07)
* remove dependence on video.js
* added contributors to package.json

## 1.0.0 (2016-06-03)
Initial Release

