# mux.js
[![Build Status](https://travis-ci.org/videojs/mux.js.svg?branch=main)](https://travis-ci.org/videojs/mux.js)[![Greenkeeper badge](https://badges.greenkeeper.io/videojs/mux.js.svg)](https://greenkeeper.io/)
[![Slack Status](http://slack.videojs.com/badge.svg)](http://slack.videojs.com)


Lightweight utilities for inspecting and manipulating video container formats.

Maintenance Status: Stable

## Table of Contents

- [Installation](#installation)
  - [NPM](#npm)
  - [Manual Build](#manual-build)
- [Building](#building)
- [Collaborator](#collaborator)
- [Contributing](#contributing)
- [Options](#options)
- [Background](#background)
  - [fmp4](#fmp4)
- [MPEG2-TS to fMP4 Transmuxer](#mpeg2-ts-to-fmp4-transmuxer)
  - [Diagram](#diagram)
- [Usage Examples](#usage-examples)
  - [Basic Usage](#basic-usage)
  - [Metadata](#metadata)
  - [MP4 Inspector](#mp4-inspector)
- [Documentation](#documentation)
- [Talk to Us](#talk-to-us)

## Installation
### NPM

To install `mux.js` with npm run

```bash
npm install --save mux.js
```

### Manual Build
Download a copy of this git repository and then follow the steps in [Building](#building)

## Building
If you're using this project in a node-like environment, just `require()` whatever you need. If you'd like to package up a distribution to include separately, run `npm run build`. See the `package.json` for other handy scripts if you're thinking about contributing.

## Collaborator
If you are a collaborator, we have a guide on how to [release](./COLLABORATOR_GUIDE.md#releasing) the project.

## Contributing
If you are interested in contributing to `mux.js`, take a look at our docs on [streams](/docs/streams.md) to get started.

## Options

The exported `muxjs` object contains the following modules:

- [codecs](#codecs): a module for handling various codecs
- [mp4](#mp4): a module for handling ISOBMFF MP4 boxes
- [flv](#flv): a module for handling Flash content
- [mp2t](#mp2t): a module for handling MPEG 2 Transport Stream content

### Codecs

#### Adts

`muxjs.codecs.Adts`

The Adts(Audio Data Transport Stream) module handles audio data, specifically AAC. Includes an `AdtsStream` that takes ADTS audio and parses out AAC frames to pass on to the next Stream component in a pipeline.

#### h264

`muxjs.codecs.h264`

The h264 module Handles H264 bitstreams, including a `NalByteStream` and `H264Stream` to parse out NAL Units and pass them on to the next Stream component in a pipeline.

### mp4

#### MP4 Generator

`muxjs.mp4.generator`

The MP4 Generator module contains multiple functions that can be used to generate fragmented MP4s (fmp4s) that can be used in MSE.

#### MP4 Probe

`muxjs.mp4.probe`

The MP4 Probe contains basic utilites that can be used to parse metadata about an MP4 segment. Some examples include: `timescale` and getting the base media decode time of a fragment in seconds.

#### MP4 Transmuxer

`muxjs.mp4.Transmuxer`

Takes MPEG2-TS segments and transmuxes them into fmp4 segments.

Options:

##### baseMediaDecodeTime

Type: `number`

Default: `0`

The Base Media Decode Time of the first segment to be passed into the transmuxer.

##### keepOriginalTimestamps

Type: `boolean`

Default: `false`

The default behavior of the MP4 Transmuxer is to rewrite the timestamps of media segments to ensure that they begin at `0` on the media timeline in MSE. To avoid this behavior, you may set this option to `true`.

**Note**: This will affect behavior of captions and metadata, and these may not align with audio and video without additional manipulation of timing metadata.

##### remux

Type: `boolean`

Default: `true`

Set to `true` to remux audio and video into a single MP4 segment.

#### CaptionParser

`muxjs.mp4.CaptionParser`

This module reads CEA-608 captions out of FMP4 segments.

#### Tools

`muxjs.mp4.tools`

This module includes utilities to parse MP4s into an equivalent javascript object, primarily for debugging purposes.

### flv

#### Transmuxer

`muxjs.flv.Transmuxer`

Takes MPEG2-TS segments and transmuxes them into FLV segments. This module is in maintenance mode and will not have further major development.

#### Tools

`muxjs.flv.tools`

This module includes utilities to parse FLV tags into an equivalent javascript object, primarily for debugging purposes.

### mp2t

`muxjs.mp2t`

Contains Streams specifically to handle MPEG2-TS data, for example `ElementaryStream` and `TransportPacketStream`. This is used in the MP4 module.

#### CaptionStream

`muxjs.mp2t.CaptionStream`

Handles the bulk of parsing CEA-608 captions out of MPEG2-TS segments.

#### Tools

`muxjs.mp2t.tools`

This module contains utilities to parse basic timing information out of MPEG2-TS segments.

## Background

### fMP4
Before making use of the Transmuxer it is best to understand the structure of a fragmented MP4 (fMP4).

fMP4's are structured in *boxes* as described in the ISOBMFF spec.

For a basic fMP4 to be valid it needs to have the following boxes:

1) ftyp (File Type Box)
2) moov (Movie Header Box)
3) moof (Movie Fragment Box)
4) mdat (Movie Data Box)

Every fMP4 stream needs to start with an `ftyp` and `moov` box which is then followed by many `moof` and `mdat` pairs.

It is important to understand that when you append your first segment to [Media Source Extensions](https://www.w3.org/TR/media-source/) that this segment will need to start with an `ftyp` and `moov` followed by a `moof` and `mdat`. A segment containing a `ftyp` and `moov` box is often referred to as an Initialization Segment(`init`) segment, and segments containing `moof` and `mdat` boxes, referring to media itself as Media Segments.

If you would like to see a clearer representation of your fMP4 you can use the `muxjs.mp4.tools.inspect()` method.

## MPEG2-TS to fMP4 Transmuxer
### Diagram
![mux.js diagram](/docs/diagram.png)

## Usage Examples

### Basic Usage

To make use of the Transmuxer method you will need to push data to the transmuxer you have created.

Feed in `Uint8Array`s of an MPEG-2 transport stream, get out a fragmented MP4.

Lets look at a very basic representation of what needs to happen the first time you want to append a fMP4 to an MSE buffer.

```js
// Create your transmuxer:
//  initOptions is optional and can be omitted at this time.
var transmuxer = new muxjs.mp4.Transmuxer(initOptions);

// Create an event listener which will be triggered after the transmuxer processes data:
//  'data' events signal a new fMP4 segment is ready
transmuxer.on('data', function (segment) {
  // This code will be executed when the event listener is triggered by a Transmuxer.push() method execution.
  // Create an empty Uint8Array with the summed value of both the initSegment and data byteLength properties.
  let data = new Uint8Array(segment.initSegment.byteLength + segment.data.byteLength);

  // Add the segment.initSegment (ftyp/moov) starting at position 0
  data.set(segment.initSegment, 0);

  // Add the segment.data (moof/mdat) starting after the initSegment
  data.set(segment.data, segment.initSegment.byteLength);

  // Uncomment this line below to see the structure of your new fMP4
  // console.log(muxjs.mp4.tools.inspect(data));

  // Add your brand new fMP4 segment to your MSE Source Buffer
  sourceBuffer.appendBuffer(data);
});

// When you push your starting MPEG-TS segment it will cause the 'data' event listener above to run.
// It is important to push after your event listener has been defined.
transmuxer.push(transportStreamSegment);
transmuxer.flush();
```

Above we are adding in the `initSegment` (ftyp/moov) to our data array before appending to the MSE Source Buffer.

This is required for the first part of data we append to the MSE Source Buffer, but we will omit the `initSegment` for our remaining chunks (moof/mdat)'s of video we are going to append to our Source Buffer.

In the case of appending additional segments after your first segment we will just need to use the following event listener anonymous function:

```js
transmuxer.on('data', function(segment){
  sourceBuffer.appendBuffer(new Uint8Array(segment.data));
});
```

Here we put all of this together in a very basic example player.

```html
<html>
  <head>
    <title>Basic Transmuxer Test</title>
  </head>
  <body>
    <video controls width="80%"></video>
    <script src="https://github.com/videojs/mux.js/releases/latest/download/mux.js"></script>
    <script>
      // Create array of TS files to play
      segments = [
        "segment-0.ts",
        "segment-1.ts",
        "segment-2.ts",
      ];

      // Replace this value with your files codec info
      mime = 'video/mp4; codecs="mp4a.40.2,avc1.64001f"';

      let mediaSource = new MediaSource();
      let transmuxer = new muxjs.mp4.Transmuxer();

      video = document.querySelector('video');
      video.src = URL.createObjectURL(mediaSource);
      mediaSource.addEventListener("sourceopen", appendFirstSegment);

      function appendFirstSegment(){
        if (segments.length == 0){
          return;
        }

        URL.revokeObjectURL(video.src);
        sourceBuffer = mediaSource.addSourceBuffer(mime);
        sourceBuffer.addEventListener('updateend', appendNextSegment);

        transmuxer.on('data', (segment) => {
          let data = new Uint8Array(segment.initSegment.byteLength + segment.data.byteLength);
          data.set(segment.initSegment, 0);
          data.set(segment.data, segment.initSegment.byteLength);
          console.log(muxjs.mp4.tools.inspect(data));
          sourceBuffer.appendBuffer(data);
        })

        fetch(segments.shift()).then((response)=>{
          return response.arrayBuffer();
        }).then((response)=>{
          transmuxer.push(new Uint8Array(response));
          transmuxer.flush();
        })
      }

      function appendNextSegment(){
        // reset the 'data' event listener to just append (moof/mdat) boxes to the Source Buffer
        transmuxer.off('data');
        transmuxer.on('data', (segment) =>{
          sourceBuffer.appendBuffer(new Uint8Array(segment.data));
        })

        if (segments.length == 0){
          // notify MSE that we have no more segments to append.
          mediaSource.endOfStream();
        }

        segments.forEach((segment) => {
          // fetch the next segment from the segments array and pass it into the transmuxer.push method
          fetch(segments.shift()).then((response)=>{
            return response.arrayBuffer();
          }).then((response)=>{
            transmuxer.push(new Uint8Array(response));
            transmuxer.flush();
          })
        })
      }
    </script>
  </body>
</html>
```
*NOTE: This player is only for example and should not be used in production.*

### Metadata

The transmuxer can also parse out supplementary video data like timed ID3 metadata and CEA-608 captions.
You can find both attached to the data event object:

```js
transmuxer.on('data', function (segment) {
  // create a metadata text track cue for each ID3 frame:
  segment.metadata.frames.forEach(function(frame) {
    metadataTextTrack.addCue(new VTTCue(time, time, frame.value));
  });
  // create a VTTCue for all the parsed CEA-608 captions:>
  segment.captions.forEach(function(cue) {
    captionTextTrack.addCue(new VTTCue(cue.startTime, cue.endTime, cue.text));
  });
});
```

### MP4 Inspector

Parse MP4s into javascript objects or a text representation for display or debugging:

```js
// drop in a Uint8Array of an MP4:
var parsed = muxjs.mp4.tools.inspect(bytes);
// dig into the boxes:
console.log('The major brand of the first box:', parsed[0].majorBrand);
// print out the structure of the MP4:
document.body.appendChild(document.createTextNode(muxjs.textifyMp4(parsed)));
```
The MP4 inspector is used extensively as a debugging tool for the transmuxer. You can see it in action by cloning the project and opening [the debug page](https://github.com/videojs/mux.js/blob/master/debug/index.html) in your browser.

## Documentation

Check out our [troubleshooting guide](/docs/troubleshooting.md).
We have some tips on [creating test content](/docs/test-content.md).
Also, check out our guide on [working with captions in Mux.js](/docs/captions.md).

## Talk to us
Drop by our slack channel (#playback) on the [Video.js slack](http://slack.videojs.com).
