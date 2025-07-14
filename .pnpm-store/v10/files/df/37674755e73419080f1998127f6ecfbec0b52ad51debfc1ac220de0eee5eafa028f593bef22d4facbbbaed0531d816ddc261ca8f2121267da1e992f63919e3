# LHLS

### Table of Contents

* [Background](#background)
* [Current Support for LHLS in VHS](#current-support-for-lhls-in-vhs)
* [Request a Segment in Pieces](#request-a-segment-in-pieces)
* [Transmux and Append Segment Pieces](#transmux-and-append-segment-pieces)
  * [videojs-contrib-media-sources background](#videojs-contrib-media-sources-background)
  * [Transmux Before Append](#transmux-before-append)
  * [Transmux Within media-segment-request](#transmux-within-media-segment-request)
  * [mux.js](#muxjs)
  * [The New Flow](#the-new-flow)
* [Resources](#resources)

### Background

LHLS stands for Low-Latency HLS (see [Periscope's post](https://medium.com/@periscopecode/introducing-lhls-media-streaming-eb6212948bef)). It's meant to be used for ultra low latency live streaming, where a server can send pieces of a segment before the segment is done being written to, and the player can append those pieces to the browser, allowing sub segment duration latency from true live.

In order to support LHLS, a few components are required:

* A server that supports [chunked transfer encoding](https://en.wikipedia.org/wiki/Chunked_transfer_encoding).
* A client that can:
  * request segment pieces
  * transmux segment pieces (for browsers that don't natively support the media type)
  * append segment pieces

### Current Support for LHLS in VHS

At the moment, VHS doesn't support any of the client requirements. It waits until a request is completed and the transmuxer expects full segments.

Current flow:

![current flow](./current-flow.plantuml.png)

Expected flow:

![expected flow](./expected-flow.plantuml.png)

### Request Segment Pieces

The first change was to request pieces of a segment. There are a few approaches to accomplish this:

* [Range Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)
  * requires server support
  * more round trips
* [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
  * limited browser support
  * doesn't support aborts
* [Plain text MIME type](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Sending_and_Receiving_Binary_Data)
  * slightly non-standard
  * incurs a cost of converting from string to bytes

*Plain text MIME type* was chosen because of its wide support. It provides a mechanism to access progressive bytes downloaded on [XMLHttpRequest progress events](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequestEventTarget/onprogress).

This change was made in [media-segment-request](https://github.com/videojs/http-streaming/blob/master/src/media-segment-request.js).

### Transmux and Append Segment Pieces

Getting the progress bytes is easy. Supporting partial transmuxing and appending is harder.

Current flow:

![current transmux and append flow](./current-transmux-and-append-flow.plantuml.png)

In order to support partial transmuxing and appending in the current flow, videojs-contrib-media-sources would have to get more complicated.

##### videojs-contrib-media-sources background

Browsers, via MSE source buffers, only support a limited set of media types. For most browsers, this means MP4/fragmented MP4. HLS uses TS segments (it also supports fragmented MP4, but that case is less common). This is why transmuxing is necessary.

Just like Video.js is a wrapper around the browser video element, bridging compatibility and adding support to extend features, videojs-contrib-media-sources provides support for more media types across different browsers by building in a transmuxer.

Not only did videojs-contrib-media-sources allow us to transmux TS to FMP4, but it also allowed us to transmux TS to FLV for flash support.

Over time, the complexity of logic grew in videojs-contrib-media-sources, and it coupled tightly with videojs-contrib-hls and videojs-http-streaming, firing events to communicate between the two.

Once flash support was moved to a distinct flash module, [via flashls](https://github.com/brightcove/videojs-flashls-source-handler), it was decided to move the videojs-contrib-media-sources logic into VHS, and to remove coupled logic by using only the native source buffers (instead of the wrapper) and transmuxing somewhere within VHS before appending.

##### Transmux Before Append

As the LHLS work started, and videojs-contrib-media-sources needed more logic, the native media source [abstraction leaked](https://en.wikipedia.org/wiki/Leaky_abstraction), adding non-standard functions to work around limitations. In addition, the logic in videojs-contrib-media-sources required more conditional paths, leading to more confusing code.

It was decided that it would be easier to do the transmux before append work in the process of adding support for LHLS. This was widely considered a *good decision*, and provided a means of reducing tech debt while adding in a new feature.

##### Transmux Within media-segment-request

Work started by moving transmuxing into segment-loader, however, we quickly realized that media-segment-request provided a better home.

media-segment-request already handled decrypting segments. If it handled transmuxing as well, then segment-loader could stick with only deciding which segment to request, getting bytes as FMP4, and appending them.

The transmuxing logic moved to a new module called segment-transmuxer, which wrapped around the [WebWorker](https://developer.mozilla.org/en-US/docs/Web/API/Worker/Worker) that wrapped around mux.js (the transmuxer itself).

##### mux.js

While most of the [mux.js pipeline](https://github.com/videojs/mux.js/blob/master/docs/diagram.png) supports pushing pieces of data (and should support LHLS by default), its "flushes" to send transmuxed data back to the caller expected full segments.

Much of the pipeline was reused, however, the top level audio and video segment streams, as well as the entry point, were rewritten so that instead of providing a full segment on flushes, each frame of video was provided individually (audio frames still flush as a group). The new concept of partial flushes was added into the pipeline to handle this case.

##### The New Flow

One benefit to transmuxing before appending is the possibility of extracting track and timing information from the segments. Previously, this required a separate parsing step to happen on the full segment. Now, it is included in the transmuxing pipeline, and comes back to us on separate callbacks.

![new segment loader sequence](./new-segment-loader-sequence.plantuml.png)

### Resources

* https://medium.com/@periscopecode/introducing-lhls-media-streaming-eb6212948bef
* https://github.com/jordicenzano/webserver-chunked-growingfiles
