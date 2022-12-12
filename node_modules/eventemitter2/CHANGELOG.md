# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

For changes before version 2.2.0, please see the commit history

# [6.4.4] - 2021-02-23

### Added 
- `ETIMEDOUT` code property to timeout errors @HalleyAssist

### Fixed
- prepending listeners to wildcard emitters @Ilrilan

# [6.4.3] - 2020-06-18

### Fixed
- ignoring the `objectify` option in wildcard mode (#265) @DigitalBrainJS
- waitFor listeners leakage issue (#262) @DigitalBrainJS

## [6.4.2] - 2020-05-28

### Fixed
- removed eval usage to avoid Content Security Policy issue (#259) @DigitalBrainJS

## [6.4.1] - 2020-05-10

### Fixed
- increased emitter performance in wildcard mode @DigitalBrainJS

## [6.4.0] - 2020-05-04

### Added

- Symbol events support for simple and wildcard emitters #201 @DigitalBrainJS
- `emitter.hasListeners` method #251 @DigitalBrainJS
- `emitter.listenTo` & `emitter.stopListeningTo` methods for listening to an external event emitter of any kind and propagate its events through itself using optional reducers/filters @DigitalBrainJS
- async listeners for invoking handlers using setImmediate|setTimeout|nextTick (see `async`, `promisify` and `nextTicks` options for subscription methods) @DigitalBrainJS
- Ability for subscription methods to return a listener object to simplify subscription management (see the `objectify` option) @DigitalBrainJS
- micro optimizations for performance reasons @DigitalBrainJS

### Fixed

- Event name/reference normalization for the `this.event` property #162 @DigitalBrainJS
- Bug with data arguments for `Any` listeners #254 @DigitalBrainJS
- `emitter.eventNames` now supports wildcard emitters #214 @DigitalBrainJS

## [6.3.0] - 2020-03-28

### Added
- emitter.getMaxListeners() & EventEmitter2.defaultMaxListeners() @DigitalBrainJS
- EventEmitter2.once for feature parity with EventEmitter.once @DigitalBrainJS

## [6.2.1] - 2020-03-20

### Fixed
- #153 - global scope is no longer defaulted to the `window` variable, now supports workers. @DigitalBrainJS

## [6.2.0] - 2020-03-20

### Added
- `waitFor` method to wait for events using promises @DigitalBrainJS

## [6.1.0] - 2020-03-19

### Added
- `ignoreErrors` errors option in constructor @DigitalBrainJS

## [5.0.1] - 2018-01-09

### Fixed
- Allow `removeAllListeners` to receive `undefined` as an argument. @majames

## [4.1.2] - 2017-07-12
### Added
- Correct listeners and listenersAny typings @cartant

## [4.1.1] - 2017-03-29
### Added
- Use process.emitWarning if it is available (new Node.js) @SimenB

## [4.0.0] - 2017-03-22
### Fixed
- Fix for EventAndListener in typescript definition. @thisboyiscrazy

### Added
- New Node 6 APIs such as `prependListener` and `eventNames`. @sebakerckhof

## [3.0.2] - 2017-03-06
### Fixed
- Fixed `emitAsync` when using `once`. @Moeriki

## [3.0.1] - 2017-02-21
### Changed
- Changed Typescript definition to take array of strings for event name. @thisboyiscrazy

## [3.0.0] - 2017-01-23
### Changed
- Typescript definition now uses `EventEmitter2` instead of `EventEmitter2.eitter`. @gitawego

## [2.2.2] - 2017-01-17
### Fixed
- Typescript definition for `removeAllListeners` can take an array. @gitawego

## [2.2.1] - 2016-11-24
### Added
- Added missing parameters for emitAsync in typescript definition. @stanleytakamatsu

## [2.2.0] - 2016-11-14
### Added
- option to emit name of event that causes memory leak warning. @kwiateusz

### Fixed
- component.json and bower.json got updated with latest version. @kwiateusz
- missing globals in test suite got added in.  @kwiateusz
