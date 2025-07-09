<a name="2.13.1"></a>
## [2.13.1](https://github.com/videojs/http-streaming/compare/v2.13.0...v2.13.1) (2021-12-20)

### Bug Fixes

* **package:** update mux.js to 6.0.1 ([#1242](https://github.com/videojs/http-streaming/issues/1242)) ([aed1931](https://github.com/videojs/http-streaming/commit/aed1931))

<a name="2.13.0"></a>
# [2.13.0](https://github.com/videojs/http-streaming/compare/v2.12.1...v2.13.0) (2021-12-20)

### Features

* set up required key sessions on waitingforkey event ([#1232](https://github.com/videojs/http-streaming/issues/1232)) ([3ed24a4](https://github.com/videojs/http-streaming/commit/3ed24a4))
* use new mpd-parser API for handling live DASH refreshes ([#1231](https://github.com/videojs/http-streaming/issues/1231)) ([f109078](https://github.com/videojs/http-streaming/commit/f109078))

### Tests

* fix failing IE11 test due to late initialize of EME keys ([#1241](https://github.com/videojs/http-streaming/issues/1241)) ([159545c](https://github.com/videojs/http-streaming/commit/159545c))

<a name="2.12.1"></a>
## [2.12.1](https://github.com/videojs/http-streaming/compare/v2.12.0...v2.12.1) (2021-12-10)

### Bug Fixes

* fix seekable not updating after the first change for live streams ([#1233](https://github.com/videojs/http-streaming/issues/1233)) ([3d8755c](https://github.com/videojs/http-streaming/commit/3d8755c))
* mp4 sources that use bigint numbers ([#1217](https://github.com/videojs/http-streaming/issues/1217)) ([bfd0ad0](https://github.com/videojs/http-streaming/commit/bfd0ad0))
* support legacy hls option for overrideNative ([#1222](https://github.com/videojs/http-streaming/issues/1222)) ([4f9ce7a](https://github.com/videojs/http-streaming/commit/4f9ce7a))

### Tests

* add a test to verify that seekable updates with a live stream ([#1234](https://github.com/videojs/http-streaming/issues/1234)) ([7495ead](https://github.com/videojs/http-streaming/commit/7495ead)), closes [#1233](https://github.com/videojs/http-streaming/issues/1233)
* **playack:** make live dash test take 5 seconds ([#1235](https://github.com/videojs/http-streaming/issues/1235)) ([b66e124](https://github.com/videojs/http-streaming/commit/b66e124))

<a name="2.12.0"></a>
# [2.12.0](https://github.com/videojs/http-streaming/compare/v2.11.2...v2.12.0) (2021-11-08)

### Features

* Add an option to use the NetworkInformation API, when available ([#1218](https://github.com/videojs/http-streaming/issues/1218)) ([061cf3c](https://github.com/videojs/http-streaming/commit/061cf3c))

### Tests

* Don't run networkInfo tests against ie11 ([#1221](https://github.com/videojs/http-streaming/issues/1221)) ([aaedde3](https://github.com/videojs/http-streaming/commit/aaedde3))

<a name="2.11.2"></a>
## [2.11.2](https://github.com/videojs/http-streaming/compare/v2.11.1...v2.11.2) (2021-10-27)

### Bug Fixes

* Various fixes for llhls so that we start closer to live, and stay closer to live ([#1201](https://github.com/videojs/http-streaming/issues/1201)) ([bf4a458](https://github.com/videojs/http-streaming/commit/bf4a458))

<a name="2.11.1"></a>
## [2.11.1](https://github.com/videojs/http-streaming/compare/v2.11.0...v2.11.1) (2021-10-14)

### Bug Fixes

* **package:** update mpd-parser to 0.19.2 ([#1211](https://github.com/videojs/http-streaming/issues/1211)) ([7420296](https://github.com/videojs/http-streaming/commit/7420296))
* **package:** update mux.js to 5.14.1 ([#1215](https://github.com/videojs/http-streaming/issues/1215)) ([d7f6b63](https://github.com/videojs/http-streaming/commit/d7f6b63))
* reset transmuxer in resetEverything to fix seeking backwards in some cases ([#1213](https://github.com/videojs/http-streaming/issues/1213)) ([a83ea37](https://github.com/videojs/http-streaming/commit/a83ea37))

### Chores

* add mux's ll-hls test stream ([#1214](https://github.com/videojs/http-streaming/issues/1214)) ([fc83109](https://github.com/videojs/http-streaming/commit/fc83109))

<a name="2.11.0"></a>
# [2.11.0](https://github.com/videojs/http-streaming/compare/v2.10.3...v2.11.0) (2021-09-22)

### Features

* Add ability to pass encoding value for 708 captions via captionServices ([#1194](https://github.com/videojs/http-streaming/issues/1194)) ([e2b46e7](https://github.com/videojs/http-streaming/commit/e2b46e7))

### Bug Fixes

* do not try to save expired segment information for gaps greater than 86400 ([#1204](https://github.com/videojs/http-streaming/issues/1204)) ([0dc0b61](https://github.com/videojs/http-streaming/commit/0dc0b61))
* mark global/window/document as external globals ([#1205](https://github.com/videojs/http-streaming/issues/1205)) ([324af10](https://github.com/videojs/http-streaming/commit/324af10))
* Only check/fix bad seeks after seeking, without seeked, and an append ([#1195](https://github.com/videojs/http-streaming/issues/1195)) ([9d6505a](https://github.com/videojs/http-streaming/commit/9d6505a))
* use URL to add searchParams for LLHLS ([#1199](https://github.com/videojs/http-streaming/issues/1199)) ([a8d3c1a](https://github.com/videojs/http-streaming/commit/a8d3c1a))

### Chores

* upgrade to node 14 ([#1207](https://github.com/videojs/http-streaming/issues/1207)) ([7566ca0](https://github.com/videojs/http-streaming/commit/7566ca0))

### Tests

* fix ie 11 race condition in tests ([#1200](https://github.com/videojs/http-streaming/issues/1200)) ([1517386](https://github.com/videojs/http-streaming/commit/1517386))
* skip test on ie 11 ([#1206](https://github.com/videojs/http-streaming/issues/1206)) ([6d0cbd1](https://github.com/videojs/http-streaming/commit/6d0cbd1))

<a name="2.10.3"></a>
## [2.10.3](https://github.com/videojs/http-streaming/compare/v2.10.2...v2.10.3) (2021-09-03)

### Bug Fixes

* only register reloadSourceOnError once ([#1191](https://github.com/videojs/http-streaming/issues/1191)) ([9aeb77b](https://github.com/videojs/http-streaming/commit/9aeb77b))
* We should skip gaps that are seeked into. ([#1192](https://github.com/videojs/http-streaming/issues/1192)) ([61b8eef](https://github.com/videojs/http-streaming/commit/61b8eef))

<a name="2.10.3"></a>
## [2.10.3](https://github.com/videojs/http-streaming/compare/v2.10.2...v2.10.3) (2021-09-03)

### Bug Fixes

* only register reloadSourceOnError once ([#1191](https://github.com/videojs/http-streaming/issues/1191)) ([9aeb77b](https://github.com/videojs/http-streaming/commit/9aeb77b))
* We should skip gaps that are seeked into. ([#1192](https://github.com/videojs/http-streaming/issues/1192)) ([61b8eef](https://github.com/videojs/http-streaming/commit/61b8eef))

<a name="2.10.2"></a>
## [2.10.2](https://github.com/videojs/http-streaming/compare/v2.10.1...v2.10.2) (2021-08-24)

### Bug Fixes

* update mpd-parser and mux.js to fix an xmldom vulnerability ([#1190](https://github.com/videojs/http-streaming/issues/1190)) ([37b4b04](https://github.com/videojs/http-streaming/commit/37b4b04))

<a name="2.10.2"></a>
## [2.10.2](https://github.com/videojs/http-streaming/compare/v2.10.1...v2.10.2) (2021-08-24)

### Bug Fixes

* update mpd-parser and mux.js to fix an xmldom vulnerability ([#1190](https://github.com/videojs/http-streaming/issues/1190)) ([37b4b04](https://github.com/videojs/http-streaming/commit/37b4b04))

<a name="2.10.1"></a>
## [2.10.1](https://github.com/videojs/http-streaming/compare/v2.10.0...v2.10.1) (2021-08-17)

### Bug Fixes

* keep media update timeout alive so live playlists can recover from network issues ([#1176](https://github.com/videojs/http-streaming/issues/1176)) ([8b3533c](https://github.com/videojs/http-streaming/commit/8b3533c))

### Chores

* add a github-release action to automate github releases on version tags ([#1182](https://github.com/videojs/http-streaming/issues/1182)) ([e8230a9](https://github.com/videojs/http-streaming/commit/e8230a9))
* consistent source selection on demo start ([#1185](https://github.com/videojs/http-streaming/issues/1185)) ([ff34277](https://github.com/videojs/http-streaming/commit/ff34277))
* update the demo page ([#1184](https://github.com/videojs/http-streaming/issues/1184)) ([55f0bde](https://github.com/videojs/http-streaming/commit/55f0bde))
* various demo page fixes and enhancements ([#1186](https://github.com/videojs/http-streaming/issues/1186)) ([eef29d4](https://github.com/videojs/http-streaming/commit/eef29d4))

<a name="2.10.1"></a>
## [2.10.1](https://github.com/videojs/http-streaming/compare/v2.10.0...v2.10.1) (2021-08-17)

### Bug Fixes

* keep media update timeout alive so live playlists can recover from network issues ([#1176](https://github.com/videojs/http-streaming/issues/1176)) ([8b3533c](https://github.com/videojs/http-streaming/commit/8b3533c))

### Chores

* add a github-release action to automate github releases on version tags ([#1182](https://github.com/videojs/http-streaming/issues/1182)) ([e8230a9](https://github.com/videojs/http-streaming/commit/e8230a9))
* consistent source selection on demo start ([#1185](https://github.com/videojs/http-streaming/issues/1185)) ([ff34277](https://github.com/videojs/http-streaming/commit/ff34277))
* update the demo page ([#1184](https://github.com/videojs/http-streaming/issues/1184)) ([55f0bde](https://github.com/videojs/http-streaming/commit/55f0bde))
* various demo page fixes and enhancements ([#1186](https://github.com/videojs/http-streaming/issues/1186)) ([eef29d4](https://github.com/videojs/http-streaming/commit/eef29d4))

<a name="2.10.0"></a>
# [2.10.0](https://github.com/videojs/http-streaming/compare/v2.9.3...v2.10.0) (2021-07-28)

### Features

* add experimental pixel diff selector behind a flag defaulted off ([#786](https://github.com/videojs/http-streaming/issues/786)) ([a0c0359](https://github.com/videojs/http-streaming/commit/a0c0359))
* Add experimentalExactManifestTimings which forgoes TIME_FUDGE_FACTOR during segment choice ([#1165](https://github.com/videojs/http-streaming/issues/1165)) ([67a1201](https://github.com/videojs/http-streaming/commit/67a1201))

### Bug Fixes

* exclude playlists on DRM key status of output-restricted ([#1171](https://github.com/videojs/http-streaming/issues/1171)) ([de5baa7](https://github.com/videojs/http-streaming/commit/de5baa7))
* Generate the correct number of segments for segment template multi period dash ([#1175](https://github.com/videojs/http-streaming/issues/1175)) ([413fee3](https://github.com/videojs/http-streaming/commit/413fee3))
* update vhs-utils to correctly detect mp4 starting with moof/moov ([#1173](https://github.com/videojs/http-streaming/issues/1173)) ([464a365](https://github.com/videojs/http-streaming/commit/464a365))

### Chores

* add tests/sources for manifest object urls ([#1168](https://github.com/videojs/http-streaming/issues/1168)) ([5f60612](https://github.com/videojs/http-streaming/commit/5f60612))

### Tests

* refactor tests so that players/blob urls/ and media elements are cleaned up ([#1174](https://github.com/videojs/http-streaming/issues/1174)) ([b3d1ec0](https://github.com/videojs/http-streaming/commit/b3d1ec0))

<a name="2.10.0"></a>
# [2.10.0](https://github.com/videojs/http-streaming/compare/v2.9.3...v2.10.0) (2021-07-28)

### Features

* add experimental pixel diff selector behind a flag defaulted off ([#786](https://github.com/videojs/http-streaming/issues/786)) ([a0c0359](https://github.com/videojs/http-streaming/commit/a0c0359))
* Add experimentalExactManifestTimings which forgoes TIME_FUDGE_FACTOR during segment choice ([#1165](https://github.com/videojs/http-streaming/issues/1165)) ([67a1201](https://github.com/videojs/http-streaming/commit/67a1201))

### Bug Fixes

* exclude playlists on DRM key status of output-restricted ([#1171](https://github.com/videojs/http-streaming/issues/1171)) ([de5baa7](https://github.com/videojs/http-streaming/commit/de5baa7))
* Generate the correct number of segments for segment template multi period dash ([#1175](https://github.com/videojs/http-streaming/issues/1175)) ([413fee3](https://github.com/videojs/http-streaming/commit/413fee3))
* update vhs-utils to correctly detect mp4 starting with moof/moov ([#1173](https://github.com/videojs/http-streaming/issues/1173)) ([464a365](https://github.com/videojs/http-streaming/commit/464a365))

### Chores

* add tests/sources for manifest object urls ([#1168](https://github.com/videojs/http-streaming/issues/1168)) ([5f60612](https://github.com/videojs/http-streaming/commit/5f60612))

### Tests

* refactor tests so that players/blob urls/ and media elements are cleaned up ([#1174](https://github.com/videojs/http-streaming/issues/1174)) ([b3d1ec0](https://github.com/videojs/http-streaming/commit/b3d1ec0))

<a name="2.9.3"></a>
## [2.9.3](https://github.com/videojs/http-streaming/compare/v2.9.2...v2.9.3) (2021-07-19)

### Bug Fixes

* Prevent audio groups without a playlist from being requested. ([#1167](https://github.com/videojs/http-streaming/issues/1167)) ([8c10733](https://github.com/videojs/http-streaming/commit/8c10733))

<a name="2.9.2"></a>
## [2.9.2](https://github.com/videojs/http-streaming/compare/v2.9.1...v2.9.2) (2021-07-14)

### Bug Fixes

* Default to using segmentInfo.trackInfo over this.currentMediaInfo_ to get segment track info. ([#1162](https://github.com/videojs/http-streaming/issues/1162)) ([1d6bb55](https://github.com/videojs/http-streaming/commit/1d6bb55))
* encode correct video width/height in transmuxed mp4 ([#1166](https://github.com/videojs/http-streaming/issues/1166)) ([d32801a](https://github.com/videojs/http-streaming/commit/d32801a))
* include all master playlists in default audio group ([#1149](https://github.com/videojs/http-streaming/issues/1149)) ([297e2c7](https://github.com/videojs/http-streaming/commit/297e2c7))
* Prevent skipping frames in adts data via mux.js 5.11.3 ([#1153](https://github.com/videojs/http-streaming/issues/1153)) ([253849a](https://github.com/videojs/http-streaming/commit/253849a))

### Chores

* log transmuxer log events via segment loader ([#1155](https://github.com/videojs/http-streaming/issues/1155)) ([1e2f7a4](https://github.com/videojs/http-streaming/commit/1e2f7a4))
* prevent debugger statement removal and soucemap updating via rollup-plugin-strip ([#1147](https://github.com/videojs/http-streaming/issues/1147)) ([62f9c1c](https://github.com/videojs/http-streaming/commit/62f9c1c))
* skip playback tests in forks ([#1148](https://github.com/videojs/http-streaming/issues/1148)) ([063e163](https://github.com/videojs/http-streaming/commit/063e163))
* update utils/stats ([#1146](https://github.com/videojs/http-streaming/issues/1146)) ([c504b0d](https://github.com/videojs/http-streaming/commit/c504b0d))
* use the new npm cache option when setting up node ([#1157](https://github.com/videojs/http-streaming/issues/1157)) ([b7942ff](https://github.com/videojs/http-streaming/commit/b7942ff))

### Documentation

* update maxPlaylistRetries outline level ([93b293a](https://github.com/videojs/http-streaming/commit/93b293a))

### Tests

* cleanup/dispose transmuxers in tests ([#1163](https://github.com/videojs/http-streaming/issues/1163)) ([df07176](https://github.com/videojs/http-streaming/commit/df07176))

<a name="2.9.1"></a>
## [2.9.1](https://github.com/videojs/http-streaming/compare/v2.9.0...v2.9.1) (2021-06-22)

### Bug Fixes

* actually default maxPlaylistRetries to Infinity ([#1142](https://github.com/videojs/http-streaming/issues/1142)) ([4428e3a](https://github.com/videojs/http-streaming/commit/4428e3a)), closes [#1098](https://github.com/videojs/http-streaming/issues/1098)
* don't decay average bandwidth value if system bandwidth did not change ([#1137](https://github.com/videojs/http-streaming/issues/1137)) ([c22749b](https://github.com/videojs/http-streaming/commit/c22749b))
* ts segments that don't define all streams in the first pmt ([#1144](https://github.com/videojs/http-streaming/issues/1144)) ([36a8be4](https://github.com/videojs/http-streaming/commit/36a8be4))

### Tests

* moving average should not decay without new data ([#1141](https://github.com/videojs/http-streaming/issues/1141)) ([55726af](https://github.com/videojs/http-streaming/commit/55726af)), closes [#1137](https://github.com/videojs/http-streaming/issues/1137)

<a name="2.9.0"></a>
# [2.9.0](https://github.com/videojs/http-streaming/compare/v2.8.2...v2.9.0) (2021-06-11)

### Features

* Add support for encrypted init segments ([#1132](https://github.com/videojs/http-streaming/issues/1132)) ([4449ed5](https://github.com/videojs/http-streaming/commit/4449ed5))
* allow clients to limit the number of times a playlist attempts to reload following an error ([#1098](https://github.com/videojs/http-streaming/issues/1098)) ([44905d4](https://github.com/videojs/http-streaming/commit/44905d4))
* Caption services (608/708) metadata ([#1138](https://github.com/videojs/http-streaming/issues/1138)) ([39782c6](https://github.com/videojs/http-streaming/commit/39782c6)), closes [/datatracker.ietf.org/doc/html/draft-pantos-hls-rfc8216bis-08#section-4](https://github.com//datatracker.ietf.org/doc/html/draft-pantos-hls-rfc8216bis-08/issues/section-4) [videojs/mpd-parser#131](https://github.com/videojs/mpd-parser/issues/131)
* do fast rendition changes on fullscreen changes and user actions ([#1074](https://github.com/videojs/http-streaming/issues/1074)) ([5405c18](https://github.com/videojs/http-streaming/commit/5405c18))
* stats for timeToLoadedData, appendsToLoadedData, mainAppendsToLoadedData, audioAppendsToLoadedData, and mediaAppends ([#1106](https://github.com/videojs/http-streaming/issues/1106)) ([3124fbc](https://github.com/videojs/http-streaming/commit/3124fbc))
* Use ll-hls query directives: segment skipping and requesting a specific segment/part ([#1079](https://github.com/videojs/http-streaming/issues/1079)) ([458be2c](https://github.com/videojs/http-streaming/commit/458be2c))

### Bug Fixes

* add part level sync points, fix LL hls sync issues, add part timing info ([#1125](https://github.com/videojs/http-streaming/issues/1125)) ([ee5841d](https://github.com/videojs/http-streaming/commit/ee5841d))
* Append valid syncRequests, better sync request choice, less getMediaInfoForTime rounding ([#1127](https://github.com/videojs/http-streaming/issues/1127)) ([ce03f66](https://github.com/videojs/http-streaming/commit/ce03f66))

### Chores

* fix coverage ci run ([#1135](https://github.com/videojs/http-streaming/issues/1135)) ([82b6781](https://github.com/videojs/http-streaming/commit/82b6781))

<a name="2.8.2"></a>
## [2.8.2](https://github.com/videojs/http-streaming/compare/v2.8.1...v2.8.2) (2021-05-20)

### Bug Fixes

* add tests for data uri, fix data uri in demo page ([#1133](https://github.com/videojs/http-streaming/issues/1133)) ([0be51eb](https://github.com/videojs/http-streaming/commit/0be51eb))

<a name="2.8.1"></a>
## [2.8.1](https://github.com/videojs/http-streaming/compare/v2.8.0...v2.8.1) (2021-05-19)

### Bug Fixes

* add master referenced id/uri for audio playlists. Add playlists to hls media groups ([#1124](https://github.com/videojs/http-streaming/issues/1124)) ([740d2ee](https://github.com/videojs/http-streaming/commit/740d2ee))
* m3u8-parser/eme updates ([#1131](https://github.com/videojs/http-streaming/issues/1131)) ([29ece75](https://github.com/videojs/http-streaming/commit/29ece75))
* only append/request init segments when they change ([#1128](https://github.com/videojs/http-streaming/issues/1128)) ([a4af004](https://github.com/videojs/http-streaming/commit/a4af004))
* set audio status on loaders when setting up media groups ([#1126](https://github.com/videojs/http-streaming/issues/1126)) ([a44f984](https://github.com/videojs/http-streaming/commit/a44f984))

### Chores

* update vhs utils to 3.0.1 ([#1123](https://github.com/videojs/http-streaming/issues/1123)) ([552b012](https://github.com/videojs/http-streaming/commit/552b012))

<a name="2.8.0"></a>
# [2.8.0](https://github.com/videojs/http-streaming/compare/v2.7.1...v2.8.0) (2021-04-28)

### Features

* add initialBandwidth option at the tech level ([#1122](https://github.com/videojs/http-streaming/issues/1122)) ([2071008](https://github.com/videojs/http-streaming/commit/2071008))

### Bug Fixes

* don't clear DASH minimum update period timeout on pause of a media loader ([#1118](https://github.com/videojs/http-streaming/issues/1118)) ([82ff4f5](https://github.com/videojs/http-streaming/commit/82ff4f5))
* null check sidx on sidxmapping, check that end > start on remove ([#1121](https://github.com/videojs/http-streaming/issues/1121)) ([92f1333](https://github.com/videojs/http-streaming/commit/92f1333))

### Code Refactoring

* drop support for the partial muxer and handlePartial ([#1119](https://github.com/videojs/http-streaming/issues/1119)) ([ab305f8](https://github.com/videojs/http-streaming/commit/ab305f8))
* offload mp4/ts probe to the web worker ([#1117](https://github.com/videojs/http-streaming/issues/1117)) ([3c9f721](https://github.com/videojs/http-streaming/commit/3c9f721))
* segment/part choice and add more logging around the choice ([#1097](https://github.com/videojs/http-streaming/issues/1097)) ([b8a5aa5](https://github.com/videojs/http-streaming/commit/b8a5aa5))

<a name="2.7.1"></a>
## [2.7.1](https://github.com/videojs/http-streaming/compare/v2.7.0...v2.7.1) (2021-04-09)

### Bug Fixes

* experimentalLLHLS option should always be passed ([#1114](https://github.com/videojs/http-streaming/issues/1114)) ([684fd08](https://github.com/videojs/http-streaming/commit/684fd08))

### Chores

* dont run tests on chromium ([#1116](https://github.com/videojs/http-streaming/issues/1116)) ([c2154d7](https://github.com/videojs/http-streaming/commit/c2154d7))

<a name="2.7.0"></a>
# [2.7.0](https://github.com/videojs/http-streaming/compare/v2.6.4...v2.7.0) (2021-04-06)

### Features

* Add  EXT-X-PART support behind a flag for LL-HLS ([#1055](https://github.com/videojs/http-streaming/issues/1055)) ([b33e109](https://github.com/videojs/http-streaming/commit/b33e109))
* mark Video.js as a peer dependency ([#1111](https://github.com/videojs/http-streaming/issues/1111)) ([99480d5](https://github.com/videojs/http-streaming/commit/99480d5))
* support serverControl and preloadSegment behind experimentalLLHLS flag ([#1078](https://github.com/videojs/http-streaming/issues/1078)) ([fa1b6b5](https://github.com/videojs/http-streaming/commit/fa1b6b5))
* usage and logging on rendition change with reasons ([#1088](https://github.com/videojs/http-streaming/issues/1088)) ([1b990f1](https://github.com/videojs/http-streaming/commit/1b990f1))

### Bug Fixes

* audio only media group playlists, audio group playlists, and audio switches for audio only ([#1100](https://github.com/videojs/http-streaming/issues/1100)) ([6d83de3](https://github.com/videojs/http-streaming/commit/6d83de3))
* better time to first frame for live playlists ([#1105](https://github.com/videojs/http-streaming/issues/1105)) ([1e94680](https://github.com/videojs/http-streaming/commit/1e94680))
* catch remove errors, remove all data on QUOTA_EXCEEDED ([#1101](https://github.com/videojs/http-streaming/issues/1101)) ([86f77fe](https://github.com/videojs/http-streaming/commit/86f77fe))
* Only add sidxMapping on successful sidx request and parse. ([#1099](https://github.com/videojs/http-streaming/issues/1099)) ([de0b55b](https://github.com/videojs/http-streaming/commit/de0b55b)), closes [#1107](https://github.com/videojs/http-streaming/issues/1107)
* support automatic configuration of audio and video only DRM sources ([#1090](https://github.com/videojs/http-streaming/issues/1090)) ([9b116ce](https://github.com/videojs/http-streaming/commit/9b116ce))

### Chores

* never skip main ci runs ([#1108](https://github.com/videojs/http-streaming/issues/1108)) ([b2d2c91](https://github.com/videojs/http-streaming/commit/b2d2c91))
* turn checkWatch back on for rollup ([87947fc](https://github.com/videojs/http-streaming/commit/87947fc))
* update to mux.js[@5](https://github.com/5).11.0 ([#1109](https://github.com/videojs/http-streaming/issues/1109)) ([af5841c](https://github.com/videojs/http-streaming/commit/af5841c))

<a name="2.6.4"></a>
## [2.6.4](https://github.com/videojs/http-streaming/compare/v2.6.3...v2.6.4) (2021-03-12)

### Bug Fixes

* Monitor playback for stalls due to gaps in the beginning of stream when a new source is loaded ([#1087](https://github.com/videojs/http-streaming/issues/1087)) ([64a1f35](https://github.com/videojs/http-streaming/commit/64a1f35))
* retry appends on QUOTA_EXCEEDED_ERR ([#1093](https://github.com/videojs/http-streaming/issues/1093)) ([008aeaf](https://github.com/videojs/http-streaming/commit/008aeaf))

### Chores

* Get test coverage working again with mock/sync worker ([#1094](https://github.com/videojs/http-streaming/issues/1094)) ([035e8c0](https://github.com/videojs/http-streaming/commit/035e8c0))
* pin CI to ubuntu 18.04 ([#1091](https://github.com/videojs/http-streaming/issues/1091)) ([01ca182](https://github.com/videojs/http-streaming/commit/01ca182))

<a name="2.6.3"></a>
## [2.6.3](https://github.com/videojs/http-streaming/compare/v2.6.2...v2.6.3) (2021-03-05)

### Bug Fixes

* **playback-watcher:** Skip over playback gaps that occur in the beginning of streams ([#1085](https://github.com/videojs/http-streaming/issues/1085)) ([ccd9352](https://github.com/videojs/http-streaming/commit/ccd9352))
* Add exclude reason and skip duplicate playlist-unchanged ([#1082](https://github.com/videojs/http-streaming/issues/1082)) ([0dceb5b](https://github.com/videojs/http-streaming/commit/0dceb5b))
* prevent changing undefined baseStartTime to NaN ([#1086](https://github.com/videojs/http-streaming/issues/1086)) ([43aa69a](https://github.com/videojs/http-streaming/commit/43aa69a))
* update to mux.js 5.10.0 ([#1089](https://github.com/videojs/http-streaming/issues/1089)) ([1cfdab6](https://github.com/videojs/http-streaming/commit/1cfdab6))

### Chores

* ie 11 demo fixes ([0760d45](https://github.com/videojs/http-streaming/commit/0760d45))
* use deferred scripts for faster demo startup ([#1083](https://github.com/videojs/http-streaming/issues/1083)) ([c348174](https://github.com/videojs/http-streaming/commit/c348174))

<a name="2.6.2"></a>
## [2.6.2](https://github.com/videojs/http-streaming/compare/v2.6.1...v2.6.2) (2021-02-24)

### Bug Fixes

* update to mux.js[@5](https://github.com/5).9.2 and mpd-parser[@0](https://github.com/0).15.4 ([#1081](https://github.com/videojs/http-streaming/issues/1081)) ([f5c060f](https://github.com/videojs/http-streaming/commit/f5c060f))

### Tests

* add playback-min as a unit test type ([#1077](https://github.com/videojs/http-streaming/issues/1077)) ([327a572](https://github.com/videojs/http-streaming/commit/327a572))

<a name="2.6.1"></a>
## [2.6.1](https://github.com/videojs/http-streaming/compare/v2.6.0...v2.6.1) (2021-02-19)

### Bug Fixes

* allow buffer removes when there's no current media info in loader ([#1070](https://github.com/videojs/http-streaming/issues/1070)) ([97ab712](https://github.com/videojs/http-streaming/commit/97ab712))
* live dash segment changes should be considered a playlist update ([#1065](https://github.com/videojs/http-streaming/issues/1065)) ([1ce7838](https://github.com/videojs/http-streaming/commit/1ce7838))
* sometimes subtitlesTrack_.cues is null ([#1073](https://github.com/videojs/http-streaming/issues/1073)) ([6778ca1](https://github.com/videojs/http-streaming/commit/6778ca1))
* unbreak the minified build by updating rollup-plugin-worker-factory ([#1072](https://github.com/videojs/http-streaming/issues/1072)) ([e583b26](https://github.com/videojs/http-streaming/commit/e583b26))

### Chores

* mirror player.src on the demo page using sourceset ([#1071](https://github.com/videojs/http-streaming/issues/1071)) ([fee7309](https://github.com/videojs/http-streaming/commit/fee7309))

### Documentation

* **README:** fix useBandwidthFromLocalStorage and limitRenditionByPlayerDimensions ([#1075](https://github.com/videojs/http-streaming/issues/1075)) ([cf2efcb](https://github.com/videojs/http-streaming/commit/cf2efcb))

<a name="2.6.0"></a>
# [2.6.0](https://github.com/videojs/http-streaming/compare/v2.5.0...v2.6.0) (2021-02-11)

### Features

* allow xhr override globally, for super advanced use cases only ([#1059](https://github.com/videojs/http-streaming/issues/1059)) ([6279675](https://github.com/videojs/http-streaming/commit/6279675))
* expose m3u8-parser logging in debug log ([#1048](https://github.com/videojs/http-streaming/issues/1048)) ([0e8bd4b](https://github.com/videojs/http-streaming/commit/0e8bd4b))

### Bug Fixes

* do not request manifests until play when preload is none ([#1060](https://github.com/videojs/http-streaming/issues/1060)) ([49249d5](https://github.com/videojs/http-streaming/commit/49249d5)), closes [#126](https://github.com/videojs/http-streaming/issues/126)
* store `transmuxQueue` and `currentTransmux` on `transmuxer` instead of globally ([#1045](https://github.com/videojs/http-streaming/issues/1045)) ([a34b4da](https://github.com/videojs/http-streaming/commit/a34b4da))
* use a separate ProgramDateTime mapping to player time per timeline ([#1063](https://github.com/videojs/http-streaming/issues/1063)) ([5e9b4f1](https://github.com/videojs/http-streaming/commit/5e9b4f1))
* wait for endedtimeline event from transmuxer when reaching the end of a timeline ([#1058](https://github.com/videojs/http-streaming/issues/1058)) ([b01ab72](https://github.com/videojs/http-streaming/commit/b01ab72))

### Chores

* add legacy avc source ([#1050](https://github.com/videojs/http-streaming/issues/1050)) ([b34a770](https://github.com/videojs/http-streaming/commit/b34a770))
* add pdt test sources ([#1067](https://github.com/videojs/http-streaming/issues/1067)) ([112148b](https://github.com/videojs/http-streaming/commit/112148b))
* better worker build and synchronous web worker ([#1033](https://github.com/videojs/http-streaming/issues/1033)) ([f0732af](https://github.com/videojs/http-streaming/commit/f0732af))

### Documentation

* sample-aes encryption isn't currently supported ([#923](https://github.com/videojs/http-streaming/issues/923)) ([30f9b14](https://github.com/videojs/http-streaming/commit/30f9b14))

### Tests

* for IE11, add colon to timezone in Date strings of PDT mapping tests ([#1068](https://github.com/videojs/http-streaming/issues/1068)) ([f81c5a9](https://github.com/videojs/http-streaming/commit/f81c5a9))

<a name="2.5.0"></a>
# [2.5.0](https://github.com/videojs/http-streaming/compare/v2.4.2...v2.5.0) (2021-01-20)

### Features

* add flag to turn off 708 captions ([#1047](https://github.com/videojs/http-streaming/issues/1047)) ([ab5b4dc](https://github.com/videojs/http-streaming/commit/ab5b4dc))

### Chores

* update [@videojs](https://github.com/videojs)/vhs-utils to v3.0.0 ([#1036](https://github.com/videojs/http-streaming/issues/1036)) ([b072c93](https://github.com/videojs/http-streaming/commit/b072c93))

### Tests

* clear segment transmuxer in media segment request tests ([#1043](https://github.com/videojs/http-streaming/issues/1043)) ([83057a8](https://github.com/videojs/http-streaming/commit/83057a8))
* don't show QUnit UI in regular test runs ([#1044](https://github.com/videojs/http-streaming/issues/1044)) ([25c7f64](https://github.com/videojs/http-streaming/commit/25c7f64))

<a name="2.4.2"></a>
## [2.4.2](https://github.com/videojs/http-streaming/compare/v2.4.1...v2.4.2) (2021-01-07)

### Bug Fixes

* handle rollover and don't set wrong timing info for segments with high PTS/DTS values ([#1040](https://github.com/videojs/http-streaming/issues/1040)) ([9919b85](https://github.com/videojs/http-streaming/commit/9919b85))

<a name="2.4.1"></a>
## [2.4.1](https://github.com/videojs/http-streaming/compare/v2.4.0...v2.4.1) (2020-12-22)

### Bug Fixes

* if a playlist was last requested less than half target duration, delay retry ([#1038](https://github.com/videojs/http-streaming/issues/1038)) ([2e237ee](https://github.com/videojs/http-streaming/commit/2e237ee))
* programmatically create Config getters/setters ([8454da5](https://github.com/videojs/http-streaming/commit/8454da5))

### Chores

* **demo:** clear type on manual source change ([#1030](https://github.com/videojs/http-streaming/issues/1030)) ([d39276d](https://github.com/videojs/http-streaming/commit/d39276d))
* mark many more sources as working ([#1035](https://github.com/videojs/http-streaming/issues/1035)) ([904153f](https://github.com/videojs/http-streaming/commit/904153f))
* move playback tests to a separate ci run ([#1028](https://github.com/videojs/http-streaming/issues/1028)) ([f1d9f6e](https://github.com/videojs/http-streaming/commit/f1d9f6e))
* remove replace and update packages ([#1031](https://github.com/videojs/http-streaming/issues/1031)) ([0976212](https://github.com/videojs/http-streaming/commit/0976212))

<a name="2.4.0"></a>
# [2.4.0](https://github.com/videojs/http-streaming/compare/v2.3.0...v2.4.0) (2020-12-07)

### Features

* **playback watcher:** Configurable live seekable window ([#997](https://github.com/videojs/http-streaming/issues/997)) ([ad5c270](https://github.com/videojs/http-streaming/commit/ad5c270))
* log on mislabeled segment durations for HLS ([#1010](https://github.com/videojs/http-streaming/issues/1010)) ([4109a7f](https://github.com/videojs/http-streaming/commit/4109a7f))
* update to mux.js 5.7.0 ([#1014](https://github.com/videojs/http-streaming/issues/1014)) ([5f14909](https://github.com/videojs/http-streaming/commit/5f14909)), closes [#1001](https://github.com/videojs/http-streaming/issues/1001) [#909](https://github.com/videojs/http-streaming/issues/909)

### Bug Fixes

* abort all loaders on earlyabort ([#965](https://github.com/videojs/http-streaming/issues/965)) ([e7cb63a](https://github.com/videojs/http-streaming/commit/e7cb63a))
* don't save bandwidth and throughput for really small segments ([#1024](https://github.com/videojs/http-streaming/issues/1024)) ([a29e241](https://github.com/videojs/http-streaming/commit/a29e241))
* filter out unsupported subtitles for dash ([#962](https://github.com/videojs/http-streaming/issues/962)) ([124834a](https://github.com/videojs/http-streaming/commit/124834a))
* keep running the minimumUpdatePeriod unless cancelled or changed ([#1016](https://github.com/videojs/http-streaming/issues/1016)) ([f7b528c](https://github.com/videojs/http-streaming/commit/f7b528c))
* prevent double source buffer ready on IE11 ([#1015](https://github.com/videojs/http-streaming/issues/1015)) ([b1c2969](https://github.com/videojs/http-streaming/commit/b1c2969))
* remove duplicate cues with same time interval and text ([#1005](https://github.com/videojs/http-streaming/issues/1005)) ([6db2b6a](https://github.com/videojs/http-streaming/commit/6db2b6a))
* support tracks with id 0 for fmp4 playlists ([#1018](https://github.com/videojs/http-streaming/issues/1018)) ([bf63692](https://github.com/videojs/http-streaming/commit/bf63692))
* Wait for EME initialization before appending content ([#1002](https://github.com/videojs/http-streaming/issues/1002)) ([93132b7](https://github.com/videojs/http-streaming/commit/93132b7))
* when changing renditions over a discontinuity, don't use buffered end as segment start ([#1023](https://github.com/videojs/http-streaming/issues/1023)) ([40caa45](https://github.com/videojs/http-streaming/commit/40caa45))
* **experimentalBufferBasedABR:** start ABR timer on main playlist load ([#1026](https://github.com/videojs/http-streaming/issues/1026)) ([27de9a5](https://github.com/videojs/http-streaming/commit/27de9a5)), closes [#1025](https://github.com/videojs/http-streaming/issues/1025)

### Chores

* add multiple soon-to-work sources ([#1007](https://github.com/videojs/http-streaming/issues/1007)) ([030469f](https://github.com/videojs/http-streaming/commit/030469f))
* don't run tests on release ([#1006](https://github.com/videojs/http-streaming/issues/1006)) ([d13b737](https://github.com/videojs/http-streaming/commit/d13b737))
* skip duplicate ci workflows ([#1021](https://github.com/videojs/http-streaming/issues/1021)) ([20cc4a3](https://github.com/videojs/http-streaming/commit/20cc4a3))
* switch from travis to github actions for ci ([#989](https://github.com/videojs/http-streaming/issues/989)) ([c9b195b](https://github.com/videojs/http-streaming/commit/c9b195b))
* **demo page:** add an overrideNative button (default on) ([#1027](https://github.com/videojs/http-streaming/issues/1027)) ([197daab](https://github.com/videojs/http-streaming/commit/197daab))

### Code Refactoring

* Add a better distinction between master and child dash loaders ([#992](https://github.com/videojs/http-streaming/issues/992)) ([56592bc](https://github.com/videojs/http-streaming/commit/56592bc))
* add sidx segments to playlist object instead of re-parsing xml ([#994](https://github.com/videojs/http-streaming/issues/994)) ([e41f856](https://github.com/videojs/http-streaming/commit/e41f856))
* unify sidx/master/error request logic ([#998](https://github.com/videojs/http-streaming/issues/998)) ([fe57e60](https://github.com/videojs/http-streaming/commit/fe57e60))

### Tests

* fix tests on firefox 83 ([#1004](https://github.com/videojs/http-streaming/issues/1004)) ([00d9b1d](https://github.com/videojs/http-streaming/commit/00d9b1d))

<a name="2.3.0"></a>
# [2.3.0](https://github.com/videojs/http-streaming/compare/v2.2.0...v2.3.0) (2020-11-05)

### Features

* add experimental buffer based ABR ([#886](https://github.com/videojs/http-streaming/issues/886)) ([a05d032](https://github.com/videojs/http-streaming/commit/a05d032))

### Bug Fixes

* appendsdone abort and handle multiple id3 sections. ([#971](https://github.com/videojs/http-streaming/issues/971)) ([329d50a](https://github.com/videojs/http-streaming/commit/329d50a))
* check tech error before pause loaders ([#969](https://github.com/videojs/http-streaming/issues/969)) ([0c7b2cb](https://github.com/videojs/http-streaming/commit/0c7b2cb))
* inline json version ([#967](https://github.com/videojs/http-streaming/issues/967)) ([326ce1c](https://github.com/videojs/http-streaming/commit/326ce1c))
* **experimentalBufferBasedABR:** call selectPlaylist and change media on an interval ([#978](https://github.com/videojs/http-streaming/issues/978)) ([200c87b](https://github.com/videojs/http-streaming/commit/200c87b)), closes [#886](https://github.com/videojs/http-streaming/issues/886) [#966](https://github.com/videojs/http-streaming/issues/966) [#964](https://github.com/videojs/http-streaming/issues/964)
* only prevent audio group creation if no other playlists are using it ([#981](https://github.com/videojs/http-streaming/issues/981)) ([645e979](https://github.com/videojs/http-streaming/commit/645e979))
* **playback-watcher:** ignore subtitles ([#980](https://github.com/videojs/http-streaming/issues/980)) ([ca7655e](https://github.com/videojs/http-streaming/commit/ca7655e))

### Chores

* **package:** update aes-decrypter, m3u8 and mpd parser for vhs-utils ([#988](https://github.com/videojs/http-streaming/issues/988)) ([c31dee2](https://github.com/videojs/http-streaming/commit/c31dee2))

### Tests

* **playback-watcher:** subtitle test refactor ([#986](https://github.com/videojs/http-streaming/issues/986)) ([0f66d8e](https://github.com/videojs/http-streaming/commit/0f66d8e)), closes [#980](https://github.com/videojs/http-streaming/issues/980)

<a name="2.2.0"></a>
# [2.2.0](https://github.com/videojs/http-streaming/compare/v2.1.0...v2.2.0) (2020-09-25)

### Features

* default handleManfiestRedirect to true ([#927](https://github.com/videojs/http-streaming/issues/927)) ([556321f](https://github.com/videojs/http-streaming/commit/556321f))
* support MPD.Location ([#926](https://github.com/videojs/http-streaming/issues/926)) ([c4a43d7](https://github.com/videojs/http-streaming/commit/c4a43d7))
* Update minimumUpdatePeriod handling ([#942](https://github.com/videojs/http-streaming/issues/942)) ([8648e76](https://github.com/videojs/http-streaming/commit/8648e76))

### Bug Fixes

* audio groups with the same uri as media do not count ([#952](https://github.com/videojs/http-streaming/issues/952)) ([3927c0c](https://github.com/videojs/http-streaming/commit/3927c0c))
* dash manifest not refreshed if only some playlists are updated ([#949](https://github.com/videojs/http-streaming/issues/949)) ([31d3441](https://github.com/videojs/http-streaming/commit/31d3441))
* detect demuxed video underflow gaps ([#948](https://github.com/videojs/http-streaming/issues/948)) ([d0ef298](https://github.com/videojs/http-streaming/commit/d0ef298))
* MPD not refreshed if minimumUpdatePeriod is 0 ([#954](https://github.com/videojs/http-streaming/issues/954)) ([3a0682f](https://github.com/videojs/http-streaming/commit/3a0682f)), closes [#942](https://github.com/videojs/http-streaming/issues/942)
* noop vtt segment loader handle data ([#959](https://github.com/videojs/http-streaming/issues/959)) ([d1dcd7b](https://github.com/videojs/http-streaming/commit/d1dcd7b))
* report the correct buffered regardless of playlist change ([#950](https://github.com/videojs/http-streaming/issues/950)) ([043ccc6](https://github.com/videojs/http-streaming/commit/043ccc6))
* Throw a player error when trying to play DRM content without eme ([#938](https://github.com/videojs/http-streaming/issues/938)) ([ce4d6fd](https://github.com/videojs/http-streaming/commit/ce4d6fd))
* use playlist NAME when available as its ID ([#929](https://github.com/videojs/http-streaming/issues/929)) ([2269464](https://github.com/videojs/http-streaming/commit/2269464))
* use TIME_FUDGE_FACTOR rather than rounding by decimal digits ([#881](https://github.com/videojs/http-streaming/issues/881)) ([7eb112d](https://github.com/videojs/http-streaming/commit/7eb112d))

### Chores

* **package:** remove engine check in pkcs7 ([#947](https://github.com/videojs/http-streaming/issues/947)) ([89392fa](https://github.com/videojs/http-streaming/commit/89392fa))
* mark angel one dash subs as broken ([#956](https://github.com/videojs/http-streaming/issues/956)) ([56a0970](https://github.com/videojs/http-streaming/commit/56a0970))
* mediaConfig_ -> staringMediaInfo_, startingMedia_ -> currentMediaInfo_ ([#953](https://github.com/videojs/http-streaming/issues/953)) ([8801d1c](https://github.com/videojs/http-streaming/commit/8801d1c))
* playlist selector logging ([#921](https://github.com/videojs/http-streaming/issues/921)) ([ccdbaef](https://github.com/videojs/http-streaming/commit/ccdbaef))
* update m3u8-parser to v4.4.3 ([#928](https://github.com/videojs/http-streaming/issues/928)) ([af5b4ee](https://github.com/videojs/http-streaming/commit/af5b4ee))

### Reverts

* fix: use playlist NAME when available as its ID ([#929](https://github.com/videojs/http-streaming/issues/929)) ([#957](https://github.com/videojs/http-streaming/issues/957)) ([fe8376b](https://github.com/videojs/http-streaming/commit/fe8376b))

<a name="2.1.0"></a>
# [2.1.0](https://github.com/videojs/http-streaming/compare/v2.0.0...v2.1.0) (2020-07-28)

### Features

* Easier manual playlist switching, add codecs to renditions ([#850](https://github.com/videojs/http-streaming/issues/850)) ([f60fa1f](https://github.com/videojs/http-streaming/commit/f60fa1f))
* exclude all incompatable browser/muxer codecs ([#903](https://github.com/videojs/http-streaming/issues/903)) ([2d0f0d7](https://github.com/videojs/http-streaming/commit/2d0f0d7))
* expose canChangeType on the VHS property ([#911](https://github.com/videojs/http-streaming/issues/911)) ([a4ab285](https://github.com/videojs/http-streaming/commit/a4ab285))
* let back buffer be configurable ([8c96e6c](https://github.com/videojs/http-streaming/commit/8c96e6c))
* Support codecs switching when possible via sourceBuffer.changeType  ([#841](https://github.com/videojs/http-streaming/issues/841)) ([267cc34](https://github.com/videojs/http-streaming/commit/267cc34))

### Bug Fixes

* always append init segment after trackinfo change ([#913](https://github.com/videojs/http-streaming/issues/913)) ([ea3650a](https://github.com/videojs/http-streaming/commit/ea3650a))
* cleanup mediasource listeners on dispose ([#871](https://github.com/videojs/http-streaming/issues/871)) ([e50f4c9](https://github.com/videojs/http-streaming/commit/e50f4c9))
* do not try to use unsupported audio ([#896](https://github.com/videojs/http-streaming/issues/896)) ([7711b26](https://github.com/videojs/http-streaming/commit/7711b26))
* do not use remove source buffer on ie 11 ([#904](https://github.com/videojs/http-streaming/issues/904)) ([1ab0f07](https://github.com/videojs/http-streaming/commit/1ab0f07))
* do not wait for audio appends for muxed segments ([#894](https://github.com/videojs/http-streaming/issues/894)) ([406cbcd](https://github.com/videojs/http-streaming/commit/406cbcd))
* Fixed issue with MPEG-Dash MPD Playlist Finalisation during Live Play. ([#874](https://github.com/videojs/http-streaming/issues/874)) ([c807930](https://github.com/videojs/http-streaming/commit/c807930))
* handle null return value from CaptionParser.parse ([#890](https://github.com/videojs/http-streaming/issues/890)) ([7b8fff2](https://github.com/videojs/http-streaming/commit/7b8fff2)), closes [#863](https://github.com/videojs/http-streaming/issues/863)
* have reloadSourceOnError get src from player ([#893](https://github.com/videojs/http-streaming/issues/893)) ([1e50bc5](https://github.com/videojs/http-streaming/commit/1e50bc5)), closes [videojs/video.js#6744](https://github.com/videojs/video.js/issues/6744)
* initialize EME for all playlists and PSSH values ([#872](https://github.com/videojs/http-streaming/issues/872)) ([e0e497f](https://github.com/videojs/http-streaming/commit/e0e497f))
* more conservative stalled download check, better logging ([#884](https://github.com/videojs/http-streaming/issues/884)) ([615e77f](https://github.com/videojs/http-streaming/commit/615e77f))
* pause/abort loaders before an exclude, preventing bad appends ([#902](https://github.com/videojs/http-streaming/issues/902)) ([c9126e1](https://github.com/videojs/http-streaming/commit/c9126e1))
* stop alt loaders on main mediachanging to prevent append race ([#895](https://github.com/videojs/http-streaming/issues/895)) ([8690c78](https://github.com/videojs/http-streaming/commit/8690c78))
* Support aac data with or without id3 tags by using mux.js[@5](https://github.com/5).6.6 ([#899](https://github.com/videojs/http-streaming/issues/899)) ([9c742ce](https://github.com/videojs/http-streaming/commit/9c742ce))
* Use revokeObjectURL dispose for created MSE blob urls ([#849](https://github.com/videojs/http-streaming/issues/849)) ([ca73cac](https://github.com/videojs/http-streaming/commit/ca73cac))
* Wait for sourceBuffer creation so drm setup uses valid codecs ([#878](https://github.com/videojs/http-streaming/issues/878)) ([f879563](https://github.com/videojs/http-streaming/commit/f879563))

### Chores

* Add vhs & mpc (vhs.masterPlaylistController_) to window of index.html ([#875](https://github.com/videojs/http-streaming/issues/875)) ([bab61d6](https://github.com/videojs/http-streaming/commit/bab61d6))
* **demo:** add a representations selector to the demo page ([#901](https://github.com/videojs/http-streaming/issues/901)) ([0a54ae2](https://github.com/videojs/http-streaming/commit/0a54ae2))
* fix tears of steal playready on the demo page ([#915](https://github.com/videojs/http-streaming/issues/915)) ([29a10d0](https://github.com/videojs/http-streaming/commit/29a10d0))
* keep window vhs/mpc up to date on source switch ([#883](https://github.com/videojs/http-streaming/issues/883)) ([3ba85fd](https://github.com/videojs/http-streaming/commit/3ba85fd))
* update DASH stream urls ([#918](https://github.com/videojs/http-streaming/issues/918)) ([902c2a5](https://github.com/videojs/http-streaming/commit/902c2a5))
* update local video.js ([#876](https://github.com/videojs/http-streaming/issues/876)) ([c2cc9aa](https://github.com/videojs/http-streaming/commit/c2cc9aa))
* use playready license server ([#916](https://github.com/videojs/http-streaming/issues/916)) ([6728837](https://github.com/videojs/http-streaming/commit/6728837))

### Code Refactoring

* remove duplicate bufferIntersection code in util/buffer.js ([#880](https://github.com/videojs/http-streaming/issues/880)) ([0ca43bd](https://github.com/videojs/http-streaming/commit/0ca43bd))
* simplify setupEmeOptions and add tests ([#869](https://github.com/videojs/http-streaming/issues/869)) ([e3921ed](https://github.com/videojs/http-streaming/commit/e3921ed))

<a name="2.0.0"></a>
# [2.0.0](https://github.com/videojs/http-streaming/compare/v2.0.0-rc.2...v2.0.0) (2020-06-16)

### Features

* add external vhs properties and deprecate hls and dash references ([#859](https://github.com/videojs/http-streaming/issues/859)) ([22af0b2](https://github.com/videojs/http-streaming/commit/22af0b2))
* Use VHS playback on any non-Safari browser ([#843](https://github.com/videojs/http-streaming/issues/843)) ([225d127](https://github.com/videojs/http-streaming/commit/225d127))

### Chores

* fix demo page on firefox, always use vhs on safari ([#851](https://github.com/videojs/http-streaming/issues/851)) ([d567b7d](https://github.com/videojs/http-streaming/commit/d567b7d))
* **stats:** update vhs usage in the stats page ([#867](https://github.com/videojs/http-streaming/issues/867)) ([4dda42a](https://github.com/videojs/http-streaming/commit/4dda42a))

### Code Refactoring

* Move caption parser to webworker, saving 5732b offloading work ([#863](https://github.com/videojs/http-streaming/issues/863)) ([491d194](https://github.com/videojs/http-streaming/commit/491d194))
* remove aes-decrypter objects from Hls saving 1415gz bytes ([#860](https://github.com/videojs/http-streaming/issues/860)) ([a4f8302](https://github.com/videojs/http-streaming/commit/a4f8302))

### Documentation

* add supported features doc ([#848](https://github.com/videojs/http-streaming/issues/848)) ([38f5860](https://github.com/videojs/http-streaming/commit/38f5860))

### Reverts

* "fix: Use middleware and a wrapped function for seeking instead of relying on unreliable 'seeking' events ([#161](https://github.com/videojs/http-streaming/issues/161))"([#856](https://github.com/videojs/http-streaming/issues/856)) ([1165f8e](https://github.com/videojs/http-streaming/commit/1165f8e))


### BREAKING CHANGES

* The Hls object which was exposed on videojs no longer has Decrypter, AsyncStream, and decrypt from aes-decrypter.

<a name="1.10.2"></a>
## [1.10.2](https://github.com/videojs/http-streaming/compare/v1.10.1...v1.10.2) (2019-05-13)

### Bug Fixes

* clear the blacklist for other playlists if final rendition errors ([#479](https://github.com/videojs/http-streaming/issues/479)) ([fe3b378](https://github.com/videojs/http-streaming/commit/fe3b378)), closes [#396](https://github.com/videojs/http-streaming/issues/396) [#471](https://github.com/videojs/http-streaming/issues/471)
* **development:** rollup watch, via `npm run watch`, should work for es/cjs ([#484](https://github.com/videojs/http-streaming/issues/484)) ([ad6f292](https://github.com/videojs/http-streaming/commit/ad6f292))
* **HLSe:** slice keys properly on IE11 ([#506](https://github.com/videojs/http-streaming/issues/506)) ([681cd6f](https://github.com/videojs/http-streaming/commit/681cd6f))
* **package:** update mpd-parser to version 0.8.1 🚀 ([#490](https://github.com/videojs/http-streaming/issues/490)) ([a49ad3a](https://github.com/videojs/http-streaming/commit/a49ad3a))
* **package:** update mux.js to version 5.1.2 🚀 ([#477](https://github.com/videojs/http-streaming/issues/477)) ([57a38e9](https://github.com/videojs/http-streaming/commit/57a38e9)), closes [#503](https://github.com/videojs/http-streaming/issues/503) [#504](https://github.com/videojs/http-streaming/issues/504)
* **source-updater:** run callbacks after setting timestampOffset ([#480](https://github.com/videojs/http-streaming/issues/480)) ([6ecf859](https://github.com/videojs/http-streaming/commit/6ecf859))
* livestream timeout issues ([#469](https://github.com/videojs/http-streaming/issues/469)) ([cf3fafc](https://github.com/videojs/http-streaming/commit/cf3fafc)), closes [segment#16](https://github.com/segment/issues/16) [segment#15](https://github.com/segment/issues/15) [segment#16](https://github.com/segment/issues/16) [segment#15](https://github.com/segment/issues/15) [segment#16](https://github.com/segment/issues/16)
* remove both vttjs listeners to prevent leaking one of them ([#495](https://github.com/videojs/http-streaming/issues/495)) ([1db1e72](https://github.com/videojs/http-streaming/commit/1db1e72))

### Performance Improvements

* don't enable captionParser for audio or subtitle loaders ([#487](https://github.com/videojs/http-streaming/issues/487)) ([358877f](https://github.com/videojs/http-streaming/commit/358877f))

<a name="1.10.1"></a>
## [1.10.1](https://github.com/videojs/http-streaming/compare/v1.10.0...v1.10.1) (2019-04-16)

### Bug Fixes

* **dash-playlist-loader:** clear out timers on dispose ([#472](https://github.com/videojs/http-streaming/issues/472)) ([2f1c222](https://github.com/videojs/http-streaming/commit/2f1c222))

### Reverts

* "fix: clear the blacklist for other playlists if final rendition errors ([#396](https://github.com/videojs/http-streaming/issues/396))" ([#471](https://github.com/videojs/http-streaming/issues/471)) ([dd55028](https://github.com/videojs/http-streaming/commit/dd55028))

<a name="1.10.0"></a>
# [1.10.0](https://github.com/videojs/http-streaming/compare/v1.9.3...v1.10.0) (2019-04-12)

### Features

* add option to cache encrpytion keys in the player ([#446](https://github.com/videojs/http-streaming/issues/446)) ([599b94d](https://github.com/videojs/http-streaming/commit/599b94d)), closes [#140](https://github.com/videojs/http-streaming/issues/140)
* add support for dash manifests describing sidx boxes ([#455](https://github.com/videojs/http-streaming/issues/455)) ([80dde16](https://github.com/videojs/http-streaming/commit/80dde16))

### Bug Fixes

* clear the blacklist for other playlists if final rendition errors ([#396](https://github.com/videojs/http-streaming/issues/396)) ([6e6c8c2](https://github.com/videojs/http-streaming/commit/6e6c8c2))
* on dispose, don't call abort on SourceBuffer until after remove() has finished ([3806750](https://github.com/videojs/http-streaming/commit/3806750))

### Documentation

* **README:** update broken link to full docs ([#440](https://github.com/videojs/http-streaming/issues/440)) ([fbd615c](https://github.com/videojs/http-streaming/commit/fbd615c))

<a name="1.9.3"></a>
## [1.9.3](https://github.com/videojs/http-streaming/compare/v1.9.2...v1.9.3) (2019-03-21)

### Bug Fixes

* **id3:** ignore unsupported id3 frames ([#437](https://github.com/videojs/http-streaming/issues/437)) ([7040b7d](https://github.com/videojs/http-streaming/commit/7040b7d)), closes [videojs/video.js#5823](https://github.com/videojs/video.js/issues/5823)

### Documentation

* add diagrams for playlist loaders ([#426](https://github.com/videojs/http-streaming/issues/426)) ([52201f9](https://github.com/videojs/http-streaming/commit/52201f9))

<a name="1.9.2"></a>
## [1.9.2](https://github.com/videojs/http-streaming/compare/v1.9.1...v1.9.2) (2019-03-14)

### Bug Fixes

* expose `custom` segment property in the segment metadata track ([#429](https://github.com/videojs/http-streaming/issues/429)) ([17510da](https://github.com/videojs/http-streaming/commit/17510da))

<a name="1.9.1"></a>
## [1.9.1](https://github.com/videojs/http-streaming/compare/v1.9.0...v1.9.1) (2019-03-05)

### Bug Fixes

* fix for streams that would occasionally never fire an `ended` event ([fc09926](https://github.com/videojs/http-streaming/commit/fc09926))
* Fix video playback freezes caused by not using absolute current time ([#401](https://github.com/videojs/http-streaming/issues/401)) ([957ecfd](https://github.com/videojs/http-streaming/commit/957ecfd))
* only fire seekablechange when values of seekable ranges actually change ([#415](https://github.com/videojs/http-streaming/issues/415)) ([a4c056e](https://github.com/videojs/http-streaming/commit/a4c056e))
* Prevent infinite buffering at the start of looped video on edge ([#392](https://github.com/videojs/http-streaming/issues/392)) ([b6d1b97](https://github.com/videojs/http-streaming/commit/b6d1b97))

### Code Refactoring

* align DashPlaylistLoader closer to PlaylistLoader states ([#386](https://github.com/videojs/http-streaming/issues/386)) ([5d80fe7](https://github.com/videojs/http-streaming/commit/5d80fe7))

<a name="1.9.0"></a>
# [1.9.0](https://github.com/videojs/http-streaming/compare/v1.8.0...v1.9.0) (2019-02-07)

### Features

* Use exposed transmuxer time modifications for more accurate conversion between program and player times ([#371](https://github.com/videojs/http-streaming/issues/371)) ([41df5c0](https://github.com/videojs/http-streaming/commit/41df5c0))

### Bug Fixes

* m3u8 playlist is not updating when only endList changes ([#373](https://github.com/videojs/http-streaming/issues/373)) ([c7d1306](https://github.com/videojs/http-streaming/commit/c7d1306))
* Prevent exceptions from being thrown by the MediaSource ([#389](https://github.com/videojs/http-streaming/issues/389)) ([8c06366](https://github.com/videojs/http-streaming/commit/8c06366))

### Chores

* Update mux.js to the latest version 🚀 ([#397](https://github.com/videojs/http-streaming/issues/397)) ([38ec2a5](https://github.com/videojs/http-streaming/commit/38ec2a5))

### Tests

* added test for playlist not updating when only endList changes ([#394](https://github.com/videojs/http-streaming/issues/394)) ([39d0be2](https://github.com/videojs/http-streaming/commit/39d0be2))

<a name="1.8.0"></a>
# [1.8.0](https://github.com/videojs/http-streaming/compare/v1.7.0...v1.8.0) (2019-01-10)

### Features

* expose custom M3U8 mapper API ([#325](https://github.com/videojs/http-streaming/issues/325)) ([609beb3](https://github.com/videojs/http-streaming/commit/609beb3))

### Bug Fixes

* **id3:** cuechange event not being triggered on audio-only HLS streams ([#334](https://github.com/videojs/http-streaming/issues/334)) ([bab70fd](https://github.com/videojs/http-streaming/commit/bab70fd)), closes [#130](https://github.com/videojs/http-streaming/issues/130)

<a name="1.7.0"></a>
# [1.7.0](https://github.com/videojs/http-streaming/compare/v1.6.0...v1.7.0) (2019-01-04)

### Features

* expose custom M3U8 parser API ([#331](https://github.com/videojs/http-streaming/issues/331)) ([b0643a4](https://github.com/videojs/http-streaming/commit/b0643a4))

<a name="1.6.0"></a>
# [1.6.0](https://github.com/videojs/http-streaming/compare/v1.5.1...v1.6.0) (2018-12-21)

### Features

* Add allowSeeksWithinUnsafeLiveWindow property ([#320](https://github.com/videojs/http-streaming/issues/320)) ([74b28e8](https://github.com/videojs/http-streaming/commit/74b28e8))

### Chores

* add clock.ticks to now async operations in tests ([#315](https://github.com/videojs/http-streaming/issues/315)) ([895c86a](https://github.com/videojs/http-streaming/commit/895c86a))

### Documentation

* Add README entry on DRM and videojs-contrib-eme ([#307](https://github.com/videojs/http-streaming/issues/307)) ([93b6167](https://github.com/videojs/http-streaming/commit/93b6167))

<a name="1.5.1"></a>
## [1.5.1](https://github.com/videojs/http-streaming/compare/v1.5.0...v1.5.1) (2018-12-06)

### Bug Fixes

* added missing manifest information on to segments (EXT-X-PROGRAM-DATE-TIME) ([#236](https://github.com/videojs/http-streaming/issues/236)) ([a35dd09](https://github.com/videojs/http-streaming/commit/a35dd09))
* remove player props on dispose to stop middleware  ([#229](https://github.com/videojs/http-streaming/issues/229)) ([cd13f9f](https://github.com/videojs/http-streaming/commit/cd13f9f))

### Documentation

* add dash to package.json description ([#267](https://github.com/videojs/http-streaming/issues/267)) ([3296c68](https://github.com/videojs/http-streaming/commit/3296c68))
* add documentation for reloadSourceOnError ([#266](https://github.com/videojs/http-streaming/issues/266)) ([7448b37](https://github.com/videojs/http-streaming/commit/7448b37))

<a name="1.5.0"></a>
# [1.5.0](https://github.com/videojs/http-streaming/compare/v1.4.2...v1.5.0) (2018-11-13)

### Features

* Add useBandwidthFromLocalStorage option ([#275](https://github.com/videojs/http-streaming/issues/275)) ([60c88ae](https://github.com/videojs/http-streaming/commit/60c88ae))

### Bug Fixes

* don't wait for requests to finish when encountering an error in media-segment-request ([#286](https://github.com/videojs/http-streaming/issues/286)) ([970e3ce](https://github.com/videojs/http-streaming/commit/970e3ce))
* throttle final playlist reloads when using DASH ([#277](https://github.com/videojs/http-streaming/issues/277)) ([1c2887a](https://github.com/videojs/http-streaming/commit/1c2887a))

<a name="1.4.2"></a>
## [1.4.2](https://github.com/videojs/http-streaming/compare/v1.4.1...v1.4.2) (2018-11-01)

### Chores

* pin to node 8 for now ([#279](https://github.com/videojs/http-streaming/issues/279)) ([f900dc4](https://github.com/videojs/http-streaming/commit/f900dc4))
* update mux.js to 5.0.1 ([#282](https://github.com/videojs/http-streaming/issues/282)) ([af6ee4f](https://github.com/videojs/http-streaming/commit/af6ee4f))

<a name="1.4.1"></a>
## [1.4.1](https://github.com/videojs/http-streaming/compare/v1.4.0...v1.4.1) (2018-10-25)

### Bug Fixes

* **subtitles:** set default property if default and autoselect are both enabled ([#239](https://github.com/videojs/http-streaming/issues/239)) ([ee594e5](https://github.com/videojs/http-streaming/commit/ee594e5))

<a name="1.4.0"></a>
# [1.4.0](https://github.com/videojs/http-streaming/compare/v1.3.1...v1.4.0) (2018-10-24)

### Features

* limited experimental DASH multiperiod support ([#268](https://github.com/videojs/http-streaming/issues/268)) ([a213807](https://github.com/videojs/http-streaming/commit/a213807))
* smoothQualityChange flag ([#235](https://github.com/videojs/http-streaming/issues/235)) ([0e4fdf9](https://github.com/videojs/http-streaming/commit/0e4fdf9))

### Bug Fixes

* immediately setup EME if available ([#263](https://github.com/videojs/http-streaming/issues/263)) ([7577e90](https://github.com/videojs/http-streaming/commit/7577e90))

<a name="1.3.1"></a>
## [1.3.1](https://github.com/videojs/http-streaming/compare/v1.3.0...v1.3.1) (2018-10-15)

### Bug Fixes

* ensure content loops ([#259](https://github.com/videojs/http-streaming/issues/259)) ([26300df](https://github.com/videojs/http-streaming/commit/26300df))

<a name="1.3.0"></a>
# [1.3.0](https://github.com/videojs/http-streaming/compare/v1.2.6...v1.3.0) (2018-10-05)

### Features

* add an option to ignore player size in selection logic ([#238](https://github.com/videojs/http-streaming/issues/238)) ([7ae42b1](https://github.com/videojs/http-streaming/commit/7ae42b1))

### Documentation

* Update CONTRIBUTING.md ([#242](https://github.com/videojs/http-streaming/issues/242)) ([9d83e9d](https://github.com/videojs/http-streaming/commit/9d83e9d))

<a name="1.2.6"></a>
## [1.2.6](https://github.com/videojs/http-streaming/compare/v1.2.5...v1.2.6) (2018-09-21)

### Bug Fixes

* stutter after fast quality change in IE/Edge ([#213](https://github.com/videojs/http-streaming/issues/213)) ([2c0d9b2](https://github.com/videojs/http-streaming/commit/2c0d9b2))

### Documentation

* update issue template to link to the troubleshooting guide ([#215](https://github.com/videojs/http-streaming/issues/215)) ([413f0e8](https://github.com/videojs/http-streaming/commit/413f0e8))
* update README notes for video.js 7 ([#200](https://github.com/videojs/http-streaming/issues/200)) ([d68ce0c](https://github.com/videojs/http-streaming/commit/d68ce0c))
* update troubleshooting guide for Edge/mobile Chrome ([#216](https://github.com/videojs/http-streaming/issues/216)) ([21e5335](https://github.com/videojs/http-streaming/commit/21e5335))

<a name="1.2.5"></a>
## [1.2.5](https://github.com/videojs/http-streaming/compare/v1.2.4...v1.2.5) (2018-08-24)

### Bug Fixes

* fix replay functionality ([#204](https://github.com/videojs/http-streaming/issues/204)) ([fd6be83](https://github.com/videojs/http-streaming/commit/fd6be83))

<a name="1.2.4"></a>
## [1.2.4](https://github.com/videojs/http-streaming/compare/v1.2.3...v1.2.4) (2018-08-13)

### Bug Fixes

* Remove buffered data on fast quality switches ([#113](https://github.com/videojs/http-streaming/issues/113)) ([bc94fbb](https://github.com/videojs/http-streaming/commit/bc94fbb))

<a name="1.2.3"></a>
## [1.2.3](https://github.com/videojs/http-streaming/compare/v1.2.2...v1.2.3) (2018-08-09)

### Chores

* link to minified example in main page ([#189](https://github.com/videojs/http-streaming/issues/189)) ([15a7f92](https://github.com/videojs/http-streaming/commit/15a7f92))
* use netlify for easier testing ([#188](https://github.com/videojs/http-streaming/issues/188)) ([d2e0d35](https://github.com/videojs/http-streaming/commit/d2e0d35))

<a name="1.2.2"></a>
## [1.2.2](https://github.com/videojs/http-streaming/compare/v1.2.1...v1.2.2) (2018-08-07)

### Bug Fixes

* typeof minification ([#182](https://github.com/videojs/http-streaming/issues/182)) ([7c68335](https://github.com/videojs/http-streaming/commit/7c68335))
* Use middleware and a wrapped function for seeking instead of relying on unreliable 'seeking' events ([#161](https://github.com/videojs/http-streaming/issues/161)) ([6c68761](https://github.com/videojs/http-streaming/commit/6c68761))

### Chores

* add logo ([#184](https://github.com/videojs/http-streaming/issues/184)) ([a55626c](https://github.com/videojs/http-streaming/commit/a55626c))

### Documentation

* add note for Safari captions error ([#174](https://github.com/videojs/http-streaming/issues/174)) ([7b03530](https://github.com/videojs/http-streaming/commit/7b03530))

### Tests

* add support for real segments in tests ([#178](https://github.com/videojs/http-streaming/issues/178)) ([2b07fca](https://github.com/videojs/http-streaming/commit/2b07fca))

<a name="1.2.1"></a>
## [1.2.1](https://github.com/videojs/http-streaming/compare/v1.2.0...v1.2.1) (2018-07-17)

### Bug Fixes

* convert non-latin characters in IE ([#157](https://github.com/videojs/http-streaming/issues/157)) ([17678fb](https://github.com/videojs/http-streaming/commit/17678fb))

<a name="1.2.0"></a>
# [1.2.0](https://github.com/videojs/http-streaming/compare/v1.1.0...v1.2.0) (2018-07-16)

### Features

* **captions:** write in-band captions from DASH fmp4 segments to the textTrack API ([#108](https://github.com/videojs/http-streaming/issues/108)) ([7c11911](https://github.com/videojs/http-streaming/commit/7c11911))

### Chores

* add welcome bot config from video.js ([#150](https://github.com/videojs/http-streaming/issues/150)) ([922cfee](https://github.com/videojs/http-streaming/commit/922cfee))

<a name="1.1.0"></a>
# [1.1.0](https://github.com/videojs/http-streaming/compare/v1.0.2...v1.1.0) (2018-06-06)

### Features

* Utilize option to override native on tech ([#76](https://github.com/videojs/http-streaming/issues/76)) ([5c7ab4c](https://github.com/videojs/http-streaming/commit/5c7ab4c))

### Chores

* update tests and pages for video.js 7 ([#102](https://github.com/videojs/http-streaming/issues/102)) ([d6f5005](https://github.com/videojs/http-streaming/commit/d6f5005))

<a name="1.0.2"></a>
## [1.0.2](https://github.com/videojs/http-streaming/compare/v1.0.1...v1.0.2) (2018-05-17)

### Bug Fixes

* make project Video.js 7 ready ([#92](https://github.com/videojs/http-streaming/issues/92)) ([decad87](https://github.com/videojs/http-streaming/commit/decad87))
* make sure that es build is babelified ([#97](https://github.com/videojs/http-streaming/issues/97)) ([5f0428d](https://github.com/videojs/http-streaming/commit/5f0428d))

### Documentation

* update documentation with a glossary and intro page, added DASH background ([#94](https://github.com/videojs/http-streaming/issues/94)) ([4b0fde9](https://github.com/videojs/http-streaming/commit/4b0fde9))

<a name="1.0.1"></a>
## [1.0.1](https://github.com/videojs/http-streaming/compare/v1.0.0...v1.0.1) (2018-04-12)

### Bug Fixes

* minified build ([#84](https://github.com/videojs/http-streaming/issues/84)) ([2402ac6](https://github.com/videojs/http-streaming/commit/2402ac6))

<a name="1.0.0"></a>
# [1.0.0](https://github.com/videojs/http-streaming/compare/v0.9.0...v1.0.0) (2018-04-10)

### Chores

* sync videojs-contrib-hls updates ([#75](https://github.com/videojs/http-streaming/issues/75)) ([9223588](https://github.com/videojs/http-streaming/commit/9223588))
* update the aes-decrypter ([#71](https://github.com/videojs/http-streaming/issues/71)) ([27ed914](https://github.com/videojs/http-streaming/commit/27ed914))

### Documentation

* update docs for overrideNative ([#77](https://github.com/videojs/http-streaming/issues/77)) ([98ca6d3](https://github.com/videojs/http-streaming/commit/98ca6d3))
* update known issues for fmp4 captions ([#79](https://github.com/videojs/http-streaming/issues/79)) ([c418301](https://github.com/videojs/http-streaming/commit/c418301))

<a name="0.9.0"></a>
# [0.9.0](https://github.com/videojs/http-streaming/compare/v0.8.0...v0.9.0) (2018-03-30)

### Features

* support in-manifest DRM data ([#60](https://github.com/videojs/http-streaming/issues/60)) ([a1cad82](https://github.com/videojs/http-streaming/commit/a1cad82))

<a name="0.8.0"></a>
# [0.8.0](https://github.com/videojs/http-streaming/compare/v0.7.2...v0.8.0) (2018-03-30)

### Code Refactoring

* export corrections ([#68](https://github.com/videojs/http-streaming/issues/68)) ([aab3b90](https://github.com/videojs/http-streaming/commit/aab3b90))
* use rollup for build ([#69](https://github.com/videojs/http-streaming/issues/69)) ([c28c25c](https://github.com/videojs/http-streaming/commit/c28c25c))

# 0.7.0
* feat: Live support for DASH

# 0.6.1
* use webwackify for webworkers to support webpack bundle ([#50](https://github.com/videojs/http-streaming/pull/45))

# 0.5.3
* fix: program date time handling ([#45](https://github.com/videojs/http-streaming/pull/45))
  * update m3u8-parser to v4.2.0
  * use segment program date time info
* feat: Adding support for segments in Period and Representation ([#47](https://github.com/videojs/http-streaming/pull/47))
* wait for both main and audio loaders for endOfStream if main starting media unknown ([#44](https://github.com/videojs/http-streaming/pull/44))

# 0.5.2
* add debug logging statement for seekable updates ([#40](https://github.com/videojs/http-streaming/pull/40))

# 0.5.1
* Fix audio only streams with EXT-X-MEDIA tags ([#34](https://github.com/videojs/http-streaming/pull/34))
* Merge videojs-contrib-hls master into http-streaming master ([#35](https://github.com/videojs/http-streaming/pull/35))
  * Update sinon to 1.10.3=
  * Update videojs-contrib-quality-levels to ^2.0.4
  * Fix test for event handler cleanup on dispose by calling event handling methods
* fix: Don't reset eme options ([#32](https://github.com/videojs/http-streaming/pull/32))

# 0.5.0
* update mpd-parser to support more segment list types ([#27](https://github.com/videojs/http-streaming/issues/27))

# 0.4.0
* Removed Flash support ([#15](https://github.com/videojs/http-streaming/issues/15))
* Blacklist playlists not supported by browser media source before initial selection ([#17](https://github.com/videojs/http-streaming/issues/17))

# 0.3.1
* Skip flash-based source handler with DASH sources ([#14](https://github.com/videojs/http-streaming/issues/14))

# 0.3.0
* Added additional properties to the stats object ([#10](https://github.com/videojs/http-streaming/issues/10))

# 0.2.1
* Updated the mpd-parser to fix IE11 DASH support ([#12](https://github.com/videojs/http-streaming/issues/12))

# 0.2.0
* Initial DASH Support ([#8](https://github.com/videojs/http-streaming/issues/8))

# 0.1.0
* Initial release, based on [videojs-contrib-hls 5.12.2](https://github.com/videojs/videojs-contrib-hls)

