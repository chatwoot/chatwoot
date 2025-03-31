# Creating Test Content

## Table of Contents

- [CEA-608 Content](#creating-cea-608-content)

## Creating CEA-608 Content

- Use ffmpeg to create an MP4 file to start with:

  `ffmpeg -f lavfi -i testsrc=duration=300:size=1280x720:rate=30 -profile:v baseline -pix_fmt yuv420p output.mp4` (no audio)

   `ffmpeg -f lavfi -i testsrc=duration=300:size=1280x720:rate=30 -profile:v baseline -pix_fmt yuv420p -filter_complex "anoisesrc=d=300" output.mp4` (audio + video)

  This uses ffmpeg's built-in `testsrc` source which generates a test video pattern with a color and timestamp. For this example, we are using a duration of `300` seconds, a size of `1280x720` and a framerate of `30fps`. We also specify extra settings `profile` and `pix_fmt` to force the output to be encoded using `avc1.42C01F`.

- Create an [srt file][srt] with the captions you would like to see with their timestamps.

- Use ffmpeg to convert `ouput.mp4` to a flv file:

  `ffmpeg -i output.mp4 -acodec copy -vcodec copy output.flv`

- Use [libcaption][] to embed the captions into the flv:

  `flv+srt output.flv captions.srt with-captions.flv`

- Use ffmpeg to convert `with-captions.flv` to mp4

  `ffmpeg -i with-captions.flv -acodec copy -vcodec copy with-captions.mp4`

- Use [Bento4][bento4] to convert the file into a FMP4 file:

  `bento4 mp4fragment with-captions.mp4 \
    --verbosity 3 \
    --fragment-duration 4000 \
    --timescale 90000 \
    with-captions-fragment.mf4`

Then do *either* of the following:

- Use [Bento4][bento4] to split the file into an init segment and a fmp4 media segments:

  `bento4 mp4split --verbose \
    --init-segment with-captions-init.mp4 \
    --media-segment segs/with-captions-segment-%llu.m4s \
    with-captions-fragment.mf4`

- Use [Bento4][bento4] to create a DASH manifest:

  `bento4 mp4dash -v \
    --mpd-name=with-captions.mpd \
    --init-segment=with-captions-init.mp4 \
    --subtitles
    with-captions-fragment.mf4`

  This will create a DASH MPD and media segments in a new directory called `output`.


[srt]: https://en.wikipedia.org/wiki/SubRip#SubRip_text_file_format
[libcaption]: https://github.com/szatmary/libcaption
[bento4]: https://www.bento4.com/documentation/
