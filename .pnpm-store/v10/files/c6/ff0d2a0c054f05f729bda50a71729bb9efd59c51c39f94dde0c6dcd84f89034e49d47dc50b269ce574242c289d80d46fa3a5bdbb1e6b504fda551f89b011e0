# How to get player time from program time

NOTE: See the doc on [Program Time to Player Time](program-time-to-player-time.md) for definitions and an overview of the conversion process.

## Overview

To convert a program time to a player time, the following steps must be taken:

1. Find the right segment by sequentially searching through the playlist until the program time requested is >= the EXT-X-PROGRAM-DATE-TIME of the segment, and < the EXT-X-PROGRAM-DATE-TIME of the following segment (or the end of the playlist is reached).
2. Determine the segment's start and end player times.

To accomplish #2, the segment must be downloaded and transmuxed (right now only TS segments are handled, and TS is always transmuxed to FMP4). This will obtain start and end times post transmuxer modifications. These are the times that the source buffer will recieve and report for the segment's newly created MP4 fragment.

Since there isn't a simple code path for downloading a segment without appending, the easiest approach is to seek to the estimated start time of that segment using the playlist duration calculation function. Because this process is not always accurate (manifest timing values are almost never accurate), a few seeks may be required to accurately seek into that segment.

If all goes well, and the target segment is downloaded and transmuxed, the player time may be found by taking the difference between the requested program time and the EXT-X-PROGRAM-DATE-TIME of the segment, then adding that difference to `segment.videoTimingInfo.transmuxedPresentationStart`.
