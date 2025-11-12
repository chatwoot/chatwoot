/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
var ONE_SECOND_IN_TS = 90000,
    // 90kHz clock
secondsToVideoTs,
    secondsToAudioTs,
    videoTsToSeconds,
    audioTsToSeconds,
    audioTsToVideoTs,
    videoTsToAudioTs,
    metadataTsToSeconds;

secondsToVideoTs = function secondsToVideoTs(seconds) {
  return seconds * ONE_SECOND_IN_TS;
};

secondsToAudioTs = function secondsToAudioTs(seconds, sampleRate) {
  return seconds * sampleRate;
};

videoTsToSeconds = function videoTsToSeconds(timestamp) {
  return timestamp / ONE_SECOND_IN_TS;
};

audioTsToSeconds = function audioTsToSeconds(timestamp, sampleRate) {
  return timestamp / sampleRate;
};

audioTsToVideoTs = function audioTsToVideoTs(timestamp, sampleRate) {
  return secondsToVideoTs(audioTsToSeconds(timestamp, sampleRate));
};

videoTsToAudioTs = function videoTsToAudioTs(timestamp, sampleRate) {
  return secondsToAudioTs(videoTsToSeconds(timestamp), sampleRate);
};
/**
 * Adjust ID3 tag or caption timing information by the timeline pts values
 * (if keepOriginalTimestamps is false) and convert to seconds
 */


metadataTsToSeconds = function metadataTsToSeconds(timestamp, timelineStartPts, keepOriginalTimestamps) {
  return videoTsToSeconds(keepOriginalTimestamps ? timestamp : timestamp - timelineStartPts);
};

module.exports = {
  ONE_SECOND_IN_TS: ONE_SECOND_IN_TS,
  secondsToVideoTs: secondsToVideoTs,
  secondsToAudioTs: secondsToAudioTs,
  videoTsToSeconds: videoTsToSeconds,
  audioTsToSeconds: audioTsToSeconds,
  audioTsToVideoTs: audioTsToVideoTs,
  videoTsToAudioTs: videoTsToAudioTs,
  metadataTsToSeconds: metadataTsToSeconds
};