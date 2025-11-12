# Creating Content

## Commands for creating tests streams

### Streams with EXT-X-PROGRAM-DATE-TIME for testing seekToProgramTime and convertToProgramTime

lavfi and testsrc are provided for creating a test stream in ffmpeg
-g 300 sets the GOP size to 300 (keyframe interval, at 30fps, one keyframe every 10 seconds)
-f hls sets the format to HLS (creates an m3u8 and TS segments)
-hls\_time 10 sets the goal segment size to 10 seconds
-hls\_list\_size 20 sets the number of segments in the m3u8 file to 20
-program\_date\_time an hls flag for setting #EXT-X-PROGRAM-DATE-TIME on each segment

```
ffmpeg \
  -f lavfi \
  -i testsrc=duration=200:size=1280x720:rate=30 \
  -g 300 \
  -f hls \
  -hls_time 10 \
  -hls_list_size 20 \
  -hls_flags program_date_time \
  stream.m3u8
```

## Commands used for segments in `test/segments` dir

### video.ts

Copy only the first two video frames, leave out audio.

```
$ ffmpeg -i index0.ts -vframes 2 -an -vcodec copy video.ts
```

### videoOneSecond.ts

Blank video for 1 second, MMS-Small resolution, start at 0 PTS/DTS, 2 frames per second

```
$ ffmpeg -f lavfi -i color=c=black:s=128x96:r=2:d=1 -muxdelay 0 -c:v libx264 videoOneSecond.ts
```

### videoOneSecond1.ts through videoOneSecond4.ts

Same as videoOneSecond.ts, but follows timing in sequence, with videoOneSecond.ts acting as the 0 index. Each segment starts at the second that its index indicates (e.g., videoOneSecond2.ts has a start time of 2 seconds).

```
$ ffmpeg -i videoOneSecond.ts -muxdelay 0 -output_ts_offset 1 -vcodec copy videoOneSecond1.ts
$ ffmpeg -i videoOneSecond.ts -muxdelay 0 -output_ts_offset 2 -vcodec copy videoOneSecond2.ts
$ ffmpeg -i videoOneSecond.ts -muxdelay 0 -output_ts_offset 3 -vcodec copy videoOneSecond3.ts
$ ffmpeg -i videoOneSecond.ts -muxdelay 0 -output_ts_offset 4 -vcodec copy videoOneSecond4.ts
```

### audio.ts

Copy only the first two audio frames, leave out video.

```
$ ffmpeg -i index0.ts -aframes 2 -vn -acodec copy audio.ts
```

### videoMinOffset.ts

video.ts but with an offset of 0

```
$ ffmpeg -i video.ts -muxpreload 0 -muxdelay 0 -vcodec copy videoMinOffset.ts
```

### audioMinOffset.ts

audio.ts but with an offset of 0. Note that muxed.ts is used because ffmpeg didn't like
the use of audio.ts

```
$ ffmpeg -i muxed.ts -muxpreload 0 -muxdelay 0 -acodec copy -vn audioMinOffset.ts
```

### videoMaxOffset.ts

This segment offsets content such that it ends at exactly the max timestamp before a rollover occurs. It uses the max timestamp of 2^33 (8589934592) minus the segment duration of 6006 (0.066733 seconds) in order to not rollover mid segment, and divides the value by 90,000 to convert it from media time to seconds.

(2^33 - 6006) / 90,000 = 95443.6509556

```
$ ffmpeg -i videoMinOffset.ts -muxdelay 95443.6509556 -muxpreload 95443.6509556 -output_ts_offset 95443.6509556 -vcodec copy videoMaxOffset.ts
```

### audioMaxOffset.ts

This segment offsets content such that it ends at exactly the max timestamp before a rollover occurs. It uses the max timestamp of 2^33 (8589934592) minus the segment duration of 11520 (0.128000 seconds) in order to not rollover mid segment, and divides the value by 90,000 to convert it from media time to seconds.

(2^33 - 11520) / 90,000 = 95443.5896889

```
$ ffmpeg -i audioMinOffset.ts -muxdelay 95443.5896889 -muxpreload 95443.5896889 -output_ts_offset 95443.5896889 -acodec copy audioMaxOffset.ts
```

### videoLargeOffset.ts

This segment offsets content by the rollover threshhold of 2^32 (4294967296) found in the rollover handling of mux.js, adds 1 to ensure there aren't any cases where there's an equal match, then divides the value by 90,000 to convert it from media time to seconds.

(2^32 + 1) / 90,000 = 47721.8588556

```
$ ffmpeg -i videoMinOffset.ts -muxdelay 47721.8588556 -muxpreload 47721.8588556 -output_ts_offset 47721.8588556 -vcodec copy videoLargeOffset.ts
```

### audioLargeOffset.ts

This segment offsets content by the rollover threshhold of 2^32 (4294967296) found in the rollover handling of mux.js, adds 1 to ensure there aren't any cases where there's an equal match, then divides the value by 90,000 to convert it from media time to seconds.

(2^32 + 1) / 90,000 = 47721.8588556

```
$ ffmpeg -i audioMinOffset.ts -muxdelay 47721.8588556 -muxpreload 47721.8588556 -output_ts_offset 47721.8588556 -acodec copy audioLargeOffset.ts
```

### videoLargeOffset2.ts

This takes videoLargeOffset.ts and adds the duration of videoLargeOffset.ts (6006 / 90,000 = 0.066733 seconds) to its offset so that this segment can act as the second in one continuous stream.

47721.8588556 + 0.066733 = 47721.9255886

```
$ ffmpeg -i videoLargeOffset.ts -muxdelay 47721.9255886 -muxpreload 47721.9255886 -output_ts_offset 47721.9255886 -vcodec copy videoLargeOffset2.ts
```

### audioLargeOffset2.ts

This takes audioLargeOffset.ts and adds the duration of audioLargeOffset.ts (11520 / 90,000 = 0.128 seconds) to its offset so that this segment can act as the second in one continuous stream.

47721.8588556 + 0.128 = 47721.9868556

```
$ ffmpeg -i audioLargeOffset.ts -muxdelay 47721.9868556 -muxpreload 47721.9868556 -output_ts_offset 47721.9868556 -acodec copy audioLargeOffset2.ts
```

### caption.ts

Copy the first two frames of video out of a ts segment that already includes CEA-608 captions.

`ffmpeg -i index0.ts -vframes 2 -an -vcodec copy caption.ts`

### id3.ts

Copy only the first five frames of video, leave out audio.

`ffmpeg -i index0.ts -vframes 5 -an -vcodec copy smaller.ts`

Create an ID3 tag using [id3taggenerator][apple_streaming_tools]:

`id3taggenerator -text "{\"id\":1, \"data\": \"id3\"}" -o tag.id3`

Create a file `macro.txt` with the following:

`0 id3 tag.id3`

Run [mediafilesegmenter][apple_streaming_tools] with the small video segment and macro file, to produce a new segment with ID3 tags inserted at the specified times.

`mediafilesegmenter -start-segments-with-iframe --target-duration=1  --meta-macro-file=macro.txt -s -A smaller.ts`

### mp4Video.mp4

Copy only the first two video frames, leave out audio.
movflags:
* frag\_keyframe: "Start a new fragment at each video keyframe."
* empty\_moov: "Write an initial moov atom directly at the start of the file, without describing any samples in it."
* omit\_tfhd\_offset: "Do not write any absolute base\_data\_offset in tfhd atoms. This avoids tying fragments to absolute byte positions in the file/streams." (see also: https://www.w3.org/TR/mse-byte-stream-format-isobmff/#movie-fragment-relative-addressing)

```
$ ffmpeg -i file.mp4 -movflags frag_keyframe+empty_moov+omit_tfhd_offset -vframes 2 -an -vcodec copy mp4Video.mp4
```

### mp4Audio.mp4

Copy only the first two audio frames, leave out video.
movflags:
* frag\_keyframe: "Start a new fragment at each video keyframe."
* empty\_moov: "Write an initial moov atom directly at the start of the file, without describing any samples in it."
* omit\_tfhd\_offset: "Do not write any absolute base\_data\_offset in tfhd atoms. This avoids tying fragments to absolute byte positions in the file/streams." (see also: https://www.w3.org/TR/mse-byte-stream-format-isobmff/#movie-fragment-relative-addressing)

```
$ ffmpeg -i file.mp4 -movflags frag_keyframe+empty_moov+omit_tfhd_offset -aframes 2 -vn -acodec copy mp4Audio.mp4
```

### mp4VideoInit.mp4 and mp4AudioInit.mp4

Using DASH as the format type (-f) will lead to two init segments, one for video and one for audio. Using HLS will lead to one joined.
Renamed from .m4s to .mp4

```
$ ffmpeg -i input.mp4 -f dash out.mpd
```

### webmVideoInit.webm and webmVideo.webm

```
$ cat mp4VideoInit.mp4 mp4Video.mp4 > video.mp4
$ ffmpeg -i video.mp4 -dash_segment_type webm -c:v libvpx-vp9 -f dash output.mpd
$ mv init-stream0.webm webmVideoInit.webm
$ mv chunk-stream0-00001.webm webmVideo.webm
```

## Other useful commands

### Joined (audio and video) initialization segment (for HLS)

Using DASH as the format type (-f) will lead to two init segments, one for video and one for audio. Using HLS will lead to one joined.
Note that -hls\_fmp4\_init\_filename defaults to init.mp4, but is here for readability.
Without specifying fmp4 for hls\_segment\_type, ffmpeg defaults to ts.

```
$ ffmpeg -i input.mp4 -f hls -hls_fmp4_init_filename init.mp4 -hls_segment_type fmp4 out.m3u8
```

[apple_streaming_tools]: https://developer.apple.com/documentation/http_live_streaming/about_apple_s_http_live_streaming_tools
