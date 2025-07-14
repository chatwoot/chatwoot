<a name="0.21.0"></a>
# [0.21.0](https://github.com/videojs/mpd-parser/compare/v0.20.0...v0.21.0) (2021-12-17)

### Features

* support multi-period live DASH with changing periods ([#152](https://github.com/videojs/mpd-parser/issues/152)) ([fe886d0](https://github.com/videojs/mpd-parser/commit/fe886d0))


### BREAKING CHANGES

* period start time (periodStart) is now used as the timeline instead of period index (periodIndex)

<a name="0.20.0"></a>
# [0.20.0](https://github.com/videojs/mpd-parser/compare/v0.19.2...v0.20.0) (2021-11-29)

### Features

* support BigInt values ([#135](https://github.com/videojs/mpd-parser/issues/135)) ([50eb434](https://github.com/videojs/mpd-parser/commit/50eb434))

### Chores

* don't run tests on version ([#154](https://github.com/videojs/mpd-parser/issues/154)) ([bcbe162](https://github.com/videojs/mpd-parser/commit/bcbe162))

### Documentation

* fixed examples of using "parse" ([#149](https://github.com/videojs/mpd-parser/issues/149)) ([bf0421e](https://github.com/videojs/mpd-parser/commit/bf0421e))

<a name="0.19.2"></a>
## [0.19.2](https://github.com/videojs/mpd-parser/compare/v0.19.1...v0.19.2) (2021-10-06)

### Bug Fixes

* caption services are allowed not to have a value ([#151](https://github.com/videojs/mpd-parser/issues/151)) ([c9803f1](https://github.com/videojs/mpd-parser/commit/c9803f1))

<a name="0.19.1"></a>
## [0.19.1](https://github.com/videojs/mpd-parser/compare/v0.19.0...v0.19.1) (2021-09-22)

### Bug Fixes

* mark global/window/document as external globals ([#148](https://github.com/videojs/mpd-parser/issues/148)) ([2f82ff8](https://github.com/videojs/mpd-parser/commit/2f82ff8))

<a name="0.19.0"></a>
# [0.19.0](https://github.com/videojs/mpd-parser/compare/v0.18.0...v0.19.0) (2021-08-24)

### Features

* add presentationTime as an attribute on each SegmentList segment ([#142](https://github.com/videojs/mpd-parser/issues/142)) ([478abb0](https://github.com/videojs/mpd-parser/commit/478abb0))

### Chores

* change from the xmldom package to [@xmldom](https://github.com/xmldom)/xmldom ([#146](https://github.com/videojs/mpd-parser/issues/146)) ([a2f5cb8](https://github.com/videojs/mpd-parser/commit/a2f5cb8))
* update release ci and add github-release ([#147](https://github.com/videojs/mpd-parser/issues/147)) ([23ae57e](https://github.com/videojs/mpd-parser/commit/23ae57e))


### BREAKING CHANGES

* the presentationTimeOffset attribute has been removed from output

<a name="0.18.0"></a>
# [0.18.0](https://github.com/videojs/mpd-parser/compare/v0.17.0...v0.18.0) (2021-07-28)

### Features

* add Period[@start](https://github.com/start) attribute when missing ([#137](https://github.com/videojs/mpd-parser/issues/137)) ([f118a8b](https://github.com/videojs/mpd-parser/commit/f118a8b))
* add presentationTime as an attribute on each SegmentTemplate segment ([#139](https://github.com/videojs/mpd-parser/issues/139)) ([a972b8c](https://github.com/videojs/mpd-parser/commit/a972b8c))

### Bug Fixes

* generate proper number of segments for multiperiod content that uses segment template ([#138](https://github.com/videojs/mpd-parser/issues/138)) ([39109d0](https://github.com/videojs/mpd-parser/commit/39109d0))

### Code Refactoring

* default MPD[@type](https://github.com/type) to static when missing ([#136](https://github.com/videojs/mpd-parser/issues/136)) ([281e035](https://github.com/videojs/mpd-parser/commit/281e035))
* rename master manifest to main manifest ([#141](https://github.com/videojs/mpd-parser/issues/141)) ([5720fbd](https://github.com/videojs/mpd-parser/commit/5720fbd))
* rename SegmentInfo property from timeline to segmentTimeline ([#140](https://github.com/videojs/mpd-parser/issues/140)) ([1601467](https://github.com/videojs/mpd-parser/commit/1601467))

<a name="0.17.0"></a>
# [0.17.0](https://github.com/videojs/mpd-parser/compare/v0.16.0...v0.17.0) (2021-05-28)

### Features

* caption services metadata support ([#131](https://github.com/videojs/mpd-parser/issues/131)) ([75ecbc2](https://github.com/videojs/mpd-parser/commit/75ecbc2))

### Chores

* **package:** update to vhs-utils[@3](https://github.com/3).0.2 ([#134](https://github.com/videojs/mpd-parser/issues/134)) ([744142d](https://github.com/videojs/mpd-parser/commit/744142d))

<a name="0.16.0"></a>
# [0.16.0](https://github.com/videojs/mpd-parser/compare/v0.15.4...v0.16.0) (2021-03-26)

### Features

* add a binary to convert mpd to m3u8 json in node ([#129](https://github.com/videojs/mpd-parser/issues/129)) ([608aa9d](https://github.com/videojs/mpd-parser/commit/608aa9d))
* expose presentationTimeOffset on segments that have it ([#81](https://github.com/videojs/mpd-parser/issues/81)) ([8b58b39](https://github.com/videojs/mpd-parser/commit/8b58b39))
* parse Label element and use as m3u8 group label ([#113](https://github.com/videojs/mpd-parser/issues/113)) ([5dde0e9](https://github.com/videojs/mpd-parser/commit/5dde0e9))

### Bug Fixes

* bump xmldom to prevent npm security issue ([#122](https://github.com/videojs/mpd-parser/issues/122)) ([e132e40](https://github.com/videojs/mpd-parser/commit/e132e40))
* support multiple audio/subtitle playlists and export generateSidxKey ([#123](https://github.com/videojs/mpd-parser/issues/123)) ([f7105d8](https://github.com/videojs/mpd-parser/commit/f7105d8))

### Chores

* fix publish, add bin to files, update vjsverify ([cb4d772](https://github.com/videojs/mpd-parser/commit/cb4d772))

### Documentation

* better explain how to update the JS manifest files ([#130](https://github.com/videojs/mpd-parser/issues/130)) ([21aa91c](https://github.com/videojs/mpd-parser/commit/21aa91c))
* update usage example in README ([#127](https://github.com/videojs/mpd-parser/issues/127)) ([f0da2cc](https://github.com/videojs/mpd-parser/commit/f0da2cc))

<a name="0.15.4"></a>
## [0.15.4](https://github.com/videojs/mpd-parser/compare/v0.15.3...v0.15.4) (2021-02-24)
An accidental republish of 0.15.3 with no changes.

<a name="0.15.3"></a>
## [0.15.3](https://github.com/videojs/mpd-parser/compare/v0.15.2...v0.15.3) (2021-02-24)

### Features

* add support for endNumber in template duration parsing ([#120](https://github.com/videojs/mpd-parser/issues/120)) ([0a75d62](https://github.com/videojs/mpd-parser/commit/0a75d62))

<a name="0.15.2"></a>
## [0.15.2](https://github.com/videojs/mpd-parser/compare/v0.15.1...v0.15.2) (2021-01-12)

### Bug Fixes

* cjs dist should only import cjs ([#118](https://github.com/videojs/mpd-parser/issues/118)) ([0529e62](https://github.com/videojs/mpd-parser/commit/0529e62))

<a name="0.15.1"></a>
## [0.15.1](https://github.com/videojs/mpd-parser/compare/v0.15.0...v0.15.1) (2021-01-11)

### Chores

* update to vhs-utils[@3](https://github.com/3) ([#115](https://github.com/videojs/mpd-parser/issues/115)) ([3240031](https://github.com/videojs/mpd-parser/commit/3240031))

<a name="0.15.0"></a>
# [0.15.0](https://github.com/videojs/mpd-parser/compare/v0.14.0...v0.15.0) (2020-11-17)

### Features

* expose add addSidxSegmentsToPlaylist ([#109](https://github.com/videojs/mpd-parser/issues/109)) ([880c139](https://github.com/videojs/mpd-parser/commit/880c139))
* recognize webm segments as video ([#79](https://github.com/videojs/mpd-parser/issues/79)) ([aa1bbf1](https://github.com/videojs/mpd-parser/commit/aa1bbf1))

### Bug Fixes

* edge case error handling on ie 11 ([#112](https://github.com/videojs/mpd-parser/issues/112)) ([23040c1](https://github.com/videojs/mpd-parser/commit/23040c1))

### Chores

* switch from travis ci to github ci ([#111](https://github.com/videojs/mpd-parser/issues/111)) ([1dc9090](https://github.com/videojs/mpd-parser/commit/1dc9090))

### Tests

* fix tests introduced in [#79](https://github.com/videojs/mpd-parser/issues/79) that was not rebased on [#103](https://github.com/videojs/mpd-parser/issues/103) ([#110](https://github.com/videojs/mpd-parser/issues/110)) ([1a6abbf](https://github.com/videojs/mpd-parser/commit/1a6abbf))

<a name="0.14.0"></a>
# [0.14.0](https://github.com/videojs/mpd-parser/compare/v0.13.0...v0.14.0) (2020-11-03)

### Chores

* **package:** update to vhs-utils[@2](https://github.com/2) ([#108](https://github.com/videojs/mpd-parser/issues/108)) ([8337333](https://github.com/videojs/mpd-parser/commit/8337333))

<a name="0.13.0"></a>
# [0.13.0](https://github.com/videojs/mpd-parser/compare/v0.12.0...v0.13.0) (2020-09-29)

### Features

* add CODECS attribute to subtitle playlists if it exists ([#106](https://github.com/videojs/mpd-parser/issues/106)) ([bc0872a](https://github.com/videojs/mpd-parser/commit/bc0872a))

<a name="0.12.0"></a>
# [0.12.0](https://github.com/videojs/mpd-parser/compare/v0.11.0...v0.12.0) (2020-09-03)

### Features

* remove default value of 0 for minimumUpdatePeriod ([#103](https://github.com/videojs/mpd-parser/issues/103)) ([38ca9ad](https://github.com/videojs/mpd-parser/commit/38ca9ad))


### BREAKING CHANGES

* The minimumUpdatePeriod property is now omitted from parsed output if it is not present in the manifest, rather than using a default value of 0. This is to allow differentiation between cases when a value of 0 is present in the manifest and when no value is provided.

<a name="0.11.0"></a>
# [0.11.0](https://github.com/videojs/mpd-parser/compare/v0.10.1...v0.11.0) (2020-08-12)

### Features

* parse out Location elements ([#102](https://github.com/videojs/mpd-parser/issues/102)) ([967e5e6](https://github.com/videojs/mpd-parser/commit/967e5e6))

<a name="0.10.1"></a>
## [0.10.1](https://github.com/videojs/mpd-parser/compare/v0.10.0...v0.10.1) (2020-03-31)

### Bug Fixes

* don't adjust mediaPresentationDuration by timescale for segment duration when using SegmentBase ([#94](https://github.com/videojs/mpd-parser/issues/94)) ([40cdd00](https://github.com/videojs/mpd-parser/commit/40cdd00))

<a name="0.10.0"></a>
# [0.10.0](https://github.com/videojs/mpd-parser/compare/v0.9.0...v0.10.0) (2020-02-04)

### Features

* expose suggestPresentationDelay if the type is dynamic ([#82](https://github.com/videojs/mpd-parser/issues/82)) ([cd27003](https://github.com/videojs/mpd-parser/commit/cd27003))

<a name="0.9.0"></a>
# [0.9.0](https://github.com/videojs/mpd-parser/compare/v0.8.2...v0.9.0) (2019-08-30)

### Features

* node support ([#75](https://github.com/videojs/mpd-parser/issues/75)) ([58b43b0](https://github.com/videojs/mpd-parser/commit/58b43b0))

<a name="0.8.2"></a>
## [0.8.2](https://github.com/videojs/mpd-parser/compare/v0.8.1...v0.8.2) (2019-08-22)

### Chores

* update generator and use [@videojs](https://github.com/videojs)/vhs-utils ([#76](https://github.com/videojs/mpd-parser/issues/76)) ([1238749](https://github.com/videojs/mpd-parser/commit/1238749))

<a name="0.8.1"></a>
## [0.8.1](https://github.com/videojs/mpd-parser/compare/v0.8.0...v0.8.1) (2019-05-01)

### Bug Fixes

* skip playlists without sidx ([#73](https://github.com/videojs/mpd-parser/issues/73)) ([67d2bad](https://github.com/videojs/mpd-parser/commit/67d2bad)), closes [videojs/video.js#5289](https://github.com/videojs/video.js/issues/5289)

<a name="0.8.0"></a>
# [0.8.0](https://github.com/videojs/mpd-parser/compare/v0.7.0...v0.8.0) (2019-04-11)

### Features

* add sidx information to segment base playlists ([#41](https://github.com/videojs/mpd-parser/issues/41)) ([1176109](https://github.com/videojs/mpd-parser/commit/1176109))

### Bug Fixes

* make byteRange.length inclusive ([#43](https://github.com/videojs/mpd-parser/issues/43)) ([28d217a](https://github.com/videojs/mpd-parser/commit/28d217a))

### Chores

* add netlify for testing ([#45](https://github.com/videojs/mpd-parser/issues/45)) ([a78a7be](https://github.com/videojs/mpd-parser/commit/a78a7be))
* Update videojs-generate-karma-config to the latest version 🚀 ([#37](https://github.com/videojs/mpd-parser/issues/37)) ([a18c660](https://github.com/videojs/mpd-parser/commit/a18c660))
* Update videojs-generate-karma-config to the latest version 🚀 ([#38](https://github.com/videojs/mpd-parser/issues/38)) ([3aaabac](https://github.com/videojs/mpd-parser/commit/3aaabac))
* Update videojs-generate-rollup-config to the latest version 🚀 ([#36](https://github.com/videojs/mpd-parser/issues/36)) ([3f6ccbd](https://github.com/videojs/mpd-parser/commit/3f6ccbd))
* **package:** update videojs-generate-karma-config to 5.0.2 ([#54](https://github.com/videojs/mpd-parser/issues/54)) ([fcbabc3](https://github.com/videojs/mpd-parser/commit/fcbabc3))
* **package:** videojs-generate-karma-config[@4](https://github.com/4).0.0 does not exist ([#44](https://github.com/videojs/mpd-parser/issues/44)) ([bc361b5](https://github.com/videojs/mpd-parser/commit/bc361b5))

<a name="0.7.0"></a>
# [0.7.0](https://github.com/videojs/mpd-parser/compare/v0.6.1...v0.7.0) (2018-10-24)

### Features

* limited multiperiod support ([#35](https://github.com/videojs/mpd-parser/issues/35)) ([aee87a0](https://github.com/videojs/mpd-parser/commit/aee87a0))

### Bug Fixes

* fixed segment timeline parsing when duration is present ([#34](https://github.com/videojs/mpd-parser/issues/34)) ([90feb2d](https://github.com/videojs/mpd-parser/commit/90feb2d))
* Remove the postinstall script to prevent install issues ([#29](https://github.com/videojs/mpd-parser/issues/29)) ([ae458f4](https://github.com/videojs/mpd-parser/commit/ae458f4))

### Chores

* Update to generator-videojs-plugin[@7](https://github.com/7).2.0 ([#28](https://github.com/videojs/mpd-parser/issues/28)) ([909cf08](https://github.com/videojs/mpd-parser/commit/909cf08))
* **package:** Update dependencies to enable Greenkeeper 🌴 ([#30](https://github.com/videojs/mpd-parser/issues/30)) ([0593c2c](https://github.com/videojs/mpd-parser/commit/0593c2c))

<a name="0.6.1"></a>
## [0.6.1](https://github.com/videojs/mpd-parser/compare/v0.6.0...v0.6.1) (2018-05-17)

### Bug Fixes

* babel es module ([#25](https://github.com/videojs/mpd-parser/issues/25)) ([9a84461](https://github.com/videojs/mpd-parser/commit/9a84461))

<a name="0.6.0"></a>
# [0.6.0](https://github.com/videojs/mpd-parser/compare/v0.5.0...v0.6.0) (2018-03-30)

### Features

* support in-manifest DRM data ([#23](https://github.com/videojs/mpd-parser/issues/23)) ([7ce9aca](https://github.com/videojs/mpd-parser/commit/7ce9aca))

<a name="0.5.0"></a>
# [0.5.0](https://github.com/videojs/mpd-parser/compare/v0.4.0...v0.5.0) (2018-03-15)

### Features

* live support with SegmentTemplate[@duration](https://github.com/duration) and more ([#22](https://github.com/videojs/mpd-parser/issues/22)) ([f1cee87](https://github.com/videojs/mpd-parser/commit/f1cee87))

<a name="0.4.0"></a>
# [0.4.0](https://github.com/videojs/mpd-parser/compare/v0.3.0...v0.4.0) (2018-02-26)

### Features

* Adding support for segments in Period and Representation. ([#19](https://github.com/videojs/mpd-parser/issues/19)) ([8e59b38](https://github.com/videojs/mpd-parser/commit/8e59b38))

<a name="0.3.0"></a>
# [0.3.0](https://github.com/videojs/mpd-parser/compare/v0.2.1...v0.3.0) (2018-02-06)

### Features

* Parse <SegmentList> and <SegmentBase> ([#18](https://github.com/videojs/mpd-parser/issues/18)) ([71b8976](https://github.com/videojs/mpd-parser/commit/71b8976))
* Support for inheriting BaseURL and alternate BaseURLs ([#17](https://github.com/videojs/mpd-parser/issues/17)) ([7dad5d5](https://github.com/videojs/mpd-parser/commit/7dad5d5))
* add support for SegmentTemplate padding format string and SegmentTimeline ([#16](https://github.com/videojs/mpd-parser/issues/16)) ([87933f6](https://github.com/videojs/mpd-parser/commit/87933f6))

<a name="0.2.1"></a>
## [0.2.1](https://github.com/videojs/mpd-parser/compare/v0.2.0...v0.2.1) (2017-12-15)

### Bug Fixes

* access HTMLCollections with IE11 compatibility ([#15](https://github.com/videojs/mpd-parser/issues/15)) ([5612984](https://github.com/videojs/mpd-parser/commit/5612984))

<a name="0.2.0"></a>
# [0.2.0](https://github.com/videojs/mpd-parser/compare/v0.1.1...v0.2.0) (2017-12-12)

### Features

* Support for vtt ([#13](https://github.com/videojs/mpd-parser/issues/13)) ([96fc406](https://github.com/videojs/mpd-parser/commit/96fc406))

### Tests

* add more tests for vtt ([#14](https://github.com/videojs/mpd-parser/issues/14)) ([4068790](https://github.com/videojs/mpd-parser/commit/4068790))

<a name="0.1.1"></a>
## [0.1.1](https://github.com/videojs/mpd-parser/compare/v0.1.0...v0.1.1) (2017-12-07)

### Bug Fixes

* avoid using Array.prototype.fill for IE support ([#11](https://github.com/videojs/mpd-parser/issues/11)) ([5c444de](https://github.com/videojs/mpd-parser/commit/5c444de))

<a name="0.1.0"></a>
# 0.1.0 (2017-11-29)

### Bug Fixes

* switch off in-manifest caption support ([#8](https://github.com/videojs/mpd-parser/issues/8)) ([15712c6](https://github.com/videojs/mpd-parser/commit/15712c6))

CHANGELOG
=========

## HEAD (Unreleased)
_(none)_

--------------------

