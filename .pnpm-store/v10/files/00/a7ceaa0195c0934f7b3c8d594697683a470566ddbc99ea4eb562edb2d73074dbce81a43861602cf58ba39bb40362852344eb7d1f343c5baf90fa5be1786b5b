<a name="6.0.1"></a>
## [6.0.1](https://github.com/videojs/mux.js/compare/v6.0.0...v6.0.1) (2021-12-20)

### Bug Fixes

* fix IE11 by replacing arrow function ([#406](https://github.com/videojs/mux.js/issues/406)) ([47302fe](https://github.com/videojs/mux.js/commit/47302fe))

<a name="6.0.0"></a>
# [6.0.0](https://github.com/videojs/mux.js/compare/v5.14.1...v6.0.0) (2021-11-29)

### Features

* use bigint for 64 bit ints if needed and available. ([#383](https://github.com/videojs/mux.js/issues/383)) ([83779b9](https://github.com/videojs/mux.js/commit/83779b9))

### Chores

* don't run tests on version ([#404](https://github.com/videojs/mux.js/issues/404)) ([45623ea](https://github.com/videojs/mux.js/commit/45623ea))


### BREAKING CHANGES

* In some cases, mux.js will now be returning a BigInt rather than a regular Number value. This means that consumers of this library will need to add checks for BigInt for optimal operation.

<a name="5.14.1"></a>
## [5.14.1](https://github.com/videojs/mux.js/compare/v5.14.0...v5.14.1) (2021-10-14)

### Bug Fixes

* avoid mismatch with avc1 and hvc1 codec ([#400](https://github.com/videojs/mux.js/issues/400)) ([8a58d6e](https://github.com/videojs/mux.js/commit/8a58d6e))
* prevent adding duplicate log listeners on every push after a flush ([#402](https://github.com/videojs/mux.js/issues/402)) ([eb332c1](https://github.com/videojs/mux.js/commit/eb332c1))

<a name="5.14.0"></a>
# [5.14.0](https://github.com/videojs/mux.js/compare/v5.13.0...v5.14.0) (2021-09-21)

### Features

* Add multibyte character support ([#398](https://github.com/videojs/mux.js/issues/398)) ([0849e0a](https://github.com/videojs/mux.js/commit/0849e0a))

<a name="5.13.0"></a>
# [5.13.0](https://github.com/videojs/mux.js/compare/v5.12.2...v5.13.0) (2021-08-24)

### Features

* add firstSequenceNumber option to Transmuxer to start sequence somewhere other than zero ([#395](https://github.com/videojs/mux.js/issues/395)) ([6ff42f4](https://github.com/videojs/mux.js/commit/6ff42f4))

### Chores

* add github release ci action ([#397](https://github.com/videojs/mux.js/issues/397)) ([abe7936](https://github.com/videojs/mux.js/commit/abe7936))
* update ci workflow to fix ci ([#396](https://github.com/videojs/mux.js/issues/396)) ([86cfdca](https://github.com/videojs/mux.js/commit/86cfdca))

<a name="5.12.2"></a>
## [5.12.2](https://github.com/videojs/mux.js/compare/v5.12.1...v5.12.2) (2021-07-14)

### Bug Fixes

* Do not scale width by sarRatio, let decoder handle it via the pasp box ([#393](https://github.com/videojs/mux.js/issues/393)) ([9e9982f](https://github.com/videojs/mux.js/commit/9e9982f))

<a name="5.12.1"></a>
## [5.12.1](https://github.com/videojs/mux.js/compare/v5.12.0...v5.12.1) (2021-07-09)

### Code Refactoring

* rename warn event to log, change console logs to log events ([#392](https://github.com/videojs/mux.js/issues/392)) ([4995603](https://github.com/videojs/mux.js/commit/4995603))

<a name="5.12.0"></a>
# [5.12.0](https://github.com/videojs/mux.js/compare/v5.11.3...v5.12.0) (2021-07-02)

### Features

* add general error/warn/debug log events and log skipped adts data ([#391](https://github.com/videojs/mux.js/issues/391)) ([6588d48](https://github.com/videojs/mux.js/commit/6588d48))

<a name="5.11.3"></a>
## [5.11.3](https://github.com/videojs/mux.js/compare/v5.11.2...v5.11.3) (2021-06-30)

### Bug Fixes

* Prevent skipping frames when we have garbage data between adts sync words ([#390](https://github.com/videojs/mux.js/issues/390)) ([71bac64](https://github.com/videojs/mux.js/commit/71bac64))

<a name="5.11.2"></a>
## [5.11.2](https://github.com/videojs/mux.js/compare/v5.11.1...v5.11.2) (2021-06-24)

### Bug Fixes

* on flush if a pmt has not been emitted and we have one, emit it ([#388](https://github.com/videojs/mux.js/issues/388)) ([67b4aab](https://github.com/videojs/mux.js/commit/67b4aab))

<a name="5.11.1"></a>
## [5.11.1](https://github.com/videojs/mux.js/compare/v5.11.0...v5.11.1) (2021-06-22)

### Bug Fixes

* inspect all program map tables for stream types ([#386](https://github.com/videojs/mux.js/issues/386)) ([bac4da9](https://github.com/videojs/mux.js/commit/bac4da9))

<a name="5.11.0"></a>
# [5.11.0](https://github.com/videojs/mux.js/compare/v5.10.0...v5.11.0) (2021-03-29)

### Features

* parse ctts atom in mp4 inspector ([#379](https://github.com/videojs/mux.js/issues/379)) ([b75a7a4](https://github.com/videojs/mux.js/commit/b75a7a4))
* stss atom parsing ([#380](https://github.com/videojs/mux.js/issues/380)) ([305eb4f](https://github.com/videojs/mux.js/commit/305eb4f))

<a name="5.10.0"></a>
# [5.10.0](https://github.com/videojs/mux.js/compare/v5.9.2...v5.10.0) (2021-03-05)

### Features

* parse edts boxes ([#375](https://github.com/videojs/mux.js/issues/375)) ([989bffd](https://github.com/videojs/mux.js/commit/989bffd))

### Bug Fixes

* Check if baseTimestamp is NaN ([#370](https://github.com/videojs/mux.js/issues/370)) ([b4e61dd](https://github.com/videojs/mux.js/commit/b4e61dd))
* only parse PES packets as PES packets ([#378](https://github.com/videojs/mux.js/issues/378)) ([bb984db](https://github.com/videojs/mux.js/commit/bb984db))

<a name="5.9.2"></a>
## [5.9.2](https://github.com/videojs/mux.js/compare/v5.9.1...v5.9.2) (2021-02-24)

### Features

* add a nodejs binary for transmux via command line ([#366](https://github.com/videojs/mux.js/issues/366)) ([b87ed0f](https://github.com/videojs/mux.js/commit/b87ed0f))

### Bug Fixes

* ts inspect ptsTime/dtsTime typo ([#377](https://github.com/videojs/mux.js/issues/377)) ([112e6e1](https://github.com/videojs/mux.js/commit/112e6e1))

### Chores

* switch to rollup-plugin-data-files ([#369](https://github.com/videojs/mux.js/issues/369)) ([0bb1556](https://github.com/videojs/mux.js/commit/0bb1556))
* update vjsverify to fix publish failure ([cb06bb5](https://github.com/videojs/mux.js/commit/cb06bb5))

<a name="5.9.1"></a>
## [5.9.1](https://github.com/videojs/mux.js/compare/v5.9.0...v5.9.1) (2021-01-20)

### Chores

* **package:** fixup browser field ([#368](https://github.com/videojs/mux.js/issues/368)) ([8926506](https://github.com/videojs/mux.js/commit/8926506))

<a name="5.9.0"></a>
# [5.9.0](https://github.com/videojs/mux.js/compare/v5.8.0...v5.9.0) (2021-01-20)

### Features

* **CaptionStream:** add flag to turn off 708 captions ([#365](https://github.com/videojs/mux.js/issues/365)) ([8a7cdb6](https://github.com/videojs/mux.js/commit/8a7cdb6))

### Chores

* update this project to use the generator ([#352](https://github.com/videojs/mux.js/issues/352)) ([fa920a6](https://github.com/videojs/mux.js/commit/fa920a6))

