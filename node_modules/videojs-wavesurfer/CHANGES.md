# videojs-wavesurfer changelog

## 3.8.0 - 2021/06/15

- Bump required wavesurfer.js version to 5.0.1 or newer


## 3.7.0 - 2021/03/23

- Remove unneccessary resize handler for `fluid` mode (#132)


## 3.6.0 - 2021/03/06

- Bump required wavesurfer.js version to 4.6.0 or newer


## 3.5.0 - 2021/02/01

- Add `formatTime` option and `setFormatTime(impl)` for replacing the default
  `formatTime` implementation (#125)
- Build using webpack 5 (#118)


## 3.4.0 - 2021/01/24

- Trigger error event if peaks file cannot be found (#124)
- Bump required wavesurfer.js version to 4.4.0 or newer


## 3.3.1 - 2020/09/30

- Doc fixes and updated dependencies


## 3.3.0 - 2020/08/10

- Fixed webpack externals configuration: it's no longer needed to use additional webpack
  configuration in React/Angular projects (#109)
- Bump required wavesurfer.js version to 4.0.1 or newer


## 3.2.0 - 2020/05/19

**Backwards-incompatible changes** (when upgrading from a previous version):

- The `exportImage` method now returns an array of `Blob` instances


## 3.1.0 - 2020/05/18

**Backwards-incompatible changes** (when upgrading from a previous version):

- Removed `msDisplayMax` option: use `displayMilliseconds` option instead to include milliseconds
  in the time displays of the player (#91)


## 3.0.4 - 2020/05/16

- Add compatibility for video.js 7.7.6 and newer


## 3.0.3 - 2020/05/13

- Fix multiple players on single page (#101)


## 3.0.2 - 2020/05/12

- Fix hiding `bigPlayButton`


## 3.0.1 - 2020/05/12

- Fix microphone play button


## 3.0.0 - 2020/05/12

- Support for video.js progress control (#93)
- Move documentation into docsify website (#100)
- Bump required video.js version to 7.0.5 or newer
- Bump required wavesurfer.js version to 3.3.3 or newer

**Backwards-incompatible changes** (when upgrading from a previous version):

- Removed `src` option: use `player.src()` instead (#91)
- Removed `src: 'live'` option: enable the wavesurfer.js microphone plugin
  using the config instead


## 2.11.0 - 2019/10/11

- Fix loading peaks data from JSON files (#90)
- Add `style` and `sass` entries to `package.json`
- Specify non-minified videojs-wavesurfer in `main` entry of `package.json`


## 2.10.0 - 2019/09/30

- New `abort` event; triggered when wavesurfer.js fetch call is cancelled (#87)
- Bump required wavesurfer.js version to 3.1.0


## 2.9.0 - 2019/07/14

- Replace usage of `WaveSurfer.util.ajax()` with `WaveSurfer.util.fetchFile()`
- Bump required wavesurfer.js version to 3.0.0
- Disable Picture-In-Picture toggle introduced in video.js 7.6.0 until there is support
  for `canvas` in the Picture-In-Picture browser API


## 2.8.0 - 2019/03/18

- Move event types to separate class
- Bump required wavesurfer.js version to 2.2.1
- Display `video` element in video example (#8)


## 2.7.0 - 2019/02/08

- Fix hiding `playToggle` control
- Fix ES export syntax for `Wavesurfer`


## 2.6.4 - 2019/02/04

- Bump required wavesurfer.js version to 2.1.3 for Safari browser
  improvement


## 2.6.3 - 2018/12/03

- Improve API documentation (#77)


## 2.6.2 - 2018/11/19

- Bump required wavesurfer.js version to 2.1.1 for microphone support in
  the Safari browser
- Examples: add Safari browser workaround (#47)


## 2.6.1 - 2018/10/07

- Fix hiding time controls (#73)


## 2.6.0 - 2018/10/04

- Bump required wavesurfer.js version to 2.1.0 for microphone support in
  the MS Edge browser


## 2.5.1 - 2018/08/08

- Fix minified CSS file (#69)
- Add example showing integration with wavesurfer.js cursor plugin (#67)


## 2.5.0 - 2018/06/03

- Bugfix: replace custom tech for text tracks to fix high CPU usage and issue
  with regular video.js players on the same page (#60, #62)


## 2.4.0 - 2018/05/15

- Add plugin style `vjs-wavesurfer` and prefix all custom plugin styles with
  this selector. This should prevent clashes with regular video.js players
  loaded on the same page. If you were using the old `videojs-wavesurfer` CSS
  class, rename any references to `vjs-wavesurfer`
- Compile SCSS into CSS using webpack


## 2.3.2 - 2018/05/07

- Package library using webpack 4


## 2.3.1 - 2018/04/30

- Make sure plugin is only registered once
- Add `isDestroyed` method
- Add more tests


## 2.3.0 - 2018/04/16

- Package library using webpack (#55)
- Add unit tests using karma/webpack/jasmine (#55)
- Check if wavesurfer exists when calling destroy


## 2.2.2 - 2018/03/06

- Add ability to pass array of peaks data to `load` (#52)


## 2.2.1 - 2018/02/20

- Fix tech for compatibility with video.js 6.7.x (#49 by @mfairchild365)


## 2.2.0 - 2018/01/23

- Support for changing audio output device using `setAudioOutput(deviceId)`
- Added example that shows how to select an audio input device
- Bump required wavesurfer.js version to 2.0.3 for setSinkId feature


## 2.1.4 - 2018/01/14

- Bump required wavesurfer.js version to 2.0.2 for Chrome volume
  deprecation fix


## 2.1.3 - 2017/12/22

- Bump required wavesurfer.js version to 2.0.1


## 2.1.2 - 2017/12/13

- Fix compatibility issue with videojs-record plugin (#46)


## 2.1.1 - 2017/12/12

- Added support for changing the playback rate (#43)
- Added `.videojs-wavesurfer` CSS class (#44 by @eiennosihaisya)
- Fix issue with overriding the HTML5 tech which caused an error on video.js
  players on the same page that don't use the videojs-wavesurfer plugin (#41
  by @mfairchild365)
- Support setting time using `player.currentTime([seconds])` (#45 by
  @mfairchild365)


## 2.1.0 - 2017/12/05

- Caption/subtitle support (#36 by @mfairchild365)


## 2.0.3 - 2017/11/30

- Fix Windows build


## 2.0.2 - 2017/11/15

- Updated `load` function to optionally load an array of pre-rendered
  peak data (#38 by @rbwest)


## 2.0.1 - 2017/10/03

- Support for video.js 6.3.1 and newer


## 2.0.0 - 2017/10/03

- Rewrite plugin using ES6 (#29)
- video.js 6.0 or newer is now required: older versions are no longer supported
- Wavesurfer.js version 2.0.0 or newer is now required: older versions are no
  longer supported (#32)
- Added support for the video.js `fluid` option (#28 by @ikbensiep)
- Added default CSS styles (that previously were only included in the examples):
  `dist/css/videojs.wavesurfer.css`
- Added React example (#33)

**Backwards-incompatible change** (when upgrading from a previous version):

- Use `player.wavesurfer()` instead of `player.waveform` to interact with the
  plugin, e.g. `player.wavesurfer().getDuration()`


## 1.3.6 - 2017/09/23

- Bugfix: properly update current time and duration display components (#34)


## 1.3.5 - 2017/09/19

- Bugfix: correct the uiElements check (#26)


## 1.3.4 - 2017/09/19

- Restricted required wavesurfer.js version to < 2.0.0


## 1.3.3 - 2017/05/27

- Use `video.js` AMD module name (#30)


## 1.3.2 - 2017/04/09

- Use `videojs.registerPlugin` in video.js 6.0.0 and newer (#27)


## 1.3.1 - 2017/02/26

- Added `getDuration` and `getCurrentTime` methods


## 1.3.0 - 2017/02/13

- Moved main script out of root into a new `src/js` directory
- NPM package now includes `dist` directory with minified files


## 1.2.7 - 2017/01/15

- Added `playbackFinish` event (#24)


## 1.2.6 - 2016/09/30

- Bugfix: made sure the `debug` option has a default value (`false`)


## 1.2.5 - 2016/09/30

- Added `waveReady` event, useful for initializing wavesurfer.js plugins
- Added support for the wavesurfer.js `splitChannels` option (#21)


## 1.2.4 - 2016/09/16

- Added `exportImage` to save an image of the waveform
- Bumped required wavesurfer.js version to 1.2.0 for `exportImage` method


## 1.2.3 - 2016/08/27

- Bugfix: added compatibility for video.js 5.11.0 and newer (#20)


## 1.2.2 - 2016/08/08

- Bugfix: corrected Node name for wavesurfer.js module (#19 by @monachilada)


## 1.2.1 - 2016/05/22

- Documentation updates


## 1.2.0 - 2016/03/25

- Prevented negative or invalid values in `formatTime`
- Documentation updates


## 1.1.0 - 2016/02/26

- Catch microphone device errors
- Bumped required wavesurfer.js version to 1.0.57 for microphone plugin fixes
- Bugfix: make sure video.js starts playback mode
- Bugfix: pass wavesurfer config to microphone plugin


## 1.0.6 - 2016/01/17

- Fixed issues with Firefox for Android (#15)


## 1.0.5 - 2016/01/17

- Propagate wavesurfer errors properly (#13 by @xlc)


## 1.0.4 - 2015/12/21

- Fixed wrong video.js module require for browserify


## 1.0.3 - 2015/10/15

- Fixed missing amd/node/global browser dependency for wavesurfer


## 1.0.2 - 2015/10/15

- Made sure controlBar is always showing (if `controls: true`)
- Fixed module Node/AMD/browser globals


## 1.0.1 - 2015/10/14

 - Bugfix: use flex for controlBar so other plugins, like videojs-record, can
   add more controls to it.


## 1.0.0 - 2015/10/12

- Support for video.js 5
- Dropped support for video.js 4.x


## 0.9.9 - 2015/10/06

- Use new `microphone.pause` and `microphone.play` during `live` mode
- Bumped minimum version for wavesurfer.js to 1.0.44 (for microphone plugin
  updates)


## 0.9.8 - 2015/10/04

- Updated bower and npm so only video.js v4.x releases are fetched, v5.0 is not
  supported yet (#5).
- Added ability to override waveform height (#9)


## 0.9.7 - 2015/08/27

- Allow custom wavesurfer container (#7)


## 0.9.6 - 2015/03/19

- Microphone plugin (if enabled) now also being removed in `destroy`


## 0.9.5 - 2015/03/03

- Compatibility fix for video.js 4.12


## 0.9.4 - 2015/02/18

- Compatibility with video.js 4.12.0


## 0.9.3 - 2015/02/18

- Documented video support and added an example (#3)


## 0.9.2 - 2015/02/12

- Updated metadata for video


## 0.9.1 - 2015/01/14

- Documentation and packaging fixes.


## 0.9.0 - 2015/01/06

- Bugfixes


## 0.8.1 - 2014/12/17

- Fixed bug with loading `Blob` or `File` objects


## 0.8.0 - 2014/12/17

- Added microphone support for live audio visualization


## 0.7.0 - 2014/12/08

- Ignore fullscreen mode when no valid src was loaded
- Hide loading spinner when no valid src is found
- Fixed issue with currentTimeDisplay's internal timer


## 0.6.0 - 2014/11/25

- Bugfixes


## 0.5.0 - 2014/11/25

- Bugfixes


## 0.4.0 - 2014/11/19

- Added `msDisplayMax` plugin setting
- Minor bugfixes, more docs


## 0.3.0 - 2014/11/14

- Added fullscreen feature
- Fixed issue with auto-play (#2)
- Made package available on bower and npm


## 0.2.0 - 2014/10/05

- Compatibility with video.js 4.6 - 4.9


## 0.1.0 - 2014/03/18

- Initial release
