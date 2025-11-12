# m3u8-parser
[![Build Status](https://travis-ci.org/videojs/m3u8-parser.svg?branch=master)](https://travis-ci.org/videojs/m3u8-parser)
[![Greenkeeper badge](https://badges.greenkeeper.io/videojs/m3u8-parser.svg)](https://greenkeeper.io/)
[![Slack Status](http://slack.videojs.com/badge.svg)](http://slack.videojs.com)

[![NPM](https://nodei.co/npm/m3u8-parser.png?downloads=true&downloadRank=true)](https://nodei.co/npm/m3u8-parser/)

m3u8 parser

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Installation](#installation)
- [Usage](#usage)
  - [Parsed Output](#parsed-output)
- [Supported Tags](#supported-tags)
  - [Basic Playlist Tags](#basic-playlist-tags)
  - [Media Segment Tags](#media-segment-tags)
  - [Media Playlist Tags](#media-playlist-tags)
  - [Master Playlist Tags](#master-playlist-tags)
  - [Experimental Tags](#experimental-tags)
    - [EXT-X-CUE-OUT](#ext-x-cue-out)
    - [EXT-X-CUE-OUT-CONT](#ext-x-cue-out-cont)
    - [EXT-X-CUE-IN](#ext-x-cue-in)
  - [Not Yet Supported](#not-yet-supported)
  - [Custom Parsers](#custom-parsers)
- [Including the Parser](#including-the-parser)
  - [`<script>` Tag](#script-tag)
  - [Browserify](#browserify)
  - [RequireJS/AMD](#requirejsamd)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
## Installation

```sh
npm install --save m3u8-parser
```

The npm installation is preferred, but Bower works, too.

```sh
bower install  --save m3u8-parser
```

## Usage

```js
var manifest = [
  '#EXTM3U',
  '#EXT-X-VERSION:3',
  '#EXT-X-TARGETDURATION:6',
  '#EXT-X-MEDIA-SEQUENCE:0',
  '#EXT-X-DISCONTINUITY-SEQUENCE:0',
  '#EXTINF:6,',
  '0.ts',
  '#EXTINF:6,',
  '1.ts',
  '#EXTINF:6,',
  '2.ts',
  '#EXT-X-ENDLIST'
].join('\n');

var parser = new m3u8Parser.Parser();

parser.push(manifest);
parser.end();

var parsedManifest = parser.manifest;
```

### Parsed Output

The parser ouputs a plain javascript object with the following structure:

```js
Manifest {
  allowCache: boolean,
  endList: boolean,
  mediaSequence: number,
  discontinuitySequence: number,
  playlistType: string,
  custom: {},
  playlists: [
    {
      attributes: {},
      Manifest
    }
  ],
  mediaGroups: {
    AUDIO: {
      'GROUP-ID': {
        NAME: {
          default: boolean,
          autoselect: boolean,
          language: string,
          uri: string,
          instreamId: string,
          characteristics: string,
          forced: boolean
        }
      }
    },
    VIDEO: {},
    'CLOSED-CAPTIONS': {},
    SUBTITLES: {}
  },
  dateTimeString: string,
  dateTimeObject: Date,
  targetDuration: number,
  totalDuration: number,
  discontinuityStarts: [number],
  segments: [
    {
      byterange: {
        length: number,
        offset: number
      },
      duration: number,
      attributes: {},
      discontinuity: number,
      uri: string,
      timeline: number,
      key: {
        method: string,
        uri: string,
        iv: string
      },
      map: {
        uri: string,
        byterange: {
          length: number,
          offset: number
        }
      },
      'cue-out': string,
      'cue-out-cont': string,
      'cue-in': string,
      custom: {}
    }
  ]
}
```

## Supported Tags

### Basic Playlist Tags

* [EXTM3U](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.1.1)
* [EXT-X-VERSION](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.1.2)

### Media Segment Tags

* [EXTINF](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.1)
* [EXT-X-BYTERANGE](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.2)
* [EXT-X-DISCONTINUITY](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.3)
* [EXT-X-KEY](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.4)
* [EXT-X-MAP](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.5)
* [EXT-X-PROGRAM-DATE-TIME](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.6)

### Media Playlist Tags

* [EXT-X-TARGETDURATION](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.1)
* [EXT-X-MEDIA-SEQUENCE](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.2)
* [EXT-X-DISCONTINUITY-SEQUENCE](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.3)
* [EXT-X-ENDLIST](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.4)
* [EXT-X-PLAYLIST-TYPE](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.5)
* [EXT-X-START](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.5.2)

### Master Playlist Tags

* [EXT-X-MEDIA](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.4.1)
* [EXT-X-STREAM-INF](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.4.2)

### Experimental Tags

m3u8-parser supports 3 additional **Media Segment Tags** not present in the HLS specification.

#### EXT-X-CUE-OUT

The `EXT-X-CUE-OUT` indicates that the following media segment is a break in main content and the start of interstitial content. Its format is:

```
#EXT-X-CUE-OUT:<duration>
```

where `duration` is a decimal-floating-point or decimal-integer number that specifies the total duration of the interstitial in seconds.

#### EXT-X-CUE-OUT-CONT

The `EXT-X-CUE-OUT-CONT` indicates that the following media segment is a part of interstitial content and not the main content. Every media segment following a media segment with an `EXT-X-CUE-OUT` tag *SHOULD* have an `EXT-X-CUE-OUT-CONT` applied to it until there is an `EXT-X-CUE-IN` tag. A media segment between a `EXT-X-CUE-OUT` and `EXT-X-CUE-IN` segment without a `EXT-X-CUE-OUT-CONT` is assumed to be part of the interstitial. Its format is:

```
#EXT-X-CUE-OUT-CONT:<n>/<duration>
```

where `n` is a decimal-floating-point or decimal-integer number that specifies the time in seconds the first sample of the media segment lies within the interstitial content and `duration` is a decimal-floating-point or decimal-integer number that specifies the total duration of the interstitial in seconds. `n` *SHOULD* be the sum of `EXTINF` durations for all preceding media segments up to the `EXT-X-CUE-OUT` tag for the current interstitial. `duration` *SHOULD* match the `duration` specified in the `EXT-X-CUE-OUT` tag for the current interstitial.'

#### EXT-X-CUE-IN

The `EXT-X-CUE-IN` indicates the end of the interstitial and the return of the main content. Its format is:

```
#EXT-X-CUE-IN
```

There *SHOULD* be a closing `EXT-X-CUE-IN` tag for every `EXT-X-CUE-OUT` tag. If a second `EXT-X-CUE-OUT` tag is encountered before an `EXT-X-CUE-IN` tag, the client *MAY* choose to ignore the `EXT-X-CUE-OUT` and treat it as part of the interstitial, or reject the playlist.

Example media playlist using `EXT-X-CUE-` tags.

```
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXTINF:10,
0.ts
#EXTINF:10,
1.ts
#EXT-X-CUE-OUT:30
#EXTINF:10,
2.ts
#EXT-X-CUE-OUT-CONT:10/30
#EXTINF:10,
3.ts
#EXT-X-CUE-OUT-CONT:20/30
#EXTINF:10,
4.ts
#EXT-X-CUE-IN
#EXTINF:10,
5.ts
#EXTINF:10,
6.ts
#EXT-X-ENDLIST
```

### Not Yet Supported

* [EXT-X-DATERANGE](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.2.7)
* [EXT-X-I-FRAMES-ONLY](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.3.6)
* [EXT-X-I-FRAME-STREAM-INF](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.4.3)
* [EXT-X-SESSION-DATA](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.4.4)
* [EXT-X-SESSION-KEY](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.4.5)
* [EXT-X-INDEPENDENT-SEGMENTS](http://tools.ietf.org/html/draft-pantos-http-live-streaming#section-4.3.5.1)

### Custom Parsers

To add a parser for a non-standard tag the parser object allows for the specification of custom tags using regular expressions. If a custom parser is specified, a `custom` object is appended to the manifest object.

```js
const manifest = [
  '#EXTM3U',
  '#EXT-X-VERSION:3',
  '#VOD-FRAMERATE:29.97',
  ''
].join('\n');

const parser = new m3u8Parser.Parser();
parser.addParser({
  expression: /^#VOD-FRAMERATE/,
  customType: 'framerate'
});

parser.push(manifest);
parser.end();
parser.manifest.custom.framerate // "#VOD-FRAMERATE:29.97"
```

Custom parsers may additionally be provided a data parsing function that take a line and return a value.

```js
const manifest = [
  '#EXTM3U',
  '#EXT-X-VERSION:3',
  '#VOD-FRAMERATE:29.97',
  ''
].join('\n');

const parser = new m3u8Parser.Parser();
parser.addParser({
  expression: /^#VOD-FRAMERATE/,
  customType: 'framerate',
  dataParser: function(line) {
    return parseFloat(line.split(':')[1]);
  }
});

parser.push(manifest);
parser.end();
parser.manifest.custom.framerate // 29.97
```

Custom parsers may also extract data at a segment level by passing `segment: true` to the options object. Having a segment level custom parser will add a `custom` object to the segment data.

```js
const manifest = [
    '#EXTM3U',
    '#VOD-TIMING:1511816599485',
    '#EXTINF:8.0,',
    'ex1.ts',
    ''
  ].join('\n');

const parser = new m3u8Parser.Parser();
parser.addParser({
  expression: /#VOD-TIMING/,
  customType: 'vodTiming',
  segment: true
});

parser.push(manifest);
parser.end();
parser.manifest.segments[0].custom.vodTiming // #VOD-TIMING:1511816599485
```

Custom parsers may also map a tag to another tag. The old tag will not be replaced and all matching registered mappers and parsers will be executed.
```js
const manifest = [
    '#EXTM3U',
    '#EXAMPLE',
    '#EXTINF:8.0,',
    'ex1.ts',
    ''
  ].join('\n');

const parser = new m3u8Parser.Parser();
parser.addTagMapper({
  expression: /#EXAMPLE/,
  map(line) {
    return `#NEW-TAG:123`;
  }
});
parser.addParser({
  expression: /#NEW-TAG/,
  customType: 'mappingExample',
  segment: true
});

parser.push(manifest);
parser.end();
parser.manifest.segments[0].custom.mappingExample // #NEW-TAG:123
```

## Including the Parser

To include m3u8-parser on your website or web application, use any of the following methods.

### `<script>` Tag

This is the simplest case. Get the script in whatever way you prefer and include it on your page.

```html
<script src="//path/to/m3u8-parser.min.js"></script>
<script>
  var parser = new m3u8Parser.Parser();
</script>
```

### Browserify

When using with Browserify, install m3u8-parser via npm and `require` the parser as you would any other module.

```js
var m3u8Parser = require('m3u8-parser');

var parser = new m3u8Parser.Parser();
```

With ES6:
```js
import { Parser } from 'm3u8-parser';

const parser = new Parser();
```

### RequireJS/AMD

When using with RequireJS (or another AMD library), get the script in whatever way you prefer and `require` the parser as you normally would:

```js
require(['m3u8-parser'], function(m3u8Parser) {
  var parser = new m3u8Parser.Parser();
});
```

## License

Apache-2.0. Copyright (c) Brightcove, Inc
