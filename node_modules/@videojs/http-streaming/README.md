<img width=300 src="./logo.svg" alt="VHS Logo consisting of a VHS tape, the Video.js logo and the words VHS" />

# videojs-http-streaming (VHS)

[![Build Status][travis-icon]][travis-link]
[![Slack Status][slack-icon]][slack-link]
[![Greenkeeper badge][greenkeeper-icon]][greenkeeper-link]

Play HLS, DASH, and future HTTP streaming protocols with video.js, even where they're not
natively supported.

Included in video.js 7 by default! See the [video.js 7 blog post](https://blog.videojs.com/video-js-7-is-here/)

Maintenance Status: Stable

Video.js Compatibility: 6.0, 7.0

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Installation](#installation)
  - [NPM](#npm)
  - [CDN](#cdn)
  - [Releases](#releases)
  - [Manual Build](#manual-build)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [Talk to us](#talk-to-us)
- [Getting Started](#getting-started)
- [Compatibility](#compatibility)
  - [Browsers which support MSE](#browsers-which-support-mse)
  - [Native only](#native-only)
  - [Flash Support](#flash-support)
  - [DRM](#drm)
- [Documentation](#documentation)
  - [Options](#options)
    - [How to use](#how-to-use)
      - [Initialization](#initialization)
      - [Source](#source)
    - [List](#list)
      - [withCredentials](#withcredentials)
      - [handleManifestRedirects](#handlemanifestredirects)
      - [useCueTags](#usecuetags)
      - [parse708captions](#parse708captions)
      - [overrideNative](#overridenative)
      - [blacklistDuration](#blacklistduration)
      - [maxPlaylistRetries](#maxplaylistretries)
      - [bandwidth](#bandwidth)
      - [useBandwidthFromLocalStorage](#usebandwidthfromlocalstorage)
      - [enableLowInitialPlaylist](#enablelowinitialplaylist)
      - [limitRenditionByPlayerDimensions](#limitrenditionbyplayerdimensions)
      - [useDevicePixelRatio](#usedevicepixelratio)
      - [smoothQualityChange](#smoothqualitychange)
      - [allowSeeksWithinUnsafeLiveWindow](#allowseekswithinunsafelivewindow)
      - [customTagParsers](#customtagparsers)
      - [customTagMappers](#customtagmappers)
      - [cacheEncryptionKeys](#cacheencryptionkeys)
      - [handlePartialData](#handlepartialdata)
      - [liveRangeSafeTimeDelta](#liverangesafetimedelta)
      - [useNetworkInformationApi](#usenetworkinformationapi)
      - [captionServices](#captionservices)
        - [Format](#format)
        - [Example](#example)
  - [Runtime Properties](#runtime-properties)
    - [vhs.playlists.master](#vhsplaylistsmaster)
    - [vhs.playlists.media](#vhsplaylistsmedia)
    - [vhs.systemBandwidth](#vhssystembandwidth)
    - [vhs.bandwidth](#vhsbandwidth)
    - [vhs.throughput](#vhsthroughput)
    - [vhs.selectPlaylist](#vhsselectplaylist)
    - [vhs.representations](#vhsrepresentations)
    - [vhs.xhr](#vhsxhr)
    - [vhs.stats](#vhsstats)
  - [Events](#events)
    - [loadedmetadata](#loadedmetadata)
  - [VHS Usage Events](#vhs-usage-events)
    - [Presence Stats](#presence-stats)
    - [Use Stats](#use-stats)
  - [In-Band Metadata](#in-band-metadata)
  - [Segment Metadata](#segment-metadata)
  - [Object as Source](#object-as-source)
- [Hosting Considerations](#hosting-considerations)
- [Known Issues and Workarounds](#known-issues-and-workarounds)
  - [Fragmented MP4 Support](#fragmented-mp4-support)
  - [Assets with an Audio-Only Rate Get Stuck in Audio-Only](#assets-with-an-audio-only-rate-get-stuck-in-audio-only)
  - [DASH Assets with `$Time` Interpolation and `SegmentTimeline`s with No `t`](#dash-assets-with-time-interpolation-and-segmenttimelines-with-no-t)
- [Testing](#testing)
- [Debugging](#debugging)
- [Release History](#release-history)
- [Building](#building)
- [Development](#development)
  - [Tools](#tools)
  - [Commands](#commands)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation
### NPM
To install `videojs-http-streaming` with npm run

```bash
npm install --save @videojs/http-streaming
```

### CDN
Select a version of VHS from the [CDN](https://unpkg.com/@videojs/http-streaming/dist/)

### Releases
Download a release of [videojs-http-streaming](https://github.com/videojs/http-streaming/releases)

### Manual Build
Download a copy of this git repository and then follow the steps in [Building](#building)

## Contributing
See [CONTRIBUTING.md](/CONTRIBUTING.md)

## Troubleshooting
See [our troubleshooting guide](/docs/troubleshooting.md)

## Talk to us
Drop by our slack channel (#playback) on the [Video.js slack][slack-link].

## Getting Started
This library is included in video.js 7 by default, if you are using an older version of video.js then
get a copy of [videojs-http-streaming](#installation) and include it in your page along with video.js:

```html
<video-js id=vid1 width=600 height=300 class="vjs-default-skin" controls>
  <source
     src="https://example.com/index.m3u8"
     type="application/x-mpegURL">
</video-js>
<script src="video.js"></script>
<script src="videojs-http-streaming.min.js"></script>
<script>
var player = videojs('vid1');
player.play();
</script>
```

Check out our [live example](https://jsbin.com/gejugat/edit?html,output) if you're having trouble.

Is it recommended to use the `<video-js>` element or load a source with `player.src(sourceObject)` in order to prevent the video element from playing the source natively where HLS is supported.

## Compatibility

The [Media Source Extensions](http://caniuse.com/#feat=mediasource) API is required for http-streaming to play HLS or MPEG-DASH.

### Browsers which support MSE

- Chrome
- Firefox
- Internet Explorer 11 Windows 10 or 8.1

These browsers have some level of native HLS support, which will be used unless the [overrideNative](#overridenative) option is used:

- Chrome Android
- Firefox Android
- Edge

### Native only

- Mac Safari
- iOS Safari

Mac Safari does have MSE support, but native HLS is recommended 

### Flash Support
This plugin does not support Flash playback. Instead, it is recommended that users use the [videojs-flashls-source-handler](https://github.com/brightcove/videojs-flashls-source-handler) plugin as a fallback option for browsers that don't have a native
[HLS](https://caniuse.com/#feat=http-live-streaming)/[DASH](https://caniuse.com/#feat=mpeg-dash) player or support for [Media Source Extensions](http://caniuse.com/#feat=mediasource).

### DRM

DRM is supported through [videojs-contrib-eme](https://github.com/videojs/videojs-contrib-eme). In order to use DRM, include the videojs-contrib-eme plug, [initialize it](https://github.com/videojs/videojs-contrib-eme#initialization), and add options to either the [plugin](https://github.com/videojs/videojs-contrib-eme#plugin-options) or the [source](https://github.com/videojs/videojs-contrib-eme#source-options).

Detailed option information can be found in the [videojs-contrib-eme README](https://github.com/videojs/videojs-contrib-eme/blob/master/README.md).

## Documentation
[HTTP Live Streaming](https://developer.apple.com/streaming/) (HLS) has
become a de-facto standard for streaming video on mobile devices
thanks to its native support on iOS and Android. There are a number of
reasons independent of platform to recommend the format, though:

- Supports (client-driven) adaptive bitrate selection
- Delivered over standard HTTP ports
- Simple, text-based manifest format
- No proprietary streaming servers required

Unfortunately, all the major desktop browsers except for Safari are
missing HLS support. That leaves web developers in the unfortunate
position of having to maintain alternate renditions of the same video
and potentially having to forego HTML-based video entirely to provide
the best desktop viewing experience.

This project addresses that situation by providing a polyfill for HLS
on browsers that have support for [Media Source
Extensions](http://caniuse.com/#feat=mediasource).
You can deploy a single HLS stream, code against the
regular HTML5 video APIs, and create a fast, high-quality video
experience across all the big web device categories.

Check out the [full documentation](docs/README.md) for details on how HLS works
and advanced configuration. A description of the [adaptive switching
behavior](docs/bitrate-switching.md) is available, too.

videojs-http-streaming supports a bunch of HLS features. Here
are some highlights:

- video-on-demand and live playback modes
- backup or redundant streams
- mid-segment quality switching
- AES-128 segment encryption
- CEA-608 captions are automatically translated into standard HTML5
  [caption text tracks][0]
- In-Manifest WebVTT subtitles are automatically translated into standard HTML5
  subtitle tracks
- Timed ID3 Metadata is automatically translated into HTML5 metedata
  text tracks
- Highly customizable adaptive bitrate selection
- Automatic bandwidth tracking
- Cross-domain credentials support with CORS
- Tight integration with video.js and a philosophy of exposing as much
  as possible with standard HTML APIs
- Stream with multiple audio tracks and switching to those audio tracks
  (see the docs folder) for info
- Media content in
  [fragmented MP4s](https://developer.apple.com/videos/play/wwdc2016/504/)
  instead of the MPEG2-TS container format.

[0]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track

For a more complete list of supported and missing features, refer to
[this doc](docs/supported-features.md).

### Options
#### How to use

##### Initialization
You may pass in an options object to the hls source handler at player
initialization. You can pass in options just like you would for other
parts of video.js:

```javascript
// html5 for html hls
videojs(video, {
  html5: {
    vhs: {
      withCredentials: true
    }
  }
});
```

##### Source
Some options, such as `withCredentials` can be passed in to vhs during
`player.src`

```javascript

var player = videojs('some-video-id');

player.src({
  src: 'https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8',
  type: 'application/x-mpegURL',
  withCredentials: true
});
```

#### List
##### withCredentials
* Type: `boolean`
* can be used as a source option
* can be used as an initialization option

When the `withCredentials` property is set to `true`, all XHR requests for
manifests and segments would have `withCredentials` set to `true` as well. This
enables storing and passing cookies from the server that the manifests and
segments live on. This has some implications on CORS because when set, the
`Access-Control-Allow-Origin` header cannot be set to `*`, also, the response
headers require the addition of `Access-Control-Allow-Credentials` header which
is set to `true`.
See html5rocks's [article](http://www.html5rocks.com/en/tutorials/cors/)
for more info.

##### handleManifestRedirects
* Type: `boolean`
* Default: `false`
* can be used as a source option
* can be used as an initialization option

When the `handleManifestRedirects` property is set to `true`, manifest requests
which are redirected will have their URL updated to the new URL for future
requests.

##### useCueTags
* Type: `boolean`
* can be used as an initialization option

When the `useCueTags` property is set to `true,` a text track is created with
label 'ad-cues' and kind 'metadata'. The track is then added to
`player.textTracks()`. Changes in active cue may be
tracked by following the Video.js cue points API for text tracks. For example:

```javascript
let textTracks = player.textTracks();
let cuesTrack;

for (let i = 0; i < textTracks.length; i++) {
  if (textTracks[i].label === 'ad-cues') {
    cuesTrack = textTracks[i];
  }
}

cuesTrack.addEventListener('cuechange', function() {
  let activeCues = cuesTrack.activeCues;

  for (let i = 0; i < activeCues.length; i++) {
    let activeCue = activeCues[i];

    console.log('Cue runs from ' + activeCue.startTime +
                ' to ' + activeCue.endTime);
  }
});
```

##### parse708captions
* Type: `boolean`
* Default: `true`
* can be used as an initialization option

When set to `false`, 708 captions in the stream are not parsed and will not show up in text track lists or the captions menu.

##### overrideNative
* Type: `boolean`
* can be used as an initialization option

Try to use videojs-http-streaming even on platforms that provide some
level of HLS support natively. There are a number of platforms that
*technically* play back HLS content but aren't very reliable or are
missing features like CEA-608 captions support. When `overrideNative`
is true, if the platform supports Media Source Extensions
videojs-http-streaming will take over HLS playback to provide a more
consistent experience.

```javascript
// via the constructor
var player = videojs('playerId', {
  html5: {
    vhs: {
      overrideNative: true
    },
    nativeAudioTracks: false,
    nativeVideoTracks: false
  }
});
```

Since MSE playback may be desirable on all browsers with some native support other than Safari, `overrideNative: !videojs.browser.IS_SAFARI` could be used.

##### blacklistDuration
* Type: `number`
* can be used as an initialization option

When the `blacklistDuration` property is set to a time duration in seconds,
if a playlist is blacklisted, it will be blacklisted for a period of that
customized duration. This enables the blacklist duration to be configured
by the user.

##### maxPlaylistRetries
* Type: `number`
* Default: `Infinity`
* can be used as an initialization option

The max number of times that a playlist will retry loading following an error
before being indefinitely excluded from the rendition selection algorithm. Note: the number of retry attempts needs to _exceed_ this value before a playlist will be excluded.

##### bandwidth
* Type: `number`
* can be used as an initialization option

When the `bandwidth` property is set (bits per second), it will be used in
the calculation for initial playlist selection, before more bandwidth
information is seen by the player.

##### useBandwidthFromLocalStorage
* Type: `boolean`
* can be used as an initialization option

If true, `bandwidth` and `throughput` values are stored in and retrieved from local
storage on startup (for initial rendition selection). This setting is `false` by default.

##### enableLowInitialPlaylist
* Type: `boolean`
* can be used as an initialization option

When `enableLowInitialPlaylist` is set to true, it will be used to select
the lowest bitrate playlist initially.  This helps to decrease playback start time.
This setting is `false` by default.

##### limitRenditionByPlayerDimensions
* Type: `boolean`
* can be used as an initialization option

When `limitRenditionByPlayerDimensions` is set to true, rendition
selection logic will take into account the player size and rendition
resolutions when making a decision.
This setting is `true` by default.

##### useDevicePixelRatio
* Type: `boolean`
* can be used as an initialization option.

If true, this will take the device pixel ratio into account when doing rendition switching. This means that if you have a player with the width of `540px` in a high density display with a device pixel ratio of 2, a rendition of `1080p` will be allowed.
This setting is `false` by default.

##### smoothQualityChange
* NOTE: DEPRECATED
* Type: `boolean`
* can be used as a source option
* can be used as an initialization option

smoothQualityChange is deprecated and will be removed in the next major version of VHS.

Instead of its prior behavior, smoothQualityChange will now call fastQualityChange, which
clears the buffer, chooses a new rendition, and starts loading content from the current
playhead position.

##### allowSeeksWithinUnsafeLiveWindow
* Type: `boolean`
* can be used as a source option

When `allowSeeksWithinUnsafeLiveWindow` is set to `true`, if the active playlist is live
and a seek is made to a time between the safe live point (end of manifest minus three
times the target duration,
see [the hls spec](https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-6.3.3)
for details) and the end of the playlist, the seek is allowed, rather than corrected to
the safe live point.

This option can help in instances where the live stream's target duration is greater than
the segment durations, playback ends up in the unsafe live window, and there are gaps in
the content. In this case the player will attempt to seek past the gaps but end up seeking
inside of the unsafe range, leading to a correction and seek back into a previously played
content.

The property defaults to `false`.

##### customTagParsers
* Type: `Array`
* can be used as a source option

With `customTagParsers` you can pass an array of custom m3u8 tag parser objects. See https://github.com/videojs/m3u8-parser#custom-parsers

##### customTagMappers
* Type: `Array`
* can be used as a source option

Similar to `customTagParsers`, with `customTagMappers` you can pass an array of custom m3u8 tag mapper objects. See https://github.com/videojs/m3u8-parser#custom-parsers

##### cacheEncryptionKeys
* Type: `boolean`
* can be used as a source option
* can be used as an initialization option

This option forces the player to cache AES-128 encryption keys internally instead of requesting the key alongside every segment request.
This option defaults to `false`.

##### handlePartialData
* Type: `boolean`,
* Default: `false`
* Use partial appends in the transmuxer and segment loader

##### liveRangeSafeTimeDelta
* Type: `number`,
* Default: [`SAFE_TIME_DELTA`](https://github.com/videojs/http-streaming/blob/e7cb63af010779108336eddb5c8fd138d6390e95/src/ranges.js#L17)
* Allow to  re-define length (in seconds) of time delta when you compare current time and the end of the buffered range.

##### useNetworkInformationApi
* Type: `boolean`,
* Default: `false`
* Use [window.networkInformation.downlink](https://developer.mozilla.org/en-US/docs/Web/API/NetworkInformation/downlink) to estimate the network's bandwidth. Per mdn, _The value is never greater than 10 Mbps, as a non-standard anti-fingerprinting measure_. Given this, if bandwidth estimates from both the player and networkInfo are >= 10 Mbps, the player will use the larger of the two values as its bandwidth estimate.

##### captionServices
* Type: `object`
* Default: undefined
* Provide extra information, like a label or a language, for instream (608 and 708) captions.

The captionServices options object has properties that map to the caption services. Each property is an object itself that includes several properties, like a label or language.

For 608 captions, the service names are `CC1`, `CC2`, `CC3`, and `CC4`. For 708 captions, the service names are `SERVICEn` where `n` is a digit between `1` and `63`.

For 708 caption services, you may additionally provide an `encoding` value that will be used by the transmuxer to decode the captions using an instance of [TextDecoder](https://developer.mozilla.org/en-US/docs/Web/API/TextDecoder). This is to permit and is required for legacy multi-byte encodings. Please review the `TextDecoder` documentation for accepted encoding labels.

###### Format
```js
{
  vhs: {
    captionServices: {
      [serviceName]: {
        language: String, // optional
        label: String, // optional
        default: boolean, // optional,
        encoding: String // optional, 708 services only
      }
    }
  }
}
```
###### Example
```js
{
  vhs: {
    captionServices: {
      CC1: {
        language: 'en',
        label: 'English'
      },
      SERVICE1: {
        langauge: 'kr',
        label: 'Korean',
        encoding: 'euc-kr'
        default: true,
      }
    }
  }
}
```

### Runtime Properties
Runtime properties are attached to the tech object when HLS is in
use. You can get a reference to the VHS source handler like this:

```javascript
var vhs = player.tech().vhs;
```

If you *were* thinking about modifying runtime properties in a
video.js plugin, we'd recommend you avoid it. Your plugin won't work
with videos that don't use videojs-http-streaming and the best plugins
work across all the media types that video.js supports. If you're
deploying videojs-http-streaming on your own website and want to make a
couple tweaks though, go for it!

#### vhs.playlists.master
Type: `object`

An object representing the parsed master playlist. If a media playlist
is loaded directly, a master playlist with only one entry will be
created.

#### vhs.playlists.media
Type: `function`

A function that can be used to retrieve or modify the currently active
media playlist. The active media playlist is referred to when
additional video data needs to be downloaded. Calling this function
with no arguments returns the parsed playlist object for the active
media playlist. Calling this function with a playlist object from the
master playlist or a URI string as specified in the master playlist
will kick off an asynchronous load of the specified media
playlist. Once it has been retreived, it will become the active media
playlist.

#### vhs.systemBandwidth
Type: `number`

`systemBandwidth` is a combination of two serial processes' bitrates. The first
is the network bitrate provided by `bandwidth` and the second is the bitrate of
the entire process after that (decryption, transmuxing, and appending) provided
by `throughput`. This value is used by the default implementation of `selectPlaylist`
to select an appropriate bitrate to play.

Since the two process are serial, the overall system bandwidth is given by:
`systemBandwidth = 1 / (1 / bandwidth + 1 / throughput)`

#### vhs.bandwidth
Type: `number`

The number of bits downloaded per second in the last segment download.

Before the first video segment has been downloaded, it's hard to
estimate bandwidth accurately. The HLS tech uses a starting value of 4194304 or 0.5 MB/s. If you
have a more accurate source of bandwidth information, you can override
this value as soon as the HLS tech has loaded to provide an initial
bandwidth estimate.

#### vhs.throughput
Type: `number`

The number of bits decrypted, transmuxed, and appended per second as a cumulative average across active processing time.

#### vhs.selectPlaylist
Type: `function`

A function that returns the media playlist object to use to download
the next segment. It is invoked by the tech immediately before a new
segment is downloaded. You can override this function to provide your
adaptive streaming logic. You must, however, be sure to return a valid
media playlist object that is present in `player.tech().vhs.master`.

Overridding this function with your own is very powerful but is overkill
for many purposes. Most of the time, you should use the much simpler
function below to selectively enable or disable a playlist from the
adaptive streaming logic.

#### vhs.representations
Type: `function`

It is recommended to include the [videojs-contrib-quality-levels](https://github.com/videojs/videojs-contrib-quality-levels) plugin to your page so that videojs-http-streaming will automatically populate the QualityLevelList exposed on the player by the plugin. You can access this list by calling `player.qualityLevels()`. See the [videojs-contrib-quality-levels project page](https://github.com/videojs/videojs-contrib-quality-levels) for more information on how to use the api.

Example, only enabling representations with a width greater than or equal to 720:

```javascript
var qualityLevels = player.qualityLevels();

for (var i = 0; i < qualityLevels.length; i++) {
  var quality = qualityLevels[i];
  if (quality.width >= 720) {
    quality.enabled = true;
  } else {
    quality.enabled = false;
  }
}
```

If including [videojs-contrib-quality-levels](https://github.com/videojs/videojs-contrib-quality-levels) is not an option, you can use the representations api. To get all of the available representations, call the `representations()` method on `player.tech().vhs`. This will return a list of plain objects, each with `width`, `height`, `bandwidth`, and `id` properties, and an `enabled()` method.

```javascript
player.tech().vhs.representations();
```

To see whether the representation is enabled or disabled, call its `enabled()` method with no arguments. To set whether it is enabled/disabled, call its `enabled()` method and pass in a boolean value. Calling `<representation>.enabled(true)` will allow the adaptive bitrate algorithm to select the representation while calling `<representation>.enabled(false)` will disallow any selection of that representation.

Example, only enabling representations with a width greater than or equal to 720:

```javascript
player.tech().vhs.representations().forEach(function(rep) {
  if (rep.width >= 720) {
    rep.enabled(true);
  } else {
    rep.enabled(false);
  }
});
```

#### vhs.xhr
Type: `function`

The xhr function that is used by HLS internally is exposed on the per-
player `vhs` object. While it is possible, we do not recommend replacing
the function with your own implementation. Instead, the `xhr` provides
the ability to specify a `beforeRequest` function that will be called
with an object containing the options that will be used to create the
xhr request.

Example:
```javascript
player.tech().vhs.xhr.beforeRequest = function(options) {
  options.uri = options.uri.replace('example.com', 'foo.com');

  return options;
};
```

The global `videojs.Vhs` also exposes an `xhr` property. Specifying a
`beforeRequest` function on that will allow you to intercept the options
for *all* requests in every player on a page. For consistency across
browsers the video source should be set at runtime once the video player
is ready.

Example
```javascript
videojs.Vhs.xhr.beforeRequest = function(options) {
  /*
   * Modifications to requests that will affect every player.
   */

  return options;
};

var player = videojs('video-player-id');
player.ready(function() {
  this.src({
    src: 'https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8',
    type: 'application/x-mpegURL',
  });
});
```

For information on the type of options that you can modify see the
documentation at [https://github.com/Raynos/xhr](https://github.com/Raynos/xhr).

#### vhs.stats
Type: `object`

This object contains a summary of HLS and player related stats.

| Property Name         | Type   | Description |
| --------------------- | ------ | ----------- |
| bandwidth             | number | Rate of the last segment download in bits/second |
| mediaRequests         | number | Total number of media segment requests |
| mediaRequestsAborted  | number | Total number of aborted media segment requests |
| mediaRequestsTimedout | number | Total number of timedout media segment requests |
| mediaRequestsErrored  | number | Total number of errored media segment requests |
| mediaTransferDuration | number | Total time spent downloading media segments in milliseconds |
| mediaBytesTransferred | number | Total number of content bytes downloaded |
| mediaSecondsLoaded    | number | Total number of content seconds downloaded |
| buffered              | array  | List of time ranges of content that are in the SourceBuffer |
| currentTime           | number | The current position of the player |
| currentSource         | object | The source object. Has the structure `{src: 'url', type: 'mimetype'}` |
| currentTech           | string | The name of the tech in use |
| duration              | number | Duration of the video in seconds |
| master                | object | The [master playlist object](#vhsplaylistsmaster) |
| playerDimensions      | object | Contains the width and height of the player |
| seekable              | array  | List of time ranges that the player can seek to |
| timestamp             | number | Timestamp of when `vhs.stats` was accessed |
| videoPlaybackQuality  | object | Media playback quality metrics as specified by the [W3C's Media Playback Quality API](https://wicg.github.io/media-playback-quality/) |


### Events
Standard HTML video events are handled by video.js automatically and
are triggered on the player object.

#### loadedmetadata

Fired after the first segment is downloaded for a playlist. This will not happen
until playback if video.js's `metadata` setting is `none`

### VHS Usage Events

Usage tracking events are fired when we detect a certain HLS feature, encoding setting,
or API is used. These can be helpful for analytics, and to pinpoint the cause of HLS errors.
For instance, if errors are being fired in tandem with a usage event indicating that the
player was playing an AES encrypted stream, then we have a possible avenue to explore when
debugging the error.

Note that although these usage events are listed below, they may change at any time without
a major version change.

VHS usage events are triggered on the tech with the exception of the 3 vhs-reload-error
events, which are triggered on the player.

To listen for usage events triggered on the tech, listen for the event type of `'usage'`:

```javascript
player.on('ready', () => {
  player.tech().on('usage', (e) => {
    console.log(e.name);
  });
});
```

Note that these events are triggered as soon as a case is encountered, and often only
once. For example, the `vhs-demuxed` usage event will be triggered as soon as the master
manifest is downloaded and parsed, and will not be triggered again.

#### Presence Stats

Each of the following usage events are fired once per source if (and when) detected:

| Name          | Description   |
| ------------- | ------------- |
| vhs-webvtt    | master manifest has at least one segmented WebVTT playlist |
| vhs-aes       | a playlist is AES encrypted |
| vhs-fmp4      | a playlist used fMP4 segments |
| vhs-demuxed   | audio and video are demuxed by default |
| vhs-alternate-audio | alternate audio available in the master manifest |
| vhs-playlist-cue-tags | a playlist used cue tags (see useCueTags(#usecuetags) for details) |
| vhs-bandwidth-from-local-storage | starting bandwidth was retrieved from local storage (see useBandwidthFromLocalStorage(#useBandwidthFromLocalStorage) for details) |
| vhs-throughput-from-local-storage | starting throughput was retrieved from local storage (see useBandwidthFromLocalStorage(#useBandwidthFromLocalStorage) for details) |

#### Use Stats

Each of the following usage events are fired per use:

| Name          | Description   |
| ------------- | ------------- |
| vhs-gap-skip  | player skipped a gap in the buffer |
| vhs-player-access | player.vhs was accessed |
| vhs-audio-change | a user selected an alternate audio stream |
| vhs-rendition-disabled | a rendition was disabled |
| vhs-rendition-enabled | a rendition was enabled |
| vhs-rendition-blacklisted | a rendition was blacklisted |
| vhs-timestamp-offset | a timestamp offset was set in HLS (can identify discontinuities) |
| vhs-unknown-waiting | the player stopped for an unknown reason and we seeked to current time try to address it |
| vhs-live-resync | playback fell off the back of a live playlist and we resynced to the live point |
| vhs-video-underflow | we seeked to current time to address video underflow |
| vhs-error-reload-initialized | the reloadSourceOnError plugin was initialized |
| vhs-error-reload | the reloadSourceOnError plugin reloaded a source |
| vhs-error-reload-canceled | an error occurred too soon after the last reload, so we didn't reload again (to prevent error loops) |


### In-Band Metadata
The HLS tech supports [timed
metadata](https://developer.apple.com/library/ios/#documentation/AudioVideo/Conceptual/HTTP_Live_Streaming_Metadata_Spec/Introduction/Introduction.html)
embedded as [ID3 tags](http://id3.org/id3v2.3.0). When a stream is
encountered with embedded metadata, an [in-band metadata text
track](https://html.spec.whatwg.org/multipage/embedded-content.html#text-track-in-band-metadata-track-dispatch-type)
will automatically be created and populated with cues as they are
encountered in the stream. UTF-8 encoded
[TXXX](http://id3.org/id3v2.3.0#User_defined_text_information_frame)
and [WXXX](http://id3.org/id3v2.3.0#User_defined_URL_link_frame) ID3
frames are mapped to cue points and their values set as the cue
text. Cues are created for all other frame types and the data is
attached to the generated cue:

```javascript
cue.value.data
```

There are lots of guides and references to using text tracks [around
the web](http://www.html5rocks.com/en/tutorials/track/basics/).

### Segment Metadata
You can get metadata about the segments currently in the buffer by using the `segment-metadata`
text track. You can get the metadata of the currently rendered segment by looking at the
track's `activeCues` array. The metadata will be attached to the `cue.value` property and
will have this structure

```javascript
cue.value = {
  byteLength, // The size of the segment in bytes
  bandwidth, // The peak bitrate reported by the segment's playlist
  resolution, // The resolution reported by the segment's playlist
  codecs, // The codecs reported by the segment's playlist
  uri, // The Segment uri
  timeline, // Timeline of the segment for detecting discontinuities
  playlist, // The Playlist uri
  start, // Segment start time
  end // Segment end time
};
```

Example:
Detect when a change in quality is rendered on screen
```javascript
let tracks = player.textTracks();
let segmentMetadataTrack;

for (let i = 0; i < tracks.length; i++) {
  if (tracks[i].label === 'segment-metadata') {
    segmentMetadataTrack = tracks[i];
  }
}

let previousPlaylist;

if (segmentMetadataTrack) {
  segmentMetadataTrack.on('cuechange', function() {
    let activeCue = segmentMetadataTrack.activeCues[0];

    if (activeCue) {
      if (previousPlaylist !== activeCue.value.playlist) {
        console.log('Switched from rendition ' + previousPlaylist +
                    ' to rendition ' + activeCue.value.playlist);
      }
      previousPlaylist = activeCue.value.playlist;
    }
  });
}
```

### Object as Source

*Note* that this is an advanced use-case, and may be more fragile for production
environments, as the schema for a VHS object and how it's used internally are not set in
stone and may change in future releases.

In normal use, VHS accepts a URL as the source of the video. But VHS also has the ability
to accept a JSON object as the source.

Passing a JSON object as the source has many uses. A couple of examples include:
* The manifest has already been downloaded, so there's no need to make another request
* You want to change some aspect of the manifest, e.g., add a segment, without modifying
  the manifest itself

In order to pass a JSON object as the source, provide a parsed manifest object in via a
[data URI](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs),
and using the "vnd.videojs.vhs+json" media type when setting the source type. For instance:

```
var player = videojs('some-video-id');
const parser = new M3u8Parser();

parser.push(manifestString);
parser.end();

player.src({
  src: `data:application/vnd.videojs.vhs+json,${JSON.stringify(parser.manifest)}`,
  type: 'application/vnd.videojs.vhs+json'
});
```

The manifest object should follow the "VHS manifest object schema" (a somewhat flexible
and informally documented structure) provided in the README of
[m3u8-parser](https://github.com/videojs/m3u8-parser) and
[mpd-parser](https://github.com/videojs/mpd-parser). This may be referred to in the
project as `vhs-json`.

## Hosting Considerations
Unlike a native HLS implementation, the HLS tech has to comply with
the browser's security policies. That means that all the files that
make up the stream must be served from the same domain as the page
hosting the video player or from a server that has appropriate [CORS
headers](https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS)
configured. Easy [instructions are
available](http://enable-cors.org/server.html) for popular webservers
and most CDNs should have no trouble turning CORS on for your account.


## Known Issues and Workarounds
Issues that are currenty known. If you want to
help find a solution that would be appreciated!

### Fragmented MP4 Support
Edge has native support for HLS but only in the MPEG2-TS container. If
you attempt to play an HLS stream with fragmented MP4 segments (without
[overriding native playback](#overridenative)), Edge will stall.
Fragmented MP4s are only supported on browsers that have
[Media Source Extensions](http://caniuse.com/#feat=mediasource) available.

### Assets with an Audio-Only Rate Get Stuck in Audio-Only
Some assets which have an audio-only rate and the lowest-bandwidth
audio + video rate isn't that low get stuck in audio-only mode. This is
because the initial bandwidth calculation thinks it there's insufficient
bandwidth for selecting the lowest-quality audio+video playlist, so it picks
the only-audio one, which unfortunately locks it to being audio-only forever,
preventing a switch to the audio+video playlist when it gets a better
estimation of bandwidth.

Until we've implemented a full fix, it is recommended to set the
[`enableLowInitialPlaylist` option](#enablelowinitialplaylist) for any assets
that include an audio-only rate; it should always select the lowest-bandwidth
audio+video playlist for its first playlist.

It's also worth mentioning that Apple no longer requires having an audio-only
rate; instead, they require a 192kbps audio+video rate (see Apple's current
[HLS Authoring Specification][]). Removing the audio-only rate would of course
eliminate this problem since there would be only audio+video playlists to
choose from.

Follow progress on this in issue [#175](https://github.com/videojs/http-streaming/issues/175).

[HLS Authoring Specification]: https://developer.apple.com/documentation/http_live_streaming/hls_authoring_specification_for_apple_devices

### DASH Assets with `$Time` Interpolation and `SegmentTimeline`s with No `t`

DASH assets which use `$Time` in a `SegmentTemplate`, and also have a
`SegmentTimeline` where only the first `S` has a `t` and the rest only have a
`d`, do not load currently.

There is currently no workaround for this, but you can track progress on this
in issue [#256](https://github.com/videojs/http-streaming/issues/256).

## Testing

For testing, you run `npm run test`. You will need Chrome and Firefox for running the tests.

_videojs-http-streaming uses [BrowserStack](https://browserstack.com) for compatibility testing._

## Debugging

videojs-http-streaming makes use of `videojs.log` for debug logging. You can enable these logs
by setting the log level to `debug` using `videojs.log.level('debug')`. You can access a complete
history of the logs using `videojs.log.history()`. This history is maintained even when the
log level is not set to `debug`.

`vhs.stats` can also be helpful when debugging. Accessing this object will give you
a snapshot summary of various HLS and player stats. See [vhs.stats](#vhsstats) for details
about what this object contains.

__NOTE__: The `debug` level is only available in video.js v6.6.0+. With earlier versions of
video.js, no debug messages will be logged to console.

## Release History
Check out the [changelog](CHANGELOG.md) for a summary of each release.

## Building
To build a copy of videojs-http-streaming run the following commands

```bash
git clone https://github.com/videojs/http-streaming
cd http-streaming
npm i
npm run build
```

videojs-http-streaming will have created all of the files for using it in a dist folder

## Development

### Tools
* Download stream locally with the [HLS Fetcher](https://github.com/videojs/hls-fetcher)
* Simulate errors with [Murphy](https://github.com/videojs/murphy)
* Inspect content with [Thumbcoil](http://thumb.co.il)

### Commands
All commands for development are listed in the `package.json` file and are run using
```bash
npm run <command>
```

[slack-icon]: http://slack.videojs.com/badge.svg
[slack-link]: http://slack.videojs.com
[travis-icon]: https://travis-ci.org/videojs/http-streaming.svg?branch=main
[travis-link]: https://travis-ci.org/videojs/http-streaming
[issue-stats-link]: http://issuestats.com/github/videojs/http-streaming
[issue-stats-pr-icon]: http://issuestats.com/github/videojs/http-streaming/badge/pr
[issue-stats-issues-icon]: http://issuestats.com/github/videojs/http-streaming/badge/issue
[greenkeeper-icon]: https://badges.greenkeeper.io/videojs/http-streaming.svg
[greenkeeper-link]: https://greenkeeper.io/
