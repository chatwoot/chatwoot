# Troubleshooting Guide

## Other troubleshooting guides

For issues around data embedded into media segments (e.g., 608 captions), see the [mux.js troubleshooting guide](https://github.com/videojs/mux.js/blob/master/docs/troubleshooting.md).

## Tools

### Thumbcoil

Thumbcoil is a video inspector tool that can unpackage various media containers and inspect the bitstreams therein. Thumbcoil runs entirely within your browser so that none of your video data is ever transmitted to a server.

http://thumb.co.il<br/>
http://beta.thumb.co.il<br/>
https://github.com/videojs/thumbcoil<br/>

## Table of Contents
- [Content plays on Mac but not on Windows](#content-plays-on-mac-but-not-windows)
- ["No compatible source was found" on IE11 Win 7](#no-compatible-source-was-found-on-ie11-win-7)
- [CORS: No Access-Control-Allow-Origin header](#cors-no-access-control-allow-origin-header)
- [Desktop Safari/iOS Safari/Android Chrome/Edge exhibit different behavior from other browsers](#desktop-safariios-safariandroid-chromeedge-exhibit-different-behavior-from-other-browsers)
- [MEDIA_ERR_DECODE error on Desktop Safari](#media_err_decode-error-on-desktop-safari)
- [Network requests are still being made while paused](#network-requests-are-still-being-made-while-paused)

## Content plays on Mac but not Windows

Some browsers may not be able to play audio sample rates higher than 48 kHz. See https://docs.microsoft.com/en-gb/windows/desktop/medfound/aac-decoder#format-constraints

Potential solution: re-encode with a Windows supported audio sample rate

## "No compatible source was found" on IE11 Win 7

videojs-http-streaming does not support Flash HLS playback (like the videojs-contrib-hls plugin does)

Solution: include the FlasHLS source handler https://github.com/brightcove/videojs-flashls-source-handler#usage

## CORS: No Access-Control-Allow-Origin header

If you see an error along the lines of

```
XMLHttpRequest cannot load ... No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin ... is therefore not allowed access.
```

you need to properly configure CORS on your server: https://github.com/videojs/http-streaming#hosting-considerations

## Desktop Safari/iOS Safari/Android Chrome/Edge exhibit different behavior from other browsers

Some browsers support native playback of certain streaming formats. By default, we defer to the native players. However, this means that features specific to videojs-http-streaming will not be available.

On Edge and mobile Chrome, 608 captions, ID3 tags or live streaming may not work as expected with native playback, it is recommended that `overrideNative` be used on those platforms if necessary.

Solution: use videojs-http-streaming based playback on those devices: https://github.com/videojs/http-streaming#overridenative

## MEDIA_ERR_DECODE error on Desktop Safari

This error may occur for a number of reasons, as it is particularly common for misconfigured content. One instance of misconfiguration is if the source manifest has `CLOSED-CAPTIONS=NONE` and an external text track is loaded into the player. Safari does not allow the inclusion any captions if the manifest indicates that captions will not be provided.

Solution: remove `CLOSED-CAPTIONS=NONE` from the manifest

## Network requests are still being made while paused

There are a couple of cases where network requests will still be made by VHS when the video is paused.

1) If the forward buffer (buffered content ahead of the playhead) has not reached the GOAL\_BUFFER\_LENGTH. For instance, if the playhead is at time 10 seconds, the buffered range goes from 5 seconds to 20 seconds, and the GOAL\_BUFFER\_LENGTH is set to 30 seconds, then segments will continue to be requested, even while paused, until the buffer ends at a time greater than or equal to 10 seconds (current time) + 30 seconds (GOAL\_BUFFER\_LENGTH) = 40 seconds. This is expected behavior in order to provide a better playback experience.

2) If the stream is LIVE, then the manifest will continue to be refreshed even while paused. This is because it is easier to keep playback in sync if we receieve manifest updates consistently.
