# videojs-record changelog

## 4.5.0 - 2021/06/14

- Add `convert` method and `convertAuto` option, allowing user
  to control start of converter process (#568)
- Improve check in `removeRecording` (#575)
- Bump required version for webrtc-adapter (8.0.0 or newer)
- Stop screen sharing on a microphone permissions error in
  `AUDIO_SCREEN` mode (#585)


## 4.4.0 - 2021/04/05

- Fix stopping stream if it is active when using `getDevice` (#561)
- Bump required version for:
  - recordrtc (5.6.2 or newer) (#553)
  - videojs-wavesurfer (3.7.0 or newer)
  - webrtc-adapter (7.7.1 or newer)


## 4.3.0 - 2021/03/08

- Fix controlbar flickering in Mobile Safari (#413)
- Fix hiding picture-in-picture button (#486)
- Fix stretched output for image-only mode when aspect ratio
  of player is not the same as camera media constraints (#511)
- Bump required version for videojs-wavesurfer (3.6.0 or newer)


## 4.2.0 - 2021/02/05

- New ffmpeg.wasm converter plugin: convert recorded data into other
  audio/video/image file formats (#522)
- New opus-media-recorder plugin: provides cross-browser Opus codec
  support for various audio formats such as Ogg and WebM (#355)
- ffmpeg.js plugin is deprecated; use new ffmpeg.wasm plugin instead (#522)
- Add support for downloading converted data using `saveAs` (#506)
- Add `formatTime` option and `setFormatTime(impl)` for replacing the default
  `formatTime` implementation (#483)
- Build using Webpack 5 (#514)
- Bump required version for videojs-wavesurfer (3.5.0 or newer)


## 4.1.1 - 2020/11/01

- Fix issue with opus-recorder plugin (#519)


## 4.1.0 - 2020/08/11

- Fix webpack externals configuration: it's no longer needed to
  use additional webpack configuration in React/Angular/Vue projects
  (#487, #493, #497)
- ffmpeg.js plugin: handle `abort` errors (#481)
- Bump required version for:
  - videojs-wavesurfer (3.3.0 or newer)
  - webrtc-adapter (7.7.0 or newer)


## 4.0.0 - 2020/05/20

- Add ability to grab waveform (audio-only) or video frame data using
  `exportImage` (#417)
- Fix file extension for `video/x-matroska` mime-type (#464, #469)
- Fix milliseconds in `formatTime` (#443)
- Ask again for device permissions in Firefox when user cleared them
  manually (#468)
- Fix missing error handler for microphone permissions in audio/screen
  mode (#463)
- Move documentation to website (#472)
- Bump required version for:
  - video.js (7.0.5 or newer)
  - videojs-wavesurfer (3.2.0 or newer)
  - recordrtc (5.6.1 or newer)
- Add compatibility for video.js 7.7.6 and newer (#465)
- Fix mime-type for lamejs plugin

**Backwards-incompatible changes** (when upgrading from a previous version):

- Configuration for microphone/audio-only has changed (due to videojs-wavesurfer upgrade):
  - Specify `backend: 'WebAudio'` instead of `src: 'live'`
  - Enable the wavesurfer.js microphone plugin using the `plugins` object of
    the `wavesurfer` plugin config


## 3.11.0 - 2020/03/02

- Fix autostop error when max file size was reached (#448 by @Eduardo-Lpz)
- Bump required version for recordrtc to 5.5.9


## 3.10.0 - 2020/02/11

- Support constraints when recording screen-only or audio-screen (#440)
- Prevent monkey-patched video.js `play` method being used by other video.js
  players on the same page (#437)


## 3.9.0 - 2019/12/29

- New options for image-only mode to change the data type of the
  `player.recordedData` object:
  - `imageOutputQuality`: number between 0 and 1 indicating the
    image quality (default: 0.92)
  - `imageOutputType`: either `'blob'` or `'dataURL'` (default)
  - `imageOutputFormat`: image format (default: `image/png`)
- Trigger `Event.RETRY` for image-only (#403 by @vendramini)
- Image-only: prevent blank image at startup (#406)
- Add `style` and `sass` entries to `package.json`
- Specify non-minified videojs-record in `main` entry of `package.json`
- Check for `pipToggle` (#411)
- Bump required version for videojs-wavesurfer to 2.11.0 or newer and reject
  videojs-wavesurfer version 3.0.0 or newer until that release is available and
  supported


## 3.8.0 - 2019/07/16

- New ffmpeg.js plugin: convert recorded data into other audio/video file formats
  in the browser (#201)
- Support for capturing screen + audio (#385 by @tony)
- Support for specifying third-party plugin settings using the `pluginLibraryOptions`
  option (#383)
- New options: `videoBitRate` and `videoFrameRate` (currently only used in the
  webm-wasm plugin)
- New event: `startConvert` (used in ts-ebml and ffmpeg.js plugins) (#201)
- Support for video.js Picture-In-Picture API (available in video.js >= 7.6.0). Tries
  to use `PictureInPictureToggle`, otherwise fallback to own implementation (#381)
- Fix `RecordRTC.MediaStreamRecorder` import when using the `timeSlice` option
- Examples: add `timeSlice` example demonstrating use of `timestamp` event
- Bump required version for videojs-wavesurfer to 2.9.0 or newer for wavesurfer.js
  3.0.0 support
- Bump required version for recordrtc to 5.5.8
- Bump required version for webrtc-adapter to 7.2.8 or newer


## 3.7.1 - 2019/05/30

- Add missing video.js imports for plugins (#378)


## 3.7.0 - 2019/05/27

- Add `setVideoInput(deviceId)` for changing the video input device (#369)
- Add `setAudioInput(deviceId)` for changing the audio input device (#374)
- Examples: use dark theme when possible


## 3.6.0 - 2019/04/02

- Add support for keyboard hotkeys (requires video.js 7.5.0 or newer) (#339)
- Trigger error when `getUserMedia` or `getDisplayMedia` support is missing (in
  Chrome iOS for example) (#353)
- Improve pause/resume accuracy with monotonic clock
- Make sure recorded data is garbage collected
- Bump required version for videojs-wavesurfer to 2.8.0 for wavesurfer.js fixes
- Examples: add `playsinline` attribute to `video` element for Safari (#353)


## 3.5.1 - 2019/03/06

- Fix RecordRTC import (#345)
- Update Safari `AudioContext` workaround in examples (#335)


## 3.5.0 - 2019/02/28

- Support for Picture-in-Picture during playback and recording. Allows users to
  record and playback in a floating window (always on top of other windows) while
  interacting with other sites or applications (#340)
- New webm-wasm plugin: create webm files using libwebm (compiled with
  WebAssembly) in the browser (#321)
- Ability to change label of record indicator (#336)
- Move event types to separate class (#341)
- Fix suspended wavesurfer.js `AudioContext` in Chrome (#335)

**Backwards-incompatible change** (when upgrading from a previous version):

- The `vmsg` plugin, introduced in 3.3.0, now requires a `audioWebAssemblyURL` option,
  previously called `audioWorkerURL`. Use the new `audioWebAssemblyURL` option instead of
  the previous `audioWorkerURL`. Note this only applies to the `vmsg` plugin, other plugin
  options have not changed.


## 3.4.3 - 2019/02/17

- Add missing import, fixes 'videojs is not defined' error (#333)
- Bump required version for webrtc-adapter to 7.2.0 or newer


## 3.4.2 - 2019/02/10

- vmsg plugin: add `destroy`


## 3.4.1 - 2019/02/09

- Fix ES export syntax for `Record` (#330 by @extronics)
- Bump required version for videojs-wavesurfer to 2.7.0 for `playToggle` fixes
- Fix hiding `playToggle` control


## 3.4.0 - 2019/02/04

- Support video recording in Safari (Technology Preview 73 or newer) (#181)
- Bump required version for recordrtc to 5.5.3 for Safari video recording
  support (#320)
- Add example for changing video source (#223)
- Add ability to permanently hide custom UI elements (e.g. `recordToggle`)


## 3.3.0 - 2019/01/10

- New ts-ebml convert plugin: creates seekable webm files by injecting
  metadata like duration (#317)
- New vmsg audio plugin: produces MP3 using a WebAssembly version of the
  LAME library (#287)


## 3.2.1 - 2019/01/08

- Fix issue with `srcObject` (#312)
- Fix shim for screen capture (#318)


## 3.2.0 - 2019/01/07

- Fix duration display for video.js 7.4.x (#316)
- Bump required version for recordrtc to 5.5.0 for `URL.createObjectURL` fixes
  (#315)
- Simple upload example: make sure upload directory exists (#314)


## 3.1.0 - 2018/12/13

- Allow hiding time controls
- Improve `destroy` method (#310)
- Bump required version for recordrtc to 5.4.9 for bug fixes


## 3.0.0 - 2018/11/29

- Add support for screen capture (#289)
- Add `maxFileSize` option to limit the maximum file size of a recorded
  clip, and stop recording when that limit is reached (#234)
- Add `msDisplayMax` option to control display of time format (#188)
- Documentation: add Angular and Vue.js wiki pages (#274, #283)
- Bump required videojs-wavesurfer version to 2.6.2 for microphone support
  in the MS Edge and Safari browsers (#294)
- Fix issue with `timeSlice` option when resetting the player (#300 by @GDIBass)
- Examples: add Safari/Edge browser workarounds for audio-only recording (#295)

**Backwards-incompatible changes** (when upgrading from a previous version):

- In older versions a `player.recordedData.video` would be available in Chrome
  when recording audio and video. This is removed and `player.recordedData`
  is always a `Blob` across all recording types and browsers now (#269)
- Upgraded to video.js/font 3.0.0: removed support for IE8, 9, 10, and
  Android < 4.4 by removing support for the `eot` font file (#279)


## 2.4.1 - 2018/08/03

- `autoMuteDevice` option to turn off the device between recordings
  (for privacy reasons) (#157)
- Fix lamejs plugin (#265)


## 2.4.0 - 2018/07/31

- Fix `RecordRTCEngine` import in React apps (#263)
- Fix recording multiple times in lamejs plugin (#265)


## 2.3.2 - 2018/07/24

- Ability to pass an options object to the `loadOptions` method (#254
  by @tomasdev)


## 2.3.1 - 2018/06/04

- Bump required version for videojs-wavesurfer to 2.5.0 to fix clashes with
  regular video.js players loaded on the same page (#235)
- Fix Safari support in audio plugins


## 2.3.0 - 2018/05/15

- Add plugin style `vjs-record` and prefix all custom plugin styles with this
  selector. This should prevent clashes with regular video.js players loaded
  on the same page (#235)
- Compile SCSS into CSS using webpack
- Move `font` directory to `src/fonts`


## 2.2.2 - 2018/05/11

- Use `grabFrame` for image capture on Chrome (#225)


## 2.2.1 - 2018/05/09

- Add simple upload example for node.js and python (#233)
- Fix misaligned text in record indicator on Chrome (by @ikbensiep)


## 2.2.0 - 2018/05/07

- Package library using webpack 4 (#226)
- Add unit tests using karma/webpack/jasmine (#226)
- Bump required version for videojs-wavesurfer to 2.3.2 for wavesurfer
  destroy fixes


## 2.1.3 - 2018/04/08

- Fix issue with `ImageCapture.takePhoto` on Chrome (#225)


## 2.1.2 - 2018/02/25

- Bump required version for videojs-wavesurfer to 2.2.1 for compatibility
  with video.js 6.7.x (#208)
- Ability to specify bitrate setting in lamejs plugin (#213)


## 2.1.1 - 2018/02/19

- Add missing file info for blobs created with `timeSlice` option (#206)
- Use the new `lastModified` property for generated blobs, `lastModifiedDate`
  is deprecated


## 2.1.0 - 2018/02/10

- Support for selecting audio output device (#16)
- Bump required version for videojs-wavesurfer to 2.2.0 for `setAudioOutput`
- Added example for audio input selection (#13)
- The opus-recorder plugin requires v4.0.0 or newer now: older versions are no
  longer supported (#204)


## 2.0.6 - 2018/01/15

- Fix compatibility with video.js 6.6.0 (#198)
- Bump required version for videojs-wavesurfer to 2.1.4
- Document how to stream upload to server using timestamp event (#176)


## 2.0.5 - 2017/12/30

- Release stream tracks and close `audioContext` on stop recording in the
  lamejs plugin (#197 by @mafflin)


## 2.0.4 - 2017/12/13

- Fix issue with blinking time display (#175)
- Bump required version for videojs-wavesurfer to 2.1.2
- Bump required version for recordrtc to 5.4.6 for access to `RecordRTC.version`
  number


## 2.0.3 - 2017/11/30

- Fix Windows build (#186)
- Bumped required version for videojs-wavesurfer to 2.0.3


## 2.0.2 - 2017/11/15

- Fix issue with copying fonts during build (#185)
- Bump required version for recordrtc to 5.4.5 for improved Safari 11 support (#181)


## 2.0.1 - 2017/11/10

- Fix `MRecordRTC` reference error (#177)


## 2.0.0 - 2017/10/05

- Refactor plugin using ES6 (#167, #149)
- video.js 6.0 or newer is now required: older versions are no longer supported
- videojs-wavesurfer.js version 2.0.1 or newer is now required: older versions
  are no longer supported
- RecordRTC.js version 5.4.4 or newer is now required: older versions are no
  longer supported
- New dependency: webrtc-adapter (version 5.0 or newer) is now recommended;
  the old WebRTC (`getUserMedia`) cross-browser support code has been removed
- Support for the video.js `fluid` option for responsive layout (#166)
- Replace usage of deprecated `URL.createObjectURL(stream)` (#169)
- Added React example (#33)

**Backwards-incompatible changes** (when upgrading from a previous version):

- Use `player.record()` instead of `player.recorder` to interact with the
  plugin, e.g. `player.record().destroy()`


## 1.7.1 - 2017/09/23

- Bumped required version for videojs-wavesurfer to 1.3.6 to restrict the
  wavesurfer.js dependency to anything lower than 2.0.0
- Bugfix: properly update current time and duration display components


## 1.7.0 - 2017/07/25

- Get blobs after specific time-intervals using the `timestamp` event and
  `timeSlice` option (#3)
- Bump required version for recordrtc to 5.4.2 for `timeSlice` support
- Fix CSS styling for video.js 6.0 and newer (#149)
- Take into account async stream loading before playing media on the Android
  version of the Chrome browser (#154 by @kperdomo1)
- Bump required Chrome version to 60 or newer for ImageCapture support (#153)
- Exclude video.js 6.2.0 or newer until video.js module export issue is
  resolved (#149)


## 1.6.2 - 2017/05/27

- Use video.js AMD module name (#123, #136)
- Bump required version for videojs-wavesurfer to 1.3.3 for the correct
  video.js AMD module name


## 1.6.1 - 2017/04/09

- Use `videojs.registerPlugin` in video.js 6.0.0 and newer
- Bumped required version for videojs-wavesurfer to 1.3.2 to support video.js
  6.0.0 and newer


## 1.6.0 - 2017/02/26

- Added `pause` and `resume` methods (#61)
- Added `getDuration` and `getCurrentTime` methods (#129)
- Added `progressRecord` event that fires continuously during recording (#128)
- Added support for `MediaStreamTrack.takePhoto` for image-only mode (#96)
- Plugin fixes for opus-recorder 0.5.0
- NPM package now includes `dist` directory with minified files
- Fix for ignoring missing player elements (#118 by @stragari)
- Bumped required version for videojs-wavesurfer to 1.3.1 for `getDuration`
  and `getCurrentTime` methods


## 1.5.2 - 2017/01/15

- Include CSS file for bower (#107 by @abrarahmedbcg)


## 1.5.1 - 2016/12/02

- Added `saveAs` method that shows a browser dialog window where the user can store
  the recorded media locally (#97)


## 1.5.0 - 2016/09/30

- Added `audioMimeType` and `videoMimeType` settings for H264 support (#92)
- Listening for `tap` events to support touch on mobile (#71)
- Bumped required version for videojs-wavesurfer to 1.2.6 and wavesurfer.js to
  1.2.0 for access to their `exportImage` method (#91)


## 1.4.0 - 2016/05/25

- Added `reset` method to reset the plugin without destroying it (#73)
- Releasing existing object URLs (#70)


## 1.3.0 - 2016/03/25

- Added `enumerateDevices` API (#16)
- Preventing invalid or negative value in `formatTime` (#46 by @zang)


## 1.2.0 - 2016/02/27

- Added compatibility for single file recording introduced in Chrome 49+ (by
  @zang)
- Preferring `navigator.mediaDevices.getUserMedia` instead of deprecated
  `navigator.getUserMedia` if available
- Stop using deprecated `MediaStream.stop()`; use `MediaStreamTrack.stop()`
  instead
- Added `audioRecorderType` and `videoRecorderType` options
- Bumped required version for videojs-wavesurfer to 1.1.0, wavesurfer.js to
  1.0.57 and recordrtc to 5.2.9 for microphone and Chrome fixes
- Fixes for latest release of the libvorbis.js plugin (1.1.1). This also
  removes the `audioModuleURL` option
- IE8 font fixes


## 1.1.0 - 2016/01/19

- Moved support for other audio recorders to separate source files
- Support for Opus using opus-recorder (#43)
- Support for MP3 using lamejs (#40)
- Support for recorder.js (#33)
- New settings: `audioChannels`, `frameWidth` and `frameHeight` (#35)
- Disabled video.js `loop` option permanently (#42)
- Disabled native controls for better Firefox mobile compatibility (#19)
- Added CSS for controlbar on mobile in examples (#19)
- Improved check for `getUserMedia` browser support (#38 by @xlc)
- Close `AudioContext` on stop in libvorbis.js plugin (#36, #37 by @xlc)
- Required version for RecordRTC is 5.2.7 now
- Required version for videojs-wavesurfer is 1.0.6 now
- Required version for wavesurfer.js and wavesurfer.microphone.js is 1.0.50 now
- Ability to add audio and video constraints (#30 by @alsar)
- Added filename and timestamp to recorded file object (#29)
- Added upload examples for the jquery.fileupload and Fine Uploader libraries (#29)


## 1.0.3 - 2015/12/20

- Fixed wrong module require for browserify (#28 by @alsar)


## 1.0.2 - 2015/10/19

- Added animated recording indicator (by @ikbensiep)
- Fixed `destroy`


## 1.0.1 - 2015/10/15

- Fixed AMD/Node/browser global dependency for video.js


## 1.0.0 - 2015/10/14

- Support for video.js 5
- Dropped support for video.js 4.x


## 0.9.3 - 2015/10/12

- Added translations for Afrikaans, German, Spanish, Finnish, Frisian, French,
  Galician, Italian, Portugese, Russian and Swedish


## 0.9.2 - 2015/10/06

- Bumped minimum version for wavesurfer.js (1.0.44) and videojs-wavesurfer
  (0.9.9) for microphone updates (#12)
- Fixed stop/getDevice in audio-only mode (#12)


## 0.9.1 - 2015/10/04

- Make sure bower and npm only download video.js v4.x (#15) because v5.0 is
  not supported yet (#6)
- Add `stopDevice` for disabling the webcam/microphone device (#12)
- Do something about new [mediastream deprecation warnings](https://developers.google.com/web/updates/2015/07/mediastream-deprecations) in Chrome 45 (#12)
- Fixed issue with missing `isChrome`


## 0.9.0 - 2015/09/25

- Support for libvorbis.js in audio-only mode (#8)
- Set default audio sample rate to 44100 (#7)


## 0.8.4 - 2015/08/27

- Examples fixes: wavesurfer changed domain name to wavesurfer-js.org


## 0.8.3 - 2015/07/30

- Added support for animated GIF recordings (#2)
- Both audio and video streams are now available when recording audio/video
  simultaneously in the Chrome browser (#4)
- Audio playback now works when recording both audio and video in the Chrome
  browser (#4)


## 0.8.2 - 2015/03/30

- Fixed `debug` option


## 0.8.1 - 2015/03/30

- Removed duplicate `stopRecord` event trigger for image-only mode


## 0.8.0 - 2015/03/30

- Switched to `MRecordRTC` to enable recording audio/video blobs (in
  Firefox >= 29 only at time of this release)
- Hide fullscreen button in image-only example


## 0.7.0 - 2015/03/28

- Added support for images (#1)


## 0.6.0 - 2015/03/23

- Documentation fixes


## 0.5.0 - 2015/02/21

- Added `destroy` method for cleaning up
- Added `debug` option to control console logging (in RecordRTC)


## 0.4.0 - 2015/02/19

- Compatibility fixes for Video.js 4.12.0


## 0.3.0 - 2015/02/11

- Added Dutch translation
- Disable controls during waveform rendering
- Added `deviceReady` event
- Documentation fixes


## 0.2.0 - 2015/01/07

- Bugfixes


## 0.1.0 - 2015/01/06

- Initial release
