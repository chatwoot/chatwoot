wavesurfer.js changelog
=======================

6.1.0 (31.03.2022)
------------------
- Fix many calls to `setSinkId` resulting in no sound (#2481)
- Optimize responsive resize to avoid unnecessarily firing redraw on unpainted waveforms (#2485)
- Minimap plugin:
  - Remove waveform of previous audio when starting to load new audio (#2479)
  - Changed regions function name to resolve ambiguities (#2482)

6.0.4 (09.03.2022)
------------------
- Spectrogram plugin:
  - Add `frequencyMin`, `frequencyMax` option to scale frequency axis. 
    And set default 12kHz range to draw spectrogram like 5.x (#2455)
- Timeline plugin:
  - Fix rendering issue for negative `offset` values (#2463)

6.0.3 (01.03.2022)
------------------
- Cursor plugin:
  - Fix type documentation for `followCursorY` and `opacity` options (#2459)
  - Fix destroying cursor and showTime dom nodes (#2460)

6.0.2 (20.02.2022)
------------------
- Fix regression and restore support for passing a `CanvasGradient` to
  `setWaveColor()` (#2448)
- Regions plugin:
  - Fixed the type annotation of `maxRegions` in the regions plugin (#2454)

6.0.1 (13.02.2022)
------------------
- Fixed a regression that broke bars rendering when using a certain format for
  the peaks array (#2439)

6.0.0 (07.02.2022)
------------------
- Add additional type to `waveColor` and `progressColor` parameters to support linear
  gradients (#2345)
- Add `hideCursor` option to hide the mouse cursor when hovering over the waveform (#2367)
- Add optional `channelIdx` parameter to `setWaveColor`, `getWaveColor`, `setProgressColor`
  and `getProgressColor` methods (#2391)
- Improved drawing waveform with bars, now bars height is the maximum peak value in
  range (#2428)
- Workaround for `seekTo` occasionally crashing on Firefox (#1228, #2431)
- Markers plugin: Add the ability to set markers as draggable using param `draggable=true`,
  `marker-drag` and `marker-drop` events will be triggered (#2398)
- Regions plugin:
  - Increase region z-index to fix stacking inconsistencies (#2353)
  - Check `maxLength` before resizing region (#2374)
  - Add support for drag selection to be separated for each channel (#2380)
  - Allow `formatTimeCallback` from plugin params to be used (#2294)
  - Use of default `edgeScrollWidth` value no longer dependent on regions being created via
    plugin params (#2401)
  - Disable `region-remove` event emission during plugin teardown (#2403)
- Spectrogram plugin:
  - Remove inaccurate frequency doubling of spectrogram (#2232)
  - Support for `splitChannels` option to draw spectrogram for each channel (#2424)

5.2.0 (16.08.2021)
------------------
- Add `ignoreSilenceMode` option to ignore iOS hardware silence switch when using the
  `WebAudio` backend (#1864)
- Fixed unhandled `Failed to execute 'stop' on 'AudioScheduledSourceNode'` error (#1473)
- Fixed unhandled `Cannot read property 'decodeArrayBuffer' of null` error (#2279)
- Timeline plugin: fixed unhandled `null is not an object (evaluating context.canvas)`
  error in Safari v14 (#2333)
- Regions plugin: add `direction` and `action` fields to the `region-updated` event
  params (#2339)

5.1.0 (20.06.2021)
------------------
- Markers plugin:
  - Add the ability to use custom HTML elements in place of the default marker icon by
    passing the new `markerElement` parameter to the marker constructor (#2269)
  - Custom HTML elements are now centered over the marker line (#2298)
  - Trigger `marker-click` event on wavesurfer (#2287)
- Regions plugin: handle rollover cursor bug fix (#2293)
- Timeline plugin: prevent calling `Canvas` context methods on `null` values (#2299)
- Spectrogram plugin: prevent calling `Canvas` context methods on `null` values (#2299)

5.0.1 (05.05.2021)
------------------
- Fix removing DOM element on `destroy()` (#2258)

5.0.0 (02.05.2021)
------------------
- Add new `vertical` parameter enabling displaying waveforms vertically (#2195)
- Fixed `exportPCM()` to return a Promise containing valid JSON data with `noWindow`
  (#1896, #1954)
- Nullify `onaudioprocess` on remove to not execute in background (#2218)
- Playhead plugin: add a new plugin that allows the setting of a independent
  "play head", or song-start position. (#2209)
- Markers plugin: fix a bug where markers at the end of a track would cause
  incorrect click-to-seek behavior (#2208)
- Regions plugin:
  - Fix mouseup not firing if click & drag a region handle & release outside the
    browser window (#2213)
  - Added new `showTooltip` param allowing disabling region `title` tooltip (#2213)

4.6.0 (04.03.2021)
------------------
- Webaudio: fix `decodeAudioData` handling in Safari (#2201)
- Markers plugin: add new plugin that allows for timeline markers (#2196)

4.5.0 (14.02.2021)
------------------
- Split channels: `overlay` param now properly displays a single canvas (#2161)
- Fixed memory leak with `destroy()` in `WebAudio` backend (#1940)
- Fixed `WaveSurfer.load(url)` not working when passing a HTMLMediaElement as
  the url parameter, with the WebAudio backend.
- Microphone plugin: remove deprecated `MediaStream.stop` call (#2168)
- Regions plugin: stop region dragging when mouse leaves canvas (#2158)

4.4.0 (13.01.2021)
------------------

- Use Webpack 5 for build (#2093)
- Fix seeking issues for `WebAudio` backend (#2149)
- Use `splitChannelsOptions` to color wave bars (#2150)

4.3.0 (12.12.2020)
------------------

- Add `relativeNormalization` option to maintain proportionality between
  waveforms when `splitChannels` and `normalize` are `true` (#2108)
- WebAudio backend: set playback rate modifying directly the playback
  property of the source node (#2118)
- Spectrogram plugin: Use `ImageData` to draw pixel-by-pixel (#2127)

4.2.0 (20.10.2020)
------------------

- Fix performance issues with `seekTo` while audio is playing (#2045)
- Trigger `waveform-ready` event when provided peaks are drawn (#2031)

4.1.1 (24.09.2020)
------------------

- Revert Code cleanup for Observer class (#2069)

4.1.0 (16.09.2020)
------------------

- Don't call HTMLMediaElement#load when given peaks and preload == 'none'.
  Prevents browsers from pre-fetching audio (#1969, #1990)
- `seekTo` bugfix inc. basic unit tests (#2047)
- Fix unhandled `AbortError` thrown during `cancelAjax` (#2063)
- Remove `util.extend`: deprecated since v3.3.0 (#1995)
- Remove `util.ajax`: deprecated since v3.0.0 (#2033)
- Regions plugin:
  - Removed `col-resize` cursor when resize is disabled (#1985)
  - Improved and unified loop playback logic (#1868)
  - Check `minLength` before resizing region (#2001)
  - Dragging and resizing will continue outside canvas (#2006)
  - `regionsMinLength` parameter to assign a min length to those regions for which the `minLength`  is not specified (#2009)
  - Revert PR #1926 click propagation on regions. Use event parameter passed
    in `region-click` if you need `stopPropagation`. (#2024)
  - Edgescroll works for both edges (#2011)
- Microphone plugin: move to separate directory (#1997)
- Minimap plugin: move plugin to separate directory (#1999)
- Cursor plugin: move plugin to separate directory (#1998)
- Elan plugin: move plugin to separate directory (#2019)
- Spectrogram plugin: move to separate directory (#1996)
- Mediasession plugin: move to separate directory (#2020)
- Timeline plugin: move to separate directory (#2018)

4.0.1 (23.06.2020)
------------------

- Fixes for event handling with certain plugins (regions, microphone).
  The crash would have involved '_disabledEventEmissions' (#1975)

4.0.0 (21.06.2020)
------------------

- Fixed mediaelement-webaudio playback under Safari (#1964)
- Fixed the `destroy` method of the `MediaElementWebAudio` backend. Instead of
  destroying only the media element, the audio nodes are disconnected and the
  audio context is closed. This was done by splitting the `destroy` method of the
  `WebAudio` backend, so it calls the new `destroyWebAudio` method to cancel
  everything related to WebAudio (#1927)
- Removed private methods of plugins and generalized plugins' access, so they can be extended creating custom
  plugins (#1928)
- Added plugin inheritance example (#1921)
- Added compatibility for Gatsby and other static site generators (#1938)
- Minimap plugin: added the ability to use a customized regions plugin using a new parameter
  `regionsPluginName` (#1943)
- Fixed waveform display to not always connect to the sample=0 point (#1942)
- Elan plugin: optional params.tiers (#1910)
- Regions plugin:
  - Split `regions.js` into `region.js` (containing `Region` class) and `index.js`.
    Both files moved into the `src/plugin/regions` directory. This makes it easier
    to extend these classes and use them in custom plugins (#1934)
  - Fixed channelCount assignment (#1858)
  - Fixed click propagation issue (#1926)
  - Fixed switch loop region (#1929)
  - Added ability to specify time format for Regions tooltip using timeformatCallback (#1948)
- Add `splitChannelsOptions` param and `setFilteredChannels` method to configure how channels are drawn (#1947)
- Added checks in `minimap` plugin for `drawer` presence (#1953)
- Add `setDisabledEventEmissions` method to optionally disable calls to event handlers for specific events (#1960)
- Drawer: removed private methods to allow overriding them (#1962)
- Add optional `setMute` method to backends to fix muting behavior with the `MediaElement` backend (#1966)

3.3.3 (16.04.2020)
------------------

- Change default `desynchronized` drawing context attribute to `false` (#1908)

3.3.2 (07.04.2020)
------------------

- Use `requestAnimationFrame` for clearWave (#1884)
- Fix `Unable to get property 'toLowerCase' of undefined or null reference`
  in IE11 (#1771)
- Spectrogram plugin: correct the hamming windfunc formula (#1850)

3.3.1 (13.01.2020)
------------------

- Regions plugin:
  - Improve handles style support (#1839)
  - Add support for a context menu event on a region (#1844)
  - Fix for handle position when using `channelIdx` param (#1845)

3.3.0 (29.12.2019)
------------------

- `wavesurfer.exportPCM` now accepts an optional `end` argument and returns
  a Promise (#1728)
- Add `wavesurfer.setPlayEnd(position)` to set a point in seconds for
  playback to stop at (#1795)
- Add `drawingContextAttributes` option and enable canvas `desynchronized`
  hint (#1642)
- Add `barMinHeight` option (#1693)
- Expose progress to the `dblclick` event (#1790)
- Deprecate `util.extend` and replace usage with `Object.assign` (#1825)
- Regions plugin:
  - Add `start` argument to `play` and `playLoop` methods (#1794)
  - Add `maxRegions` option to limit max numbers of created regions (#1793)
  - Don't assign to module object (#1823)
  - Allow setting the `handleColor` inside `addRegion` (#1798)
  - Disable drag selection before enabling it (#1698)
  - Add `channelIdx` option to select specific channel to draw on (#1829)
  - Refactor for improved readability (#1826)
- Cursor plugin: fix time visibility (#1802)

3.2.0 (24.10.2019)
------------------

- New `MediaElementWebAudio` backend (#1767):
  - Allows you to use Web Audio API with big audio files, loading audio
    like with MediaElement backend (HTML5 audio tag), so you can use the
    same methods of MediaElement backend for loading and playback. This way,
    the audio resource is not loaded entirely from server, but in ranges,
    allowing you to use WebAudio features, like filters, on audio files with
    a long duration. You can also supply peaks data, so the entire audio file
    does not have to be decoded.
    For example:
    ```
    wavesurfer.load(url | HTMLMediaElement, peaks, preload, duration);
    wavesurfer.play();
    wavesurfer.setFilter(customFilter);
    ```
- Add `barRadius` option to create waveforms with rounded bars (#953)
- Throw error when the url parameter supplied to `wavesurfer.load()`
  is empty (#1773, #1775)
- Specify non-minified wavesurfer.js in `main` entry of `package.json` (#1759)
- Add `dblclick` event listener to wavesurfer wrapper (#1764)
- Fix `destroy()` in `MediaElement` backend (#1778)
- Cursor plugin: flip position of time text to left of the cursor where needed
  to improve readability (#1776)
- Regions plugin: change region end handler position (#1762, #1781)

3.1.0 (26.09.2019)
------------------

- Add `autoCenter` and `autoCenterRate` options (#1699)
- Make sure `isReady` is true before firing the `ready` event (#1749)
- Improve fetch error messages (#1748)
- Use `MediaElement` backend for browsers that don't support WebAudio (#1739)
- Regions plugin:
  - Use `isResizing` and `isDragging` to filter events in
    region-updated listener (#1716)
  - Fix `playLoop` and `loop` option for clips with duration <15s (#1626)
- Spectrogram plugin: fix variable name in click handler (#1742)
- Minimap plugin: fix left/width calculations for regions on retina/4k
  screens (#1743)
- New example: video-annotation (#1726)

3.0.0 (11.07.2019)
------------------

- Add `wavesurfer.getActivePlugins()`: return map of plugins
  that are currently initialised
- Replace usage of `util.ajax` with `util.fetchFile` (#1365)
- Update progress when seeking with HTML media controls (#1535)
- Make sure mute/volume is updated when using `MediaElement` backend (#1615)
- Refactor `MultiCanvas` and add `CanvasEntry` class (#1617)
- Fix `wavesurfer.isReady`: make it a public boolean, the
  broken `isReady` method is removed (#1597)
- Add support for `Blob` output type in `wavesurfer.exportImage` (#1610)
- Fix fallback to Audio Element in browsers that don't support Web Audio (#1614)
- `util.getId()` now accepts a `prefix` argument (#1619)
- Improve documentation for `xhr` option (#1656)
- Fix: the `progressWave` should not be rendered when specifying the same
  value for the `progressColor` and `waveColor` options (#1620)
- Cursor plugin:
  - Add `formatTimeCallback` option
  - Add `followCursorY` option (#1605)
  - Remove deprecated `enableCursor` method (#1646)
  - Hide the cursor elements before first mouseover if `hideOnBlur` is set (#1663)
- Spectrogram plugin:
  - Fix `ready` listener when loading multiple audio files (#1572)
  - Allow user to specify a colorMap (#1436)
- Regions plugin:
  - Fix `ready` listener when loading multiple audio files (#1602)
  - Add `snapToGridInterval` and `snapToGridOffset` options (#1632)
  - Allow drawing regions over existing regions, if the underlying ones are not
    draggable or resizable (#1633)
  - Calculate the duration at event time to allow predefined regions to be
    dragged and resized (#1673)
  - Remove deprecated `initRegions` method (#1646)
- Timeline plugin: fix `ready` listener when loading multiple
  audio files
- Minimap plugin: remove deprecated `initMinimap` method (#1646)

Check `UPGRADE.md` for backward incompatible changes since v2.x.

2.2.1 (18.03.2019)
------------------

- Add `backgroundColor` option (#1118)
- Spectrogram plugin: fix click handler (#1585)
- Cursor plugin: fix `displayTime` (#1589)

2.2.0 (07.03.2019)
------------------

- Add `rtl` option (#1296)
- Fix peaks rendering issue on zooming and scrolling multicanvas (#1570)
- Add `duration` option to specify an explicit audio length (#1441)
- Spectrogram plugin: fix event listener removal (#1571)
- Regions plugin: display regions before file load using `duration`
  option (#1441)
- Build: switch to terser-webpack-plugin for minifying

2.1.3 (21.01.2019)
------------------

- Fix removeOnAudioProcess for Safari (#1215, #1367, #1398)

2.1.2 (06.01.2019)
------------------

- Fix computing peaks when buffer is not set (#1530)
- Cursor plugin: fix displayed time (#1543)
- Cursor plugin: document new params (#1516)
- Add syntax highlighting in examples (#1522)

2.1.1 (18.11.2018)
------------------

- Fix order of arguments for PluginClass.constructor (#1472)
- Microphone plugin: Safari support (#1377)
- Minimap plugin: fix styling issues and add support for zooming (#1464)
- Timeline plugin: add duration parameter handling (#1491)
- Cursor plugin: add showTime option (#1143)
- Fix: progress bar did not reach 100% when audio file is small (#1502)

2.1.0 (29.09.2018)
------------------

- Add wavesurfer.js logo, created by @entonbiba (#1409)
- Library version number is now available as `WaveSurfer.VERSION` (#1430)
- Fix `setSinkId` that used deprecated API (#1428)
- Set `isReady` attribute to false when emptying wavesufer (#1396, #1403)
- Microphone plugin: make it work in MS Edge browser (#627)
- Timeline plugin: display more tick marks as the user zooms in closely (#1455)
- Cursor plugin: fix `destroy` (#1435)

2.0.6 (14.06.2018)
------------------

- Build library using webpack 4 (#1376)
- Add `audioScriptProcessor` option to use custom script processor node (#1389)
- Added `mute` and `volume` events (#1345)

2.0.5 (26.02.2018)
------------------

- Fix `util.ajax` on iterating `requestHeaders` (#1329)
- Add version information to distributed files (#1330)
- Regions plugin: prevent click when creating / updating region (#1295)
- Add `wavesurfer.isReady` method (#1333)

2.0.4 (14.02.2018)
------------------

- Added `xhr` option to configure util.ajax for authorization (#1310, #1038, #1100)
- Fix `setCurrentTime` method (#1292)
- Fix `getScrollX` method: Check bounds when `scrollParent: true` (#1312)
- Minimap plugin: fix initial load, canvas click did not work (#1265)
- Regions plugin: fix dragging a region utside of scrollbar (#430)

2.0.3 (22.01.2018)
------------------

- Added support for selecting different audio output devices using `setSinkId` (#1293)
- Replace deprecated playbackRate.value setter (#1302)
- Play method now properly returns a Promise (#1229)

2.0.2 (10.01.2018)
------------------

- Added `barGap` parameter to set the space between bars (#1058)
- Replace deprecated gain.value setter (#1277)
- MediaElement backend: Update progress on pause events (#1267)
- Restore missing MediaSession plugin (#1286)

2.0.1 (18.12.2017)
------------------

- Core library and the plugins were refactored to be modular so it can be used with a module bundler
- Code updated to ES6/ES7 syntax and is transpiled with babel and webpack
- New plugin API
- `MultiCanvas` renderer is now the default
- Added getters and setters for height and color options (#1145)
- Introduce an option to prevent removing media element on destroy (#1163)
- Added duration parameter for the load function (#1239)
- New soundtouch.js filter to preserve pitch when changing tempo (#149)
- Add `getPlaybackRate` method (#1022)
- Switched to BSD license (#1060)
- Added `setCurrentTime` method
- Added `util.debounce` (#993)

1.2.4 (11.11.2016)
------------------

- Fix a problem of Web Audio not playing in Safari on initial load (#749)

1.2.3 (09.11.2016)
------------------

- Add a 'waveform-ready' event, triggered when waveform is drawn with MediaElement backend (#736)
- Add a 'preload' parameter to load function to choose the preload HTML5 audio attribute value if MediaElement backend is choosen (#854)

1.2.2 (31.10.2016)
------------------

- Deterministic way to mute and unmute a track (#841)
- Replace jasmine with karma / jasmine test suite (#849)
- Regions plugin: fix a bug when clicking on scroll-bar in Firefox (#851)

1.2.1 (01.10.2016)
------------------

- Added changelog (#824)
- Correct AMD module name for plugins (#831)
- Fix to remove small gaps between regions (#834)
