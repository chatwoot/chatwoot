# <img src="https://user-images.githubusercontent.com/381895/226091100-f5567a28-7736-4d37-8f84-e08f297b7e1a.png" alt="logo" height="60" valign="middle" /> wavesurfer.js

[![npm](https://img.shields.io/npm/v/wavesurfer.js)](https://www.npmjs.com/package/wavesurfer.js) [![sponsor](https://img.shields.io/badge/sponsor_us-🤍-%23B14586)](https://github.com/sponsors/katspaugh)

**Wavesurfer.js** is an interactive waveform rendering and audio playback library, perfect for web applications. It leverages modern web technologies to provide a robust and visually engaging audio experience.

<img width="626" alt="waveform screenshot" src="https://github.com/katspaugh/wavesurfer.js/assets/381895/05f03bed-800e-4fa1-b09a-82a39a1c62ce">

**Gold sponsor 💖** [Closed Caption Creator](https://www.closedcaptioncreator.com)

## Getting started

Install and import the package:

```bash
npm install --save wavesurfer.js
```
```js
import WaveSurfer from 'wavesurfer.js'
```

Alternatively, insert a UMD script tag which exports the library as a global `WaveSurfer` variable:
```html
<script src="https://unpkg.com/wavesurfer.js@7"></script>
```

Create a wavesurfer instance and pass various [options](#wavesurfer-options):
```js
const wavesurfer = WaveSurfer.create({
  container: '#waveform',
  waveColor: '#4F4A85',
  progressColor: '#383351',
  url: '/audio.mp3',
})
```

To import one of the plugins, e.g. the [Regions plugin](https://wavesurfer.xyz/examples/?regions.js):
```js
import Regions from 'wavesurfer.js/dist/plugins/regions.esm.js'
```

Or as a script tag that will export `WaveSurfer.Regions`:
```html
<script src="https://unpkg.com/wavesurfer.js@7/dist/plugins/regions.min.js"></script>
```

TypeScript types are included in the package, so there's no need to install `@types/wavesurfer.js`.

See more [examples](https://wavesurfer.xyz/examples).

## API reference

See the wavesurfer.js documentation on our website:

 * [methods](https://wavesurfer.xyz/docs/methods)
 * [options](http://wavesurfer.xyz/docs/options)
 * [events](http://wavesurfer.xyz/docs/events)

## Plugins

We maintain a number of official plugins that add various extra features:

 * [Regions](https://wavesurfer.xyz/examples/?regions.js) – visual overlays and markers for regions of audio
 * [Timeline](https://wavesurfer.xyz/examples/?timeline.js) – displays notches and time labels below the waveform
 * [Minimap](https://wavesurfer.xyz/examples/?minimap.js) – a small waveform that serves as a scrollbar for the main waveform
 * [Envelope](https://wavesurfer.xyz/examples/?envelope.js) – a graphical interface to add fade-in and -out effects and control volume
 * [Record](https://wavesurfer.xyz/examples/?record.js) – records audio from the microphone and renders a waveform
 * [Spectrogram](https://wavesurfer.xyz/examples/?spectrogram.js) – visualization of an audio frequency spectrum (written by @akreal)
 * [Hover](https://wavesurfer.xyz/examples/?hover.js) – shows a vertical line and timestmap on waveform hover

## CSS styling

wavesurfer.js v7 is rendered into a Shadow DOM tree. This isolates its CSS from the rest of the web page.
However, it's still possible to style various wavesurfer.js elements with CSS via the `::part()` pseudo-selector.
For example:

```css
#waveform ::part(cursor):before {
  content: '🏄';
}
#waveform ::part(region) {
  font-family: fantasy;
}
```

You can see which elements you can style in the DOM inspector – they will have a `part` attribute.
See [this example](https://wavesurfer.xyz/examples/?styling.js) to play around with styling.

## Questions

Have a question about integrating wavesurfer.js on your website? Feel free to ask in our [Discussions forum](https://github.com/wavesurfer-js/wavesurfer.js/discussions/categories/q-a).

However, please keep in mind that this forum is dedicated to wavesurfer-specific questions. If you're new to JavaScript and need help with the general basics like importing NPM modules, please consider asking ChatGPT or StackOverflow first.

### FAQ

<details>
  <summary>I'm having CORS issues</summary>
  Wavesurfer fetches audio from the URL you specify in order to decode it. Make sure this URL allows fetching data from your domain. In browser JavaScript, you can only fetch data eithetr from <b>the same domain</b> or another domain if and only if that domain enables <a href="https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS">CORS</a>. So if your audio file is on an external domain, make sure that domain sends the right Access-Control-Allow-Origin headers. There's nothing you can do about it from the requesting side (i.e. your JS code).
</details>

<details>
  <summary>Does wavesurfer support large files?</summary>
  Since wavesurfer decodes audio entirely in the browser using Web Audio, large clips may fail to decode due to memory constraints. We recommend using pre-decoded peaks for large files (see <a href="https://wavesurfer.xyz/examples/?predecoded.js">this example</a>). You can use a tool like <a href="https://github.com/bbc/audiowaveform">bbc/audiowaveform</a> to generate peaks.
</details>

<details>
  <summary>What about streaming audio?</summary>
  Streaming audio is supported only with <a href="https://wavesurfer.xyz/examples/?predecoded.js">pre-decoded peaks and duration</a>.
</details>

<details>
  <summary>There is a mismatch between my audio and the waveform. How do I fix it?</summary>
  If you're using a VBR (variable bit rate) audio file, there might be a mismatch between the audio and the waveform. This can be fixed by converting your file to CBR (constant bit rate).
  <p>Alternatively, you can use the <a href="https://wavesurfer.xyz/examples/?webaudio-shim.js">Web Audio shim</a> which is more accurate.</p>
</details>

<details>
  <summary>How do I connect wavesurfer.js to Web Audio effects?</summary>
Generally, wavesurfer.js doesn't aim to be a wrapper for all things Web Audio. It's just a player with a waveform visualization. It does allow connecting itself to a Web Audio graph by exporting its audio element (see <a href="https://wavesurfer.xyz/examples/?4436ec40a2ab943243755e659ae32196">this example</a>) but nothign more than that. Please don't expect wavesurfer to be able to cut, add effects, or process your audio in any way.
</details>

## v7 – a new TypeScript version

Wavesurfer.js v7 is a TypeScript rewrite of wavesurfer.js that brings several improvements:

 * Typed API for better development experience
 * Enhanced decoding and rendering performance
 * New and improved plugins

### Upgrading from v6

Most options, events, and methods are similar to those in previous versions.

### Notable differences
 * HTML audio playback by default (used to be an opt-in via `backend: "MediaElement"`)
 * The Markers plugin is removed – you should use the Regions plugin with just a `startTime`.
 * No Microphone plugin – superseded by the new Record plugin with more features.
 * The Cursor plugin is replaced by the Hover plugin.

### Removed options
 * `audioContext`, `closeAudioContext`, `audioScriptProcessor`
 * `autoCenterImmediately` – `autoCenter` is now always immediate unless the audio is playing
 * `backgroundColor`, `hideCursor` – this can be easily set via CSS
 * `mediaType` – you should instead pass an entire media element in the `media` option. [Example](https://wavesurfer.xyz/examples/?video.js).
 * `partialRender` – done by default
 * `pixelRatio` – `window.devicePixelRatio` is used by default
 * `renderer` – there's just one renderer for now, so no need for this option
 * `responsive` – responsiveness is enabled by default
 * `scrollParent` – the container will scroll if `minPxPerSec` is set to a higher value
 * `skipLength` – there's no `skipForward` and `skipBackward` methods anymore
 * `splitChannelsOptions` – you should now use `splitChannels` to pass the channel options. Pass `height: 0` to hide a channel. See [this example](https://wavesurfer.xyz/examples/?split-channels.js).
 * `drawingContextAttributes`, `maxCanvasWidth`, `forceDecode` – removed to reduce code complexity
 * `xhr` - please use `fetchParams` instead
 * `barMinHeight` - the minimum bar height is now 1 pixel by default

### Removed methods
 * `getFilters`, `setFilter` – see the [Web Audio example](https://wavesurfer.xyz/examples/?webaudio.js)
 * `drawBuffer` – to redraw the waveform, use `setOptions` instead and pass new rendering options
 * `cancelAjax` – you can pass an [AbortSignal](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal) in `fetchParams`
 * `skipForward`, `skipBackward`, `setPlayEnd` – can be implemented using `setTime(time)`
 * `exportPCM` is replaced with `exportPeaks` which returns arrays of floats
 * `toggleMute` is now called `setMuted(true | false)`
 * `setHeight`, `setWaveColor`, `setCursorColor`, etc. – use `setOptions` with the corresponding params instead. E.g., `wavesurfer.setOptions({ height: 300, waveColor: '#abc' })`

See the complete [documentation of the new API](http://wavesurfer.xyz/docs).

## Development

To get started with development, follow these steps:

 1. Install dev dependencies:

```
yarn
```

 2. Start the TypeScript compiler in watch mode and launch an HTTP server:

```
yarn start
```

This command will open http://localhost:9090 in your browser with live reload, allowing you to see the changes as you develop.

## Tests

The tests are written in the Cypress framework. They are a mix of e2e and visual regression tests.

To run the test suite locally, first build the project:
```
yarn build
```

Then launch the tests:
```
yarn cypress
```

## Feedback

We appreciate your feedback and contributions!

If you encounter any issues or have suggestions for improvements, please don't hesitate to post in our [forum](https://github.com/wavesurfer-js/wavesurfer.js/discussions/categories/q-a).

We hope you enjoy using wavesurfer.js and look forward to hearing about your experiences with the library!
