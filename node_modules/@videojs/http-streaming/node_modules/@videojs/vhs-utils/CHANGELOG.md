<a name="3.0.4"></a>
## [3.0.4](https://github.com/videojs/vhs-utils/compare/v3.0.3...v3.0.4) (2021-09-22)

### Bug Fixes

* mark global/window/document as external globals ([#30](https://github.com/videojs/vhs-utils/issues/30)) ([8216630](https://github.com/videojs/vhs-utils/commit/8216630))

### Chores

* don't run tests on version ([#31](https://github.com/videojs/vhs-utils/issues/31)) ([24dab1d](https://github.com/videojs/vhs-utils/commit/24dab1d))
* switch generate-formats to shared [@brandonocasey](https://github.com/brandonocasey)/spawn-promise ([873b43f](https://github.com/videojs/vhs-utils/commit/873b43f))

<a name="3.0.3"></a>
## [3.0.3](https://github.com/videojs/vhs-utils/compare/v3.0.2...v3.0.3) (2021-07-26)

### Bug Fixes

* detect mp4 starting with moof/moov box as mp4 ([#29](https://github.com/videojs/vhs-utils/issues/29)) ([51d995d](https://github.com/videojs/vhs-utils/commit/51d995d))
* look at all program map tables for ts stream types ([#28](https://github.com/videojs/vhs-utils/issues/28)) ([1edb519](https://github.com/videojs/vhs-utils/commit/1edb519))

<a name="3.0.2"></a>
## [3.0.2](https://github.com/videojs/vhs-utils/compare/v3.0.1...v3.0.2) (2021-05-20)

### Bug Fixes

* properly handle data URIs ([#27](https://github.com/videojs/vhs-utils/issues/27)) ([9b10245](https://github.com/videojs/vhs-utils/commit/9b10245)), closes [videojs/video.js#7240](https://github.com/videojs/video.js/issues/7240)

<a name="3.0.1"></a>
## [3.0.1](https://github.com/videojs/vhs-utils/compare/v3.0.0...v3.0.1) (2021-04-29)

### Bug Fixes

* binary issues ([e9f5079](https://github.com/videojs/vhs-utils/commit/e9f5079))

### Chores

* update vjsverify ([105c26a](https://github.com/videojs/vhs-utils/commit/105c26a))

### Performance Improvements

* use native URL when available ([#26](https://github.com/videojs/vhs-utils/issues/26)) ([e7eaab9](https://github.com/videojs/vhs-utils/commit/e7eaab9))

<a name="3.0.0"></a>
# [3.0.0](https://github.com/videojs/vhs-utils/compare/v2.3.0...v3.0.0) (2020-12-18)

### Features

* Extend our current container parsing logic and add logic for parsing codecs from files ([#14](https://github.com/videojs/vhs-utils/issues/14)) ([d425956](https://github.com/videojs/vhs-utils/commit/d425956))
* parse any number of codecs rather than just the last audio or the last video codec. ([#23](https://github.com/videojs/vhs-utils/issues/23)) ([33ec9f5](https://github.com/videojs/vhs-utils/commit/33ec9f5))
* use [@videojs](https://github.com/videojs)/babel-config to transpile code to cjs/es for node ([#20](https://github.com/videojs/vhs-utils/issues/20)) ([c6dbd0b](https://github.com/videojs/vhs-utils/commit/c6dbd0b))

### Chores

* switch from travis to github ci ([#24](https://github.com/videojs/vhs-utils/issues/24)) ([cfee30b](https://github.com/videojs/vhs-utils/commit/cfee30b))


### BREAKING CHANGES

* cjs dist files changed from './dist' to './cjs'
* parseCodecs now returns an array of codecs that where parsed so that we can support any number of codecs instead of just two.
* toUint8 in byte-helpers functions slightly differently
* getId3Offset is exported from id3-helpers rather than containers

We can now parse the container for and many of the codecs within (where applicable) for mp4, avi, ts, mkv, webm, ogg, wav, aac, ac3 (and ec3 which is contained in ac3 files), mp3, flac, raw h265, and raw h264.

Codec parsing has also been extended to parse codec details in a file for vp09, avc (h264), hevc (h265), av1, and opus

Finally we have the following additional features to our parsing of codec/container information:
* skipping multiple id3 tags at the start of a file for flac, mp3, and aac
* discarding emulation prevention bits (in h264, h265)
* parsing raw h264/h265 to get codec params for ts, avi, and even raw h264/h265 files

<a name="2.3.0"></a>
# [2.3.0](https://github.com/videojs/vhs-utils/compare/v2.2.1...v2.3.0) (2020-12-03)

### Features

* parse unknown and text codecs ([#19](https://github.com/videojs/vhs-utils/issues/19)) ([9c90076](https://github.com/videojs/vhs-utils/commit/9c90076))

### Chores

* Add repository info to package.json ([#22](https://github.com/videojs/vhs-utils/issues/22)) ([a22ae78](https://github.com/videojs/vhs-utils/commit/a22ae78))

<a name="2.2.1"></a>
## [2.2.1](https://github.com/videojs/stream/compare/v2.2.0...v2.2.1) (2020-10-06)

### Bug Fixes

* check for multiple id3 sections in a file (#21) ([759a039](https://github.com/videojs/stream/commit/759a039)), closes [#21](https://github.com/videojs/stream/issues/21)
* parse unknown codecs as audio or video (#15) ([cd2c9bb](https://github.com/videojs/stream/commit/cd2c9bb)), closes [#15](https://github.com/videojs/stream/issues/15)

### Reverts

* "fix: parse unknown codecs as audio or video (#15)" (#18) ([9983be8](https://github.com/videojs/stream/commit/9983be8)), closes [#15](https://github.com/videojs/stream/issues/15) [#18](https://github.com/videojs/stream/issues/18)

<a name="2.2.0"></a>
# [2.2.0](https://github.com/videojs/stream/compare/v2.1.0...v2.2.0) (2020-05-01)

### Features

* Add a function to concat typed arrays into one Uint8Array (#13) ([e733509](https://github.com/videojs/stream/commit/e733509)), closes [#13](https://github.com/videojs/stream/issues/13)

<a name="2.1.0"></a>
# [2.1.0](https://github.com/videojs/stream/compare/v2.0.0...v2.1.0) (2020-04-27)

### Features

* Add functions for byte manipulation and segment container detection (#12) ([325f677](https://github.com/videojs/stream/commit/325f677)), closes [#12](https://github.com/videojs/stream/issues/12)

<a name="2.0.0"></a>
# [2.0.0](https://github.com/videojs/stream/compare/v1.3.0...v2.0.0) (2020-04-07)

### Features

* **codec:** changes to handle muxer/browser/video/audio support separately (#10) ([1f92865](https://github.com/videojs/stream/commit/1f92865)), closes [#10](https://github.com/videojs/stream/issues/10)

### Bug Fixes

* Allow VP9 and AV1 codecs through in VHS ([b32e35b](https://github.com/videojs/stream/commit/b32e35b))


### BREAKING CHANGES

* **codec:** parseCodecs output has been changed. It now returns an object that can have an audio or video property, depending on the codecs found. Those properties are object that contain type. and details. Type being the codec name and details being codec specific information usually with a leading period.
* **codec:** `audioProfileFromDefault` has been renamed to `codecsFromDefault` and now returns all output from `parseCodecs` not just audio or audio profile.

<a name="1.3.0"></a>
# [1.3.0](https://github.com/videojs/vhs-utils/compare/v1.2.1...v1.3.0) (2020-02-05)

### Features

* add forEachMediaGroup in media-groups module (#8) ([a1eacf4](https://github.com/videojs/vhs-utils/commit/a1eacf4)), closes [#8](https://github.com/videojs/vhs-utils/issues/8)

<a name="1.2.1"></a>
## [1.2.1](https://github.com/videojs/vhs-utils/compare/v1.2.0...v1.2.1) (2020-01-15)

### Bug Fixes

* include videojs in VHS JSON media type (#7) ([da072f0](https://github.com/videojs/vhs-utils/commit/da072f0)), closes [#7](https://github.com/videojs/vhs-utils/issues/7)

<a name="1.2.0"></a>
# [1.2.0](https://github.com/videojs/vhs-utils/compare/v1.1.0...v1.2.0) (2019-12-06)

### Features

* add media-types module with simpleTypeFromSourceType function (#4) ([d3ebd3f](https://github.com/videojs/vhs-utils/commit/d3ebd3f)), closes [#4](https://github.com/videojs/vhs-utils/issues/4)
* add VHS codec parsing and translation functions (#5) ([4fe0e22](https://github.com/videojs/vhs-utils/commit/4fe0e22)), closes [#5](https://github.com/videojs/vhs-utils/issues/5)

<a name="1.1.0"></a>
# [1.1.0](https://github.com/videojs/stream/compare/v1.0.0...v1.1.0) (2019-08-30)

### Features

* node support and more stream tests ([315ab8d](https://github.com/videojs/stream/commit/315ab8d))

<a name="1.0.0"></a>
# 1.0.0 (2019-08-21)

### Features

* clones from mpd-parser, m3u8-parser, mux.js, aes-decrypter, and vhs ([5e89042](https://github.com/videojs/stream/commit/5e89042))

