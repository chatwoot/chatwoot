# Supported Features

## Browsers

Any browser that supports [MSE] (media source extensions). See
https://caniuse.com/#feat=mediasource

Note that browsers with native HLS support may play content with the native player, unless
the [overrideNative] option is used. Some notable browsers with native HLS players are:

* Safari (macOS and iOS)
* Chrome Android
* Firefox Android

However, due to the limited features offered by some of the native players, the only
browser on which VHS defaults to using the native player is Safari (macOS and iOS).

## Streaming Formats and Media Types

### Streaming Formats

VHS aims to be mostly streaming format agnostic. So long as the manifest can be parsed to
a common JSON representation, VHS should be able to play it. However, due to some large
differences between the major streaming formats (HLS and DASH), some format specific code
is included in VHS. If you have another format you would like supported, please reach out
to us (e.g., file an issue).

* [HLS] (HTTP Live Streaming)
* [MPEG-DASH] (Dynamic Adaptive Streaming over HTTP)

### Media Container Formats

* [TS] (MPEG Transport Stream)
* [MP4] (MPEG-4 Part 14: MP4, M4A, M4V, M4S, MPA), ISOBMFF
* [AAC] (Advanced Audio Coding)

### Codecs

If the content is packaged in an [MP4] container, then any codec supported by the browser
is supported. If the content is packaged in a [TS] container, then the codec must be
supported by [the transmuxer]. The following codecs are supported by the transmuxer:

* [AVC] (Advanced Video Coding, h.264)
* [AVC1] (Advnced Video Coding, h.265)
* [HE-AAC] (High Efficiency Advanced Audio Coding, mp4a.40.5)
* LC-AAC (Low Complexity Advanced Audio Coding, mp4a.40.2)

## General Notable Features

The following is a list of some, but not all, common streaming features supported by VHS.
It is meant to highlight some common use cases (and provide for easy searching), but is
not meant serve as an exhaustive list.

* VOD (video on demand)
* LIVE
* Multiple audio tracks
* Timed [ID3] Metadata is automatically translated into HTML5 metedata text tracks
* Cross-domain credentials support with [CORS]
* Any browser supported resolution (e.g., 4k)
* Any browser supported framerate (e.g., 60fps)
* [DRM] via [videojs-contrib-eme]
* Audio only (non DASH)
* Video only (non DASH)
* In-manifest [WebVTT] subtitles are automatically translated into standard HTML5 subtitle
  tracks
* [AES-128] segment encryption

## Notable Missing Features

Note that the following features have not yet been implemented or may work but are not
currently suppported in browsers that do not rely on the native player. For browsers that
use the native player (e.g., Safari for HLS), please refer to their documentation.

### Container Formats

* [WebM]
* [WAV]
* [MP3]
* [OGG]

### Codecs

If the content is packaged within an [MP4] container and the browser supports the codec, it
will play. However, the following are some codecs that are not routinely tested, or are not
supported when packaged within [TS].

* [MP3]
* [Vorbis]
* [WAV]
* [FLAC]
* [Opus]
* [VP8]
* [VP9]
* [Dolby Vision] (DVHE)
* [Dolby Digital] Audio (AC-3)
* [Dolby Digital Plus] (E-AC-3)

### HLS Missing Features

Note: features for low latency HLS in the [2nd edition of HTTP Live Streaming] are on the
roadmap, but not currently available.

VHS strives to support all of the features in the HLS specification, however, some have
not yet been implemented. VHS currently supports everything in the
[HLS specification v7, revision 23], except the following:

* Use of [EXT-X-MAP] with [TS] segments
  * [EXT-X-MAP] is currently supported for [MP4] segments, but not yet for TS
* I-Frame playlists via [EXT-X-I-FRAMES-ONLY] and [EXT-X-I-FRAME-STREAM-INF]
* [MP3] Audio
* [Dolby Digital] Audio (AC-3)
* [Dolby Digital Plus] Audio (E-AC-3)
* KEYFORMATVERSIONS of [EXT-X-KEY]
* [EXT-X-DATERANGE]
* [EXT-X-SESSION-DATA]
* [EXT-X-SESSION-KEY]
* [EXT-X-INDEPENDENT-SEGMENTS]
* Use of [EXT-X-START] (value parsed but not used)
* Alternate video via [EXT-X-MEDIA] of type video
* ASSOC-LANGUAGE in [EXT-X-MEDIA]
* CHANNELS in [EXT-X-MEDIA]
* Use of AVERAGE-BANDWIDTH in [EXT-X-STREAM-INF] (value parsed but not used)
* Use of FRAME-RATE in [EXT-X-STREAM-INF] (value parsed but not used)
* Use of HDCP-LEVEL in [EXT-X-STREAM-INF]
* SAMPLE-AES segment encryption

In the event of encoding changes within a playlist (see
https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-6.3.3), the
behavior will depend on the browser.

### DASH Missing Features

DASH support is more recent than HLS support in VHS, however, VHS strives to achieve as
complete compatibility as possible with the DASH spec. The following are some notable
features in the DASH specification that are not yet implemented in VHS:

Note that many of the following are parsed by [mpd-parser] but are either not yet used, or
simply take on their default values (in the case where they have valid defaults).

* Audio and video only streams
* Audio rendition switching
  * Each video rendition is paired with an audio rendition for the duration of playback.
* MPD
  * @id
  * @profiles
  * @availabilityStartTime
  * @availabilityEndTime
  * @minBufferTime
  * @maxSegmentDuration
  * @maxSubsegmentDuration
  * ProgramInformation
  * Metrics
* Period
  * @xlink:href
  * @xlink:actuate
  * @id
  * @duration
    * Normally used for determing the PeriodStart of the next period, VHS instead relies
      on segment durations to determine timing of each segment and timeline
  * @bitstreamSwitching
  * Subset
* AdaptationSet
  * @xlink:href
  * @xlink:actuate
  * @id
  * @group
  * @par (picture aspect ratio)
  * @minBandwidth
  * @maxBandwidth
  * @minWidth
  * @maxWidth
  * @minHeight
  * @maxHeight
  * @minFrameRate
  * @maxFrameRate
  * @segmentAlignment
  * @bitstreamSwitching
  * @subsegmentAlignment
  * @subsegmentStartsWithSAP
  * Accessibility
  * Rating
  * Viewpoint
  * ContentComponent
* Representation
  * @id (used for SegmentTemplate but not exposed otherwise)
  * @qualityRanking
  * @dependencyId (dependent representation)
  * @mediaStreamStructureId
  * SubRepresentation
* CommonAttributesElements (for AdaptationSet, Representation and SubRepresentation elements)
  * @profiles
  * @sar
  * @frameRate
  * @audioSamplingRate
  * @segmentProfiles
  * @maximumSAPPeriod
  * @startWithSAP
  * @maxPlayoutRate
  * @codingDependency
  * @scanType
  * FramePacking
  * AudioChannelConfiguration
* SegmentBase
  * @presentationTimeOffset
  * @indexRangeExact
  * RepresentationIndex
* MultipleSegmentBaseInformation elements
* SegmentList
  * @xlink:href
  * @xlink:actuate
  * MultipleSegmentBaseInformation
  * SegmentURL
    * @index
    * @indexRange
* SegmentTemplate
  * MultipleSegmentBaseInformation
  * @index
  * @bitstreamSwitching
* BaseURL
  * @serviceLocation
* Template-based Segment URL construction
  * Live DASH assets that use $Time$ in a SegmentTemplate, and also have a SegmentTimeline
    where only the first S has a t and the rest only have a d do not update on playlist
    refreshes
    See: https://github.com/videojs/http-streaming#dash-assets-with-time-interpolation-and-segmenttimelines-with-no-t
* ContentComponent elements
  * Right now manifests are assumed to have a single content component, with the properties
    described directly on the AdaptationSet element
* SubRepresentation elements
* Subset elements
* Early Available Periods (may work, but has not been tested)
* Access to subsegments via a subsegment index ('ssix')
* The @profiles attribute is ignored (best support for all profiles is attempted, without
  consideration of the specific profile). For descriptions on profiles, see section 8 of
  the DASH spec.
* Construction of byte range URLs via a BaseURL byteRange template (Annex E.2)
* Multiperiod content where the representation sets are not the same across periods
* In the event that an S element has a t attribute that is greater than what is expected,
  it is not treated as a discontinuity, but instead retains its segment value, and may
  result in a gap in the content

[MSE]: https://www.w3.org/TR/media-source/
[HLS]: https://en.wikipedia.org/wiki/HTTP_Live_Streaming
[MPEG-DASH]: https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP
[TS]: https://en.wikipedia.org/wiki/MPEG_transport_stream
[MP4]: https://en.wikipedia.org/wiki/MPEG-4_Part_14
[AAC]: https://en.wikipedia.org/wiki/Advanced_Audio_Coding
[AVC]: https://en.wikipedia.org/wiki/Advanced_Video_Coding
[AVC1]: https://en.wikipedia.org/wiki/Advanced_Video_Coding
[HE-AAC]: https://en.wikipedia.org/wiki/High-Efficiency_Advanced_Audio_Coding
[ID3]: https://en.wikipedia.org/wiki/ID3
[CORS]: https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
[DRM]: https://en.wikipedia.org/wiki/Digital_rights_management
[WebVTT]: https://www.w3.org/TR/webvtt1/
[AES-128]: https://en.wikipedia.org/wiki/Advanced_Encryption_Standard
[WebM]: https://en.wikipedia.org/wiki/WebM
[WAV]: https://en.wikipedia.org/wiki/WAV
[MP3]: https://en.wikipedia.org/wiki/MP3
[OGG]: https://en.wikipedia.org/wiki/Ogg
[Vorbis]: https://en.wikipedia.org/wiki/Vorbis
[FLAC]: https://en.wikipedia.org/wiki/FLAC
[Opus]: https://en.wikipedia.org/wiki/Opus_(audio_format)
[VP8]: https://en.wikipedia.org/wiki/VP8
[VP9]: https://en.wikipedia.org/wiki/VP9

[overrideNative]: https://github.com/videojs/http-streaming#overridenative
[the transmuxer]: https://github.com/videojs/mux.js
[videojs-contrib-eme]: https://github.com/videojs/videojs-contrib-eme

[2nd edition of HTTP Live Streaming]: https://tools.ietf.org/html/draft-pantos-hls-rfc8216bis-07.html
[HLS specification v7, revision 23]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23

[EXT-X-MAP]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.5
[EXT-X-STREAM-INF]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.4.2
[EXT-X-SESSION-DATA]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.4.4
[EXT-X-DATERANGE]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.7
[EXT-X-KEY]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.7
[EXT-X-I-FRAMES-ONLY]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.3.6
[EXT-X-I-FRAME-STREAM-INF]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.4.3
[EXT-X-SESSION-KEY]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.4.5
[EXT-X-INDEPENDENT-SEGMENTS]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.5.1
[EXT-X-START]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.5.2
[EXT-X-MEDIA]: https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.4.1

[Dolby Vision]: https://en.wikipedia.org/wiki/High-dynamic-range_video#Dolby_Vision
[Dolby Digital]: https://en.wikipedia.org/wiki/Dolby_Digital
[Dolby Digital Plus]: https://en.wikipedia.org/wiki/Dolby_Digital_Plus

[mpd-parser]: https://github.com/videojs/mpd-parser
