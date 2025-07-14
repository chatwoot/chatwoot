# Youtube Analytics.js Plugin

Automatically track Youtube video player events as Segment events.

## Installation

The plugin is distributed as both an NPM package and as a direct export via a CDN.

### CDN

Simply add the following script tag to the `head` of your site. `YoutubeAnalytics` will be available as part of the global `window.analyticsPlugins` object.

```html
<script src="https://cdn.jsdelivr.net/npm/@segment/youtube-analytics@1/dist/youtube.min.js"></script>
```
> The above url will download the minified version of the plugin. Don’t use this version during development! You will miss out on all the nice warnings for common mistakes! To access the unminified version, simply replace `youtube.min.js` with `youtube.js`

### NPM

```bash
# latest stable
$ npm install @segment/youtube-analytics
```

## Initializing

To initialize the plugin you will need to give it access to the Youtube video player instance(s) running on your page within the Youtube `onYouTubeIframeAPIReady()` function (more information on that [here](https://developers.google.com/youtube/iframe_api_reference#Loading_a_Video_Player). This is done using the `initialize` method:

```javascript
var player;
var apiKey = 'xxxxxxxxxxxxxxxxxxxxx';
function onYouTubeIframeAPIReady() {
    player = new YT.Player('player', {
    height: '390',
    width: '640',
    videoId: 'M7lc1UVf-VE'
    });
    var ytAnalytics = new window.videoPlugins.YouTubeAnalytics(player, apiKey);
    ytAnalytics.initialize();
}
```

The plugin will now begin listening for the Youtube player lifecycle events and responding to them with Segment video events.

## Supported Events
The following [Segment Video Spec](https://segment.com/docs/spec/video/) events are tracked by this plugin:
- Video Playback Started
    - If playing a single video, this will fire when the video starts
    - If playing a playlist, this will fire when the first video in the playlist starts
- Video Playback Completed
    - If playing a single video, this will fire when the video finishes
    - If playing a playlist, this event will fire when the final video in the playlist finishes
- Video Playback Paused/Resumed
- Video Playback Buffer Started/Completed
- Video Playback Seek Started/Completed
- Video Content Started/Completed
    - For playlists, these events get fired for each individual video

## Supported Properties
The following [Segment Video Spec](https://segment.com/docs/spec/video/) properties are automatically attached to the above events:

'Playback' Events
- Total Length
- Position
- Quality

'Content' Events
- Title
- Description
- Keywords
- Channel
- Airdate
- Duration
