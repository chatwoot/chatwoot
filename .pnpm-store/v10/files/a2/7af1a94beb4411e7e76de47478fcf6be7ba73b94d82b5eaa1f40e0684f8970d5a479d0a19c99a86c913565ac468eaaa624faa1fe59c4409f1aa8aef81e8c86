/**
 * Helper functions for creating ID3 metadata.
 */

'use strict';

var stringToInts, stringToCString, id3Tag, id3Frame;

stringToInts = function(string) {
  var result = [], i;
  for (i = 0; i < string.length; i++) {
    result[i] = string.charCodeAt(i);
  }
  return result;
};

stringToCString = function(string) {
  return stringToInts(string).concat([0x00]);
};

id3Tag = function() {
  var
    frames = Array.prototype.concat.apply([], Array.prototype.slice.call(arguments)),
    result = stringToInts('ID3').concat([
      0x03, 0x00,            // version 3.0 of ID3v2 (aka ID3v.2.3.0)
      0x40,                  // flags. include an extended header
      0x00, 0x00, 0x00, 0x00, // size. set later

      // extended header
      0x00, 0x00, 0x00, 0x06, // extended header size. no CRC
      0x00, 0x00,             // extended flags
      0x00, 0x00, 0x00, 0x02  // size of padding
    ], frames),
    size;

  // size is stored as a sequence of four 7-bit integers with the
  // high bit of each byte set to zero
  size = result.length - 10;

  result[6] = (size >>> 21) & 0x7f;
  result[7] = (size >>> 14) & 0x7f;
  result[8] = (size >>> 7) & 0x7f;
  result[9] = size & 0x7f;

  return result;
};

id3Frame = function(type) {
  var result = stringToInts(type).concat([
    0x00, 0x00, 0x00, 0x00, // size
    0xe0, 0x00 // flags. tag/file alter preservation, read-only
  ]),
      size = result.length - 10;

  // append the fields of the ID3 frame
  result = result.concat.apply(result, Array.prototype.slice.call(arguments, 1));

  // set the size
  size = result.length - 10;

  result[4] = (size >>> 21) & 0x7f;
  result[5] = (size >>> 14) & 0x7f;
  result[6] = (size >>> 7) & 0x7f;
  result[7] = size & 0x7f;

  return result;
};

module.exports = {
  stringToInts: stringToInts,
  stringToCString: stringToCString,
  id3Tag: id3Tag,
  id3Frame: id3Frame
};
