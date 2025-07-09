# Overview
This project supports both [HLS][hls] and [MPEG-DASH][dash] playback in the video.js player. This document is intended as a primer for anyone interested in contributing or just better understanding how bits from a server get turned into video on their display.

## HTTP Live Streaming
[HLS][apple-hls-intro] has two primary characteristics that distinguish it from other video formats:

- Delivered over HTTP(S): it uses the standard application protocol of the web to deliver all its data
- Segmented: longer videos are broken up into smaller chunks which can be downloaded independently and switched between at runtime

A standard HLS stream consists of a *Master Playlist* which references one or more *Media Playlists*. Each Media Playlist contains one or more sequential video segments. All these components form a logical hierarchy that informs the player of the different quality levels of the video available and how to address the individual segments of video at each of those levels:

![HLS Format](images/hls-format.png)

HLS streams can be delivered in two different modes: a "static" mode for videos that can be played back from any point, often referred to as video-on-demand (VOD); or a "live" mode where later portions of the video become available as time goes by. In the static mode, the Master and Media playlists are fixed. The player is guaranteed that the set of video segments referenced by those playlists will not change over time.

Live mode can work in one of two ways. For truly live events, the most common configuration is for each individual Media Playlist to only include the latest video segment and a small number of consecutive previous segments. In this mode, the player may be able to seek backwards a short time in the video but probably not all the way back to the beginning. In the other live configuration, new video segments can be appended to the Media Playlists but older segments are never removed. This configuration allows the player to seek back to the beginning of the stream at any time during the broadcast and transitions seamlessly to the static stream type when the event finishes.

If you're interested in a more in-depth treatment of the HLS format, check out [Apple's documentation][apple-hls-intro] and the IETF [Draft Specification][hls-spec].

## Dynamic Adaptive Streaming over HTTP
Similar to HLS, [DASH][dash-wiki] content is segmented and is delivered over HTTP(s).

A DASH stream consits of a *Media Presentation Description*(MPD) that describes segment metadata such as timing information, URLs, resolution and bitrate. Each segment can contain either ISO base media file format(e.g MP4) or MPEG-2 TS data. Typically, the MPD will describe the various *Representations* that map to collections of segments at different bitrates to allow bitrate selection. These Representations can be organized as a SegmentList, SegmentTemplate, SegmentBase, or SegmentTimeline.

DASH streams can be delivered in both video-on-demand(VOD) and live streaming modes. In the VOD case, the MPD describes all the segments and representations available and the player can chose which representation to play based on it's capabilities.

Live mode is accomplished using the ISOBMFF Live profile if the segments are in ISOBMFF. There are a few different ways to setup the MPD including but not limited to updating the MPD after an interval of time, using *Periods*, or using the *availabilityTimeOffset* field. A few examples of this are provided by the [DASH Reference Client][dash-if-reference-client]. The MPD will provide enough information for the player to playback the live stream and seek back as far as is specified in the MPD.

If you're interested in a more in-depth description of MPEG-DASH, check out [MDN's tutorial on setting up DASH][mdn-dash-tut] or the [DASHIF Guidelines][dash-if-guide].

# Further Documentation

- [Architechture](arch.md)
- [Glossary](glossary.md)
- [Adaptive Bitrate Switching](bitrate-switching.md)
- [Multiple Alternative Audio Tracks](multiple-alternative-audio-tracks.md)
- [reloadSourceOnError](reload-source-on-error.md)

# Helpful Tools
- [FFmpeg](http://trac.ffmpeg.org/wiki/CompilationGuide)
- [Thumbcoil](http://thumb.co.il/): web based video inspector

[hls]: /docs/intro.md#http-live-streaming
[dash]: /docs/intro.md#dynamic-adaptive-streaming-over-http
[apple-hls-intro]: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/Introduction/Introduction.html
[hls-spec]: https://datatracker.ietf.org/doc/draft-pantos-http-live-streaming/
[dash-wiki]: https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP
[dash-if-reference-client]: https://reference.dashif.org/dash.js/
[mdn-dash-tut]: https://developer.mozilla.org/en-US/Apps/Fundamentals/Audio_and_video_delivery/Setting_up_adaptive_streaming_media_sources
[dash-if-guide]: http://dashif.org/guidelines/
