/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var FlvTag = require('./flv-tag.js'); // For information on the FLV format, see
// http://download.macromedia.com/f4v/video_file_format_spec_v10_1.pdf.
// Technically, this function returns the header and a metadata FLV tag
// if duration is greater than zero
// duration in seconds
// @return {object} the bytes of the FLV header as a Uint8Array


var getFlvHeader = function getFlvHeader(duration, audio, video) {
  // :ByteArray {
  var headBytes = new Uint8Array(3 + 1 + 1 + 4),
      head = new DataView(headBytes.buffer),
      metadata,
      result,
      metadataLength; // default arguments

  duration = duration || 0;
  audio = audio === undefined ? true : audio;
  video = video === undefined ? true : video; // signature

  head.setUint8(0, 0x46); // 'F'

  head.setUint8(1, 0x4c); // 'L'

  head.setUint8(2, 0x56); // 'V'
  // version

  head.setUint8(3, 0x01); // flags

  head.setUint8(4, (audio ? 0x04 : 0x00) | (video ? 0x01 : 0x00)); // data offset, should be 9 for FLV v1

  head.setUint32(5, headBytes.byteLength); // init the first FLV tag

  if (duration <= 0) {
    // no duration available so just write the first field of the first
    // FLV tag
    result = new Uint8Array(headBytes.byteLength + 4);
    result.set(headBytes);
    result.set([0, 0, 0, 0], headBytes.byteLength);
    return result;
  } // write out the duration metadata tag


  metadata = new FlvTag(FlvTag.METADATA_TAG);
  metadata.pts = metadata.dts = 0;
  metadata.writeMetaDataDouble('duration', duration);
  metadataLength = metadata.finalize().length;
  result = new Uint8Array(headBytes.byteLength + metadataLength);
  result.set(headBytes);
  result.set(head.byteLength, metadataLength);
  return result;
};

module.exports = getFlvHeader;