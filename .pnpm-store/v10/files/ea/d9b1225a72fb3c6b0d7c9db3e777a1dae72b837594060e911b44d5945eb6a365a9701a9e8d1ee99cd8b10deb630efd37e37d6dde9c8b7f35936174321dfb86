# How to get program time from player time

## Definitions

NOTE: All times referenced in seconds unless otherwise specified.

*Player Time*: any time that can be gotten/set from player.currentTime() (e.g., any time within player.seekable().start(0) to player.seekable().end(0)).<br />
*Stream Time*: any time within one of the stream's segments. Used by video frames (e.g., dts, pts, base media decode time). While these times natively use clock values, throughout the document the times are referenced in seconds.<br />
*Program Time*: any time referencing the real world (e.g., EXT-X-PROGRAM-DATE-TIME).<br />
*Start of Segment*: the pts (presentation timestamp) value of the first frame in a segment.<br />

## Overview

In order to convert from a *player time* to a *stream time*, an "anchor point" is required to match up a *player time*, *stream time*, and *program time*.

Two anchor points that are usable are the time since the start of a new timeline (e.g., the time since the last discontinuity or start of the stream), and the start of a segment. Because, in our requirements for this conversion, each segment is tagged with its *program time* in the form of an [EXT-X-PROGRAM-DATE-TIME tag](https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.6), using the segment start as the anchor point is the easiest solution. It's the closest potential anchor point to the time to convert, and it doesn't require us to track time changes across segments (e.g., trimmed or prepended content).

Those time changes are the result of the transmuxer, which can add/remove content in order to keep the content playable (without gaps or other breaking changes between segments), particularly when a segment doesn't start with a key frame.

In order to make use of the segment start, and to calculate the offset between the segment start and the time to convert, a few properties are needed:

1. The start of the segment before transmuxing
1. Time changes made to the segment during transmuxing
1. The start of the segment after transmuxing

While the start of the segment before and after transmuxing is trivial to retrieve, getting the time changes made during transmuxing is more complicated, as we must account for any trimming, prepending, and gap filling made during the transmux stage. However, the required use-case only needs the position of a video frame, allowing us to ignore any changes made to the audio timeline (because VHS uses video as the timeline of truth), as well as a couple of the video modifications.

What follows are the changes made to a video stream by the transmuxer that could alter the timeline, and if they must be accounted for in the conversion:

* Keyframe Pulling
  * Used when: the segment doesn't start with a keyframe.
  * Impact: the keyframe with the lowest dts value in the segment is "pulled" back to the first dts value in the segment, and all frames in-between are dropped.
  * Need to account in time conversion? No. If a keyframe is pulled, and frames before it are dropped, then the segment will maintain the same segment duration, and the viewer is only seeing the keyframe during that period.
* GOP Fusion
  * Used when: the segment doesn't start with a keyframe.
  * Impact: if GOPs were saved from previous segment appends, the last GOP will be prepended to the segment.
  * Need to account in time conversion? Yes. The segment is artificially extended, so while it shouldn't impact the stream time itself (since it will overlap with content already appended), it will impact the post transmux start of segment.
* GOPS to Align With
  * Used when: switching renditions, or appending segments with overlapping GOPs (intersecting time ranges).
  * Impact: GOPs in the segment will be dropped until there are no overlapping GOPs with previous segments.
  * Need to account in time conversion? No. So long as we aren't switching renditions, and the content is sane enough to not contain overlapping GOPs, this should not have a meaningful impact.

Among the changes, with only GOP Fusion having an impact, the task is simplified. Instead of accounting for any changes to the video stream, only those from GOP Fusion should be accounted for. Since GOP fusion will potentially only prepend frames to the segment, we just need the number of seconds prepended to the segment when offsetting the time. As such, we can add the following properties to each segment:

```
segment: {
  // calculated start of segment from either end of previous segment or end of last buffer
  // (in stream time)
  start,
  ...
  videoTimingInfo: {
    // number of seconds prepended by GOP fusion
    transmuxerPrependedSeconds
    // start of transmuxed segment (in player time)
    transmuxedPresentationStart
  }
}
```

## The Formula

With the properties listed above, calculating a *program time* from a *player time* is given as follows:

```
const playerTimeToProgramTime = (playerTime, segment) => {
  if (!segment.dateTimeObject) {
    // Can't convert without an "anchor point" for the program time (i.e., a time that can
    // be used to map the start of a segment with a real world time).
    return null;
  }

  const transmuxerPrependedSeconds = segment.videoTimingInfo.transmuxerPrependedSeconds;
  const transmuxedStart = segment.videoTimingInfo.transmuxedPresentationStart;

  // get the start of the content from before old content is prepended
  const startOfSegment = transmuxedStart + transmuxerPrependedSeconds;
  const offsetFromSegmentStart = playerTime - startOfSegment;

  return new Date(segment.dateTimeObject.getTime() + offsetFromSegmentStart * 1000);
};
```

## Examples

```
// Program Times:
//   segment1: 2018-11-10T00:00:30.1Z => 2018-11-10T00:00:32.1Z
//   segment2: 2018-11-10T00:00:32.1Z => 2018-11-10T00:00:34.1Z
//   segment3: 2018-11-10T00:00:34.1Z => 2018-11-10T00:00:36.1Z
//
// Player Times:
//   segment1: 0 => 2
//   segment2: 2 => 4
//   segment3: 4 => 6

const segment1 = {
  dateTimeObject: 2018-11-10T00:00:30.1Z
  videoTimingInfo: {
    transmuxerPrependedSeconds: 0,
    transmuxedPresentationStart: 0
  }
};
playerTimeToProgramTime(0.1, segment1);
// startOfSegment = 0 + 0 = 0
// offsetFromSegmentStart = 0.1 - 0 = 0.1
// return 2018-11-10T00:00:30.1Z + 0.1 = 2018-11-10T00:00:30.2Z

const segment2 = {
  dateTimeObject: 2018-11-10T00:00:32.1Z
  videoTimingInfo: {
    transmuxerPrependedSeconds: 0.3,
    transmuxedPresentationStart: 1.7
  }
};
playerTimeToProgramTime(2.5, segment2);
// startOfSegment = 1.7 + 0.3 = 2
// offsetFromSegmentStart = 2.5 - 2 = 0.5
// return 2018-11-10T00:00:32.1Z + 0.5 = 2018-11-10T00:00:32.6Z

const segment3 = {
  dateTimeObject: 2018-11-10T00:00:34.1Z
  videoTimingInfo: {
    transmuxerPrependedSeconds: 0.2,
    transmuxedPresentationStart: 3.8
  }
};
playerTimeToProgramTime(4, segment3);
// startOfSegment = 3.8 + 0.2 = 4
// offsetFromSegmentStart = 4 - 4 = 0
// return 2018-11-10T00:00:34.1Z + 0 = 2018-11-10T00:00:34.1Z
```

## Transmux Before Append Changes

Even though segment timing values are retained for transmux before append, the formula does not need to change, as all that matters for calculation is the offset from the transmuxed segment start, which can then be applied to the stream time start of segment, or the program time start of segment.

## Getting the Right Segment

In order to make use of the above calculation, the right segment must be chosen for a given player time. This time may be retrieved by simply using the times of the segment after transmuxing (as the start/end pts/dts values then reflect the player time it should slot into in the source buffer). These are included in `videoTimingInfo` as `transmuxedPresentationStart` and `transmuxedPresentationEnd`.

Although there may be a small amount of overlap due to `transmuxerPrependedSeconds`, as long as the search is sequential from the beginning of the playlist to the end, the right segment will be found, as the prepended times will only come from content from prior segments.
