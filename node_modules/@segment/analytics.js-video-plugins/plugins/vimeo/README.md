# Vimeo Analytics.js Plugin

Automatically track Vimeo video player events as Segment events.

## Installation

The plugin is distributed as both an npm [package](https://www.npmjs.com/package/@segment/vimeo-analytics) and as a direct export via the [jsDelivr](https://www.jsdelivr.com/) CDN.

### CDN

To use a built version of the plugin from the CDN, simply add the following script tag to the `head` of your site. `VimeoAnalytics` will be available as part of a globally accessible object called `window.analyticsPlugins`.

```html
<script src="https://cdn.jsdelivr.net/npm/@segment/vimeo-analytics@/dist/vimeo.min.js"></script>
```
> The above url will download the minified version of the plugin which you should use in production. To access the unminified version for use in development, simply replace `vimeo.min.js` with `vimeo.js`

### NPM

```js
// `npm install @segment/vimeo-analytics --save` OR
// `yarn add @segment/vimeo-analytics

const VimeoAnalytics = require('@segment/vimeo-analytics');
```

## Getting Started
To beging using the plugin you will need to generate an Access Token in Vimeo. The plugin will use this token to access metadata about the video content being played.

Vimeo provides documentation outlining this process [here](https://developer.vimeo.com/api/start#getting-started-step1). *Please ensure you are carefully selecting your access scopes!* The plugin only needs to read information about your video(s).

## Initializing

To initialize the plugin you will need to create a new instance of the `VimeoAnalytics` class and pass in the Vimeo.Player instance running on your page as the first argument and your Vimeo Access Token as the second.

Please read more about the constructor function in the API documentation.

Next, you will need to start the plugin by calling it's `.initialize` method. The example below assumes you are using the CDN distribution option.

```html
<iframe src="https://player.vimeo.com/video/76979871" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

<script src="https://player.vimeo.com/api/player.js"></script>
<script>
    var iframe = document.querySelector('iframe');
    var player = new Vimeo.Player(iframe);
    var VimeoAnalytics = window.analyticsPlugins.VimeoAnalytics
    var vimeoAnalytics = new VimeoAnalytics(player, 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX0365');

    vimeoAnalytics.initialize();
</script>
```

The plugin will now begin listening for the Vimeo Player lifecycle events and responding to them with Segment video events.

## API

### Constructor
```js
new VimeoAnalytics(player, accessToken);
```

The `VimeoAnalyics` constructor takes as it's arguments the instance of the Vimeo Player you would like to track events for and an Array of metadata about the video(s) that are accessible in the player.

**Please ensure that the `assetId` you pass in with each [ContentEventObject](https://segment.com/docs/spec/video/#content-event-object) is the Vimeo Id for that video.**

#### Arguments
- `player` [VimeoPlayer](https://github.com/vimeo/player.js#create-a-player)
- `accessToken` String


### Initialize
```js
vimeoAnalytics.initialize()
```

The `.initialize` method will bootstrap all the supported event listeners outlined below.

## Events

### Play
[Play](https://github.com/vimeo/player.js#play) events from the Vimeo Player will trigger [Video Content Started](https://segment.com/docs/spec/video/#video-content-started) and [Video Playback Started](https://segment.com/docs/spec/video/#video-playback-started) Segment events. If the video player was previously paused, the play event will instead trigger a [Video Playback Resumed](https://segment.com/docs/spec/video/#video-playback-resumed) event.

### Pause
[Pause](https://github.com/vimeo/player.js#pause) events from the Vimeo Player will trigger [Video Playback Paused](https://segment.com/docs/spec/video/#video-playback-paused) Segment events.

### Ended
[Ended](https://github.com/vimeo/player.js#ended) events from the Vimeo Player will trigger [Video Playback Completed](https://segment.com/docs/spec/video/#video-playback-completed) and [Video Content Completed](https://segment.com/docs/spec/video/#video-content-completed) Segment events.

### Time Update
[Time Update](https://github.com/vimeo/player.js#timeupdate) events from the Vimeo Player will trigger [Video Content Playing](https://segment.com/docs/spec/video/#video-playback-paused) "heartbeat" events every 10 seconds.
