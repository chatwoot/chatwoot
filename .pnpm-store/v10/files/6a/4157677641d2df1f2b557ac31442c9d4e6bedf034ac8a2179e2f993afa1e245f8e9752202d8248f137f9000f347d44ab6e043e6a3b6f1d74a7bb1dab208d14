/**
 * @file bin-utils.js
 */

/**
 * convert a TimeRange to text
 *
 * @param {TimeRange} range the timerange to use for conversion
 * @param {number} i the iterator on the range to convert
 * @return {string} the range in string format
 */
const textRange = function(range, i) {
  return range.start(i) + '-' + range.end(i);
};

/**
 * format a number as hex string
 *
 * @param {number} e The number
 * @param {number} i the iterator
 * @return {string} the hex formatted number as a string
 */
const formatHexString = function(e, i) {
  const value = e.toString(16);

  return '00'.substring(0, 2 - value.length) + value + (i % 2 ? ' ' : '');
};
const formatAsciiString = function(e) {
  if (e >= 0x20 && e < 0x7e) {
    return String.fromCharCode(e);
  }
  return '.';
};

/**
 * Creates an object for sending to a web worker modifying properties that are TypedArrays
 * into a new object with seperated properties for the buffer, byteOffset, and byteLength.
 *
 * @param {Object} message
 *        Object of properties and values to send to the web worker
 * @return {Object}
 *         Modified message with TypedArray values expanded
 * @function createTransferableMessage
 */
export const createTransferableMessage = function(message) {
  const transferable = {};

  Object.keys(message).forEach((key) => {
    const value = message[key];

    if (ArrayBuffer.isView(value)) {
      transferable[key] = {
        bytes: value.buffer,
        byteOffset: value.byteOffset,
        byteLength: value.byteLength
      };
    } else {
      transferable[key] = value;
    }
  });

  return transferable;
};

/**
 * Returns a unique string identifier for a media initialization
 * segment.
 *
 * @param {Object} initSegment
 *        the init segment object.
 *
 * @return {string} the generated init segment id
 */
export const initSegmentId = function(initSegment) {
  const byterange = initSegment.byterange || {
    length: Infinity,
    offset: 0
  };

  return [
    byterange.length, byterange.offset, initSegment.resolvedUri
  ].join(',');
};

/**
 * Returns a unique string identifier for a media segment key.
 *
 * @param {Object} key the encryption key
 * @return {string} the unique id for the media segment key.
 */
export const segmentKeyId = function(key) {
  return key.resolvedUri;
};

/**
 * utils to help dump binary data to the console
 *
 * @param {Array|TypedArray} data
 *        data to dump to a string
 *
 * @return {string} the data as a hex string.
 */
export const hexDump = (data) => {
  const bytes = Array.prototype.slice.call(data);
  const step = 16;
  let result = '';
  let hex;
  let ascii;

  for (let j = 0; j < bytes.length / step; j++) {
    hex = bytes.slice(j * step, j * step + step).map(formatHexString).join('');
    ascii = bytes.slice(j * step, j * step + step).map(formatAsciiString).join('');
    result += hex + ' ' + ascii + '\n';
  }

  return result;
};

export const tagDump = ({ bytes }) => hexDump(bytes);

export const textRanges = (ranges) => {
  let result = '';
  let i;

  for (i = 0; i < ranges.length; i++) {
    result += textRange(ranges, i) + ' ';
  }
  return result;
};
