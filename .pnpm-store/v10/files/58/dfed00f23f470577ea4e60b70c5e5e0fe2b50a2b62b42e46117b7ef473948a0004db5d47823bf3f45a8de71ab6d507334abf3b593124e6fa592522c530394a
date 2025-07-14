# RecordRTC.js | [Live Demo](https://www.webrtc-experiment.com/RecordRTC/)

**WebRTC JavaScript Library for Audio+Video+Screen+Canvas (2D+3D animation) Recording**

[Chrome Extension](https://github.com/muaz-khan/Chrome-Extensions/tree/master/screen-recording) or [Dozens of Simple-Demos](https://www.webrtc-experiment.com/RecordRTC/simple-demos/) and [it is Open-Sourced](https://github.com/muaz-khan/RecordRTC) and has [API documentation](https://recordrtc.org/)

[![npm](https://img.shields.io/npm/v/recordrtc.svg)](https://npmjs.org/package/recordrtc) [![downloads](https://img.shields.io/npm/dm/recordrtc.svg)](https://npmjs.org/package/recordrtc) [![Build Status: Linux](https://travis-ci.org/muaz-khan/RecordRTC.png?branch=master)](https://travis-ci.org/muaz-khan/RecordRTC)

**A demo using promises:**

```javascript
let stream = await navigator.mediaDevices.getUserMedia({video: true, audio: true});
let recorder = new RecordRTCPromisesHandler(stream, {
    type: 'video'
});
recorder.startRecording();

const sleep = m => new Promise(r => setTimeout(r, m));
await sleep(3000);

await recorder.stopRecording();
let blob = await recorder.getBlob();
invokeSaveAsDialog(blob);
```

**A demo using normal coding:**

```javascript
navigator.mediaDevices.getUserMedia({
    video: true,
    audio: true
}).then(async function(stream) {
    let recorder = RecordRTC(stream, {
        type: 'video'
    });
    recorder.startRecording();

    const sleep = m => new Promise(r => setTimeout(r, m));
    await sleep(3000);

    recorder.stopRecording(function() {
        let blob = recorder.getBlob();
        invokeSaveAsDialog(blob);
    });
});
```

* [Watch a YouTube video presentation/tutorial](https://www.youtube.com/watch?v=YrLzTgdJ-Kg)

## Browsers Support

| Browser        | Operating System                    | Features               |
| -------------  |-------------                        |---------------------   |
| Google Chrome  | Windows + macOS + Ubuntu + Android  | audio + video + screen |
| Firefox        | Windows + macOS + Ubuntu + Android  | audio + video + screen |
| Opera          | Windows + macOS + Ubuntu + Android  | audio + video + screen |
| Edge (new)     | Windows (7 or 8 or 10) and MacOSX   | audio + video + screen |
| Safari         | macOS + iOS (iPhone/iPad)           | audio + video          |

## Codecs Support

| Browser       | Video               | Audio            |
| ------------- |-------------        |-------------     |
| Chrome        | VP8, VP9, H264, MKV | OPUS/VORBIS, PCM |
| Opera         | VP8, VP9, H264, MKV | OPUS/VORBIS, PCM |
| Firefox       | VP8, H264           | OPUS/VORBIS, PCM |
| Safari        | VP8                 | OPUS/VORBIS, PCM |
| Edge (new)    | VP8, VP9, H264, MKV | OPUS/VORBIS, PCM |


## CDN

```html
<!-- recommended -->
<script src="https://www.WebRTC-Experiment.com/RecordRTC.js"></script>

<!-- use 5.6.2 or any other version on cdnjs -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/RecordRTC/5.6.2/RecordRTC.js"></script>

<!-- NPM i.e. "npm install recordrtc" -->
<script src="node_modules/recordrtc/RecordRTC.js"></script>

<!-- bower -->
<script src="bower_components/recordrtc/RecordRTC.js"></script>
```

## Configuration

```javascript
const recorder = RecordRTC(stream, {
     // audio, video, canvas, gif
    type: 'video',

    // audio/webm
    // audio/webm;codecs=pcm
    // video/mp4
    // video/webm;codecs=vp9
    // video/webm;codecs=vp8
    // video/webm;codecs=h264
    // video/x-matroska;codecs=avc1
    // video/mpeg -- NOT supported by any browser, yet
    // audio/wav
    // audio/ogg  -- ONLY Firefox
    // demo: simple-demos/isTypeSupported.html
    mimeType: 'video/webm',

    // MediaStreamRecorder, StereoAudioRecorder, WebAssemblyRecorder
    // CanvasRecorder, GifRecorder, WhammyRecorder
    recorderType: MediaStreamRecorder,

    // disable logs
    disableLogs: true,

    // get intervals based blobs
    // value in milliseconds
    timeSlice: 1000,

    // requires timeSlice above
    // returns blob via callback function
    ondataavailable: function(blob) {},

    // auto stop recording if camera stops
    checkForInactiveTracks: false,

    // requires timeSlice above
    onTimeStamp: function(timestamp) {},

    // both for audio and video tracks
    bitsPerSecond: 128000,

    // only for audio track
    // ignored when codecs=pcm
    audioBitsPerSecond: 128000,

    // only for video track
    videoBitsPerSecond: 128000,

    // used by CanvasRecorder and WhammyRecorder
    // it is kind of a "frameRate"
    frameInterval: 90,

    // if you are recording multiple streams into single file
    // this helps you see what is being recorded
    previewStream: function(stream) {},

    // used by CanvasRecorder and WhammyRecorder
    // you can pass {width:640, height: 480} as well
    video: HTMLVideoElement,

    // used by CanvasRecorder and WhammyRecorder
    canvas: {
        width: 640,
        height: 480
    },

    // used by StereoAudioRecorder
    // the range 22050 to 96000.
    sampleRate: 96000,

    // used by StereoAudioRecorder
    // the range 22050 to 96000.
    // let us force 16khz recording:
    desiredSampRate: 16000,

    // used by StereoAudioRecorder
    // Legal values are (256, 512, 1024, 2048, 4096, 8192, 16384).
    bufferSize: 16384,

    // used by StereoAudioRecorder
    // 1 or 2
    numberOfAudioChannels: 2,

    // used by WebAssemblyRecorder
    frameRate: 30,

    // used by WebAssemblyRecorder
    bitrate: 128000,

    // used by MultiStreamRecorder - to access HTMLCanvasElement
    elementClass: 'multi-streams-mixer'
});
```

## MediaStream parameter

MediaStream parameter accepts following values:

```javascript
let recorder = RecordRTC(MediaStream || HTMLCanvasElement || HTMLVideoElement || HTMLElement, {});
```

## API

```javascript
RecordRTC.prototype = {
    // start the recording
    startRecording: function() {},

    // stop the recording
    // getBlob inside callback function
    stopRecording: function(blobURL) {},

    // pause the recording
    pauseRecording: function() {},

    // resume the recording
    resumeRecording: function() {},

    // auto stop recording after specific duration
    setRecordingDuration: function() {},

    // reset recorder states and remove the data
    reset: function() {},

    // invoke save as dialog
    save: function(fileName) {},

    // returns recorded Blob
    getBlob: function() {},

    // returns Blob-URL
    toURL: function() {},

    // returns Data-URL
    getDataURL: function(dataURL) {},

    // returns internal recorder
    getInternalRecorder: function() {},

    // initialize the recorder [deprecated]
    initRecorder: function() {},

    // fired if recorder's state changes
    onStateChanged: function(state) {},

    // write recorded blob into indexed-db storage
    writeToDisk: function(audio: Blob, video: Blob, gif: Blob) {},

    // get recorded blob from indexded-db storage
    getFromDisk: function(dataURL, type) {},

    // [deprecated]
    setAdvertisementArray: function([webp1, webp2]) {},

    // [deprecated] clear recorded data
    clearRecordedData: function() {},

    // clear memory; clear everything
    destroy: function() {},

    // get recorder's state
    getState: function() {},

    // [readonly] property: recorder's state
    state: string,

    // recorded blob [readonly] property
    blob: Blob,

    // [readonly] array buffer; useful only for StereoAudioRecorder
    buffer: ArrayBuffer,

    // RecordRTC version [readonly]
    version: string,

    // [readonly] useful only for StereoAudioRecorder
    bufferSize: integer,

    // [readonly] useful only for StereoAudioRecorder
    sampleRate: integer
}
```

Please check documentation here: [https://recordrtc.org/](https://recordrtc.org/)

## Global APIs

```javascript
// "bytesToSize" returns human-readable size (in MB or GB)
let size = bytesToSize(recorder.getBlob().size);

// to fix video seeking issues
getSeekableBlob(recorder.getBlob(), function(seekableBlob) {
    invokeSaveAsDialog(seekableBlob);
});

// this function invokes save-as dialog
invokeSaveAsDialog(recorder.getBlob(), 'video.webm');

// use these global variables to detect browser
let browserInfo = {isSafari, isChrome, isFirefox, isEdge, isOpera};

// use this to store blobs into IndexedDB storage
DiskStorage = {
    init: function() {},
    Fetch: function({audioBlob: Blob, videoBlob: Blob, gifBlob: Blob}) {},
    Store: function({audioBlob: Blob, videoBlob: Blob, gifBlob: Blob}) {},
    onError: function() {},
    dataStoreName: function() {}
};
```

## How to fix echo issues?

1. Set `<video>.muted=true` and `<video>.volume=0`
2. Pass `audio: {echoCancellation:true}` on getUserMedia

## Wiki

* [https://github.com/muaz-khan/RecordRTC/wiki](https://github.com/muaz-khan/RecordRTC/wiki)

## Releases

* [https://github.com/muaz-khan/RecordRTC/releases](https://github.com/muaz-khan/RecordRTC/releases)

## Unit Tests

* [https://travis-ci.org/muaz-khan/RecordRTC](https://travis-ci.org/muaz-khan/RecordRTC)

## Issues/Questions?

* Github: [https://github.com/muaz-khan/RecordRTC/issues](https://github.com/muaz-khan/RecordRTC/issues)
* Disqus: [https://www.webrtc-experiment.com/RecordRTC/#ask](https://www.webrtc-experiment.com/RecordRTC/#ask)
* Stackoverflow: [http://stackoverflow.com/questions/tagged/recordrtc](http://stackoverflow.com/questions/tagged/recordrtc)
* Email: `muazkh => gmail`

## Credits

| Library     | Usage |
| ------------- |------------|
| [Recorderjs](https://github.com/mattdiamond/Recorderjs) | StereoAudioRecorder |
| [webm-wasm](https://github.com/GoogleChromeLabs/webm-wasm) | WebAssemblyRecorder |
| [jsGif](https://github.com/antimatter15/jsgif) | GifRecorder |
| [whammy](https://github.com/antimatter15/whammy) | WhammyRecorder |

## Spec & Reference

1. [MediaRecorder API](https://w3c.github.io/mediacapture-record/MediaRecorder.html)
2. [Web Audio API](https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html)
3. [Canvas2D](http://www.w3.org/html/wg/drafts/2dcontext/html5_canvas/)
4. [Media Capture and Streams](http://www.w3.org/TR/mediacapture-streams/)

## Who is using RecordRTC?

| Framework     | Github               | Article            |
| ------------- |-------------        |-------------     |
| Angular2      | [github](https://github.com/ShankarSumanth/Angular2-RecordRTC) | [article](https://medium.com/@SumanthShankar/integrate-recordrtc-with-angular-2-typescript-942c9c4ca93f#.7x5yf2nr5) |
| React.js       | [github](https://github.com/szwang/recordrtc-react) | [article](http://suzannewang.com/recordrtc/) |
| Video.js      | [github](https://github.com/collab-project/videojs-record) | None |
| Meteor        | [github](https://github.com/launchbricklabs/recordrtc-meteor-demo) | None |

## License

[RecordRTC.js](https://github.com/muaz-khan/RecordRTC) is released under [MIT license](https://github.com/muaz-khan/RecordRTC/blob/master/LICENSE) . Copyright (c) [Muaz Khan](https://MuazKhan.com).
