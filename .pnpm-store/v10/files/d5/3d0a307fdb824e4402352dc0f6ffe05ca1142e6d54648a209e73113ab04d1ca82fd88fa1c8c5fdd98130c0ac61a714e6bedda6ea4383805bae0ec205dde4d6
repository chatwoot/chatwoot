# Transmux Before Append Changes

## Overview

In moving our transmuxing stage from after append (to a virtual source buffer from videojs-contrib-media-sources) to before appending (to a native source buffer), some changes were required, and others made the logic simpler. What follows are some details into some of the changes made, why they were made, and what impact they will have.

### Source Buffer Creation

In a pre-TBA (transmux before append) world, videojs-contrib-media-source's source buffers provided an abstraction around the native source buffers. They also required a bit more information than the native buffers. For instance, they used the full mime types instead of simply relying on the codec information, when creating the source buffers. This provided the container types, which let the virtual source buffer know whether the media needed to be transmuxed or not. In a post-TBA world, the container type is no longer required, therefore only the codec strings are passed along.

In terms of when the source buffers are created, in the post-TBA world, the creation of source buffers is delayed until we are sure we have all of the information we need. This means that we don't create the native source buffers until the PMT is parsed from the main media. Even if the content is demuxed, we only need to parse the main media, since, for now, we don't rely on codec information from the segment itself, and instead use the manifest-provided codec info, or default codecs. While we could create the source buffers earlier if the codec information is provided in the manifest, delaying provides a simpler, single, code path, and more opportunity for us to be flexible with how much codec info is provided by the attribute. While the HLS specification requires this information, other formats may not, and we have seen content that plays fine but does not adhere to the strict rules of providing all necessary codec information.

### Appending Init Segments

Previously, init segments were handled by videojs-contrib-media-sources for TS segments and segment-loader for FMP4 segments.

videojs-contrib-media-sources and TS:
* video segments
  * append the video init segment returned from the transmuxer with every segment
* audio segments
  * append the audio init segment returned from the transmuxer only in the following cases:
    * first append
    * after timestampOffset is set
    * audio track events: change/addtrack/removetrack
    * 'mediachange' event

segment-loader and FMP4:
* if segment.map is set:
  * save (cache) the init segment after the request finished
  * append the init segment directly to the source buffer if the segment loader's activeInitSegmentId doesn't match the segment.map generated init segment ID

With the transmux before append and LHLS changes, we only append video init segments on changes as well. This is more important with LHLS, as prepending an init segment before every frame of video would be wasteful.

### Test Changes

Some tests were removed because they were no longer relevant after the change to creating source buffers later. For instance, `waits for both main and audio loaders to finish before calling endOfStream if main loader starting media is unknown` no longer can be tested by waiting for an audio loader response and checking for end of stream, as the test will time out since MasterPlaylistController will wait for track info from the main loader before the source buffers are created. That condition is checked elsewhere.
