# Media Source Extensions Notes
A collection of findings experimenting with Media Source Extensions on
Chrome 36.

* Specifying an audio and video codec when creating a source buffer
  but passing in an initialization segment with only a video track
  results in a decode error

## ISO Base Media File Format (BMFF)

### Init Segment
A working initialization segment is outlined below. It may be possible
to trim this structure down further.

- `ftyp`
- `moov`
  - `mvhd`
  - `trak`
    - `tkhd`
    - `mdia`
      - `mdhd`
      - `hdlr`
      - `minf`
  - `mvex`

### Media Segment
The structure of a minimal media segment that actually encapsulates
movie data is outlined below:

- `moof`
  - `mfhd`
  - `traf`
    - `tfhd`
    - `tfdt`
    - `trun` containing samples
- `mdat`

### Structure

sample: time {number}, data {array}
chunk: samples {array}
track:  samples {array}
segment: moov {box}, mdats {array} | moof {box}, mdats {array}, data {array}

track
  chunk
    sample

movie fragment -> track fragment -> [samples]

### Sample Data Offsets
Movie-fragment Relative Addressing: all trun data offsets are relative
to the containing moof (?).

Without default-base-is-moof, the base data offset for each trun in
trafs after the first is the *end* of the previous traf.

#### iso5/DASH Style
moof
|- traf (default-base-is-moof)
|  |- trun_0 <size of moof> + 0
|   `- trun_1 <size of moof> + 100
`- traf (default-base-is-moof)
   `- trun_2 <size of moof> + 300
mdat
|- samples_for_trun_0 (100 bytes)
|- samples_for_trun_1 (200 bytes)
`- samples_for_trun_2

#### Single Track Style
moof
`- traf
   `- trun_0 <size of moof> + 0
mdat
`- samples_for_trun_0