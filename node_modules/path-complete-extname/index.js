'use strict';

// Alphabetic chars
var CHAR_UPPERCASE_A = 65; /*A*/
var CHAR_LOWERCASE_A = 97; /*a*/
var CHAR_UPPERCASE_Z = 90; /*Z*/
var CHAR_LOWERCASE_Z = 122; /*z*/
// Non-alphabetic chars.
var CHAR_DOT = 46; /*.*/
var CHAR_FORWARD_SLASH = 47; /*/*/
var CHAR_BACKWARD_SLASH = 92; /*\*/
var CHAR_COLON = 58; /*:*/

function assertPath(path) {
  if (typeof path !== 'string') {
    throw new TypeError('ERR_INVALID_ARG_TYPE');
  }
}

function isPathSeparator(code) {
  return code === CHAR_FORWARD_SLASH || code === CHAR_BACKWARD_SLASH;
}

function isWindowsDeviceRoot(code) {
  return code >= CHAR_UPPERCASE_A && code <= CHAR_UPPERCASE_Z ||
         code >= CHAR_LOWERCASE_A && code <= CHAR_LOWERCASE_Z;
}

function win32(path) {
  assertPath(path);
  var start = 0;
  var startDot = -1;
  var startPart = 0;
  var end = -1;
  var matchedSlash = true;

  // Check for a drive letter prefix so as not to mistake the following
  // path separator as an extra separator at the end of the path that can be
  // disregarded

  if (path.length >= 2 &&
      path.charCodeAt(1) === CHAR_COLON &&
      isWindowsDeviceRoot(path.charCodeAt(0))) {
    start = startPart = 2;
  }

  for (var i = path.length - 1; i >= start; --i) {
    const code = path.charCodeAt(i);
    const nextCode = path.charCodeAt(i - 1);
    if (isPathSeparator(code)) {
      // If we reached a path separator that was not part of a set of path
      // separators at the end of the string, stop now
      if (!matchedSlash) {
        startPart = i + 1;
        break;
      }
      continue;
    }
    if (end === -1) {
      // We saw the first non-path separator, mark this as the end of our
      // extension
      matchedSlash = false;
      end = i + 1;
    }
    if (code === CHAR_DOT &&
      // dot must not be first char of the filename
      i !== 0 &&
      // next char must not be a slash
      !isPathSeparator(nextCode) &&
      // previous char must not be a start dot
      i + 1 !== startDot &&
      // do not pick dot if next to drive letter chars
      (i !== 2 || start !== 2)
    ) {
      startDot = i;
    }
  }

  if (startDot === -1 ||
      end === -1 ||
      // The (right-most) trimmed path component is exactly '..'
      (startDot === end - 1 &&
       startDot === startPart + 1)) {
    return '';
  }
  return path.slice(startDot, end);
};

function posix(path) {
  assertPath(path);
  var startDot = -1;
  var startPart = 0;
  var end = -1;
  var matchedSlash = true;
  // Track the state of characters (if any) we see before our first dot and
  // after any path separator we find
  for (var i = path.length - 1; i >= 0; --i) {
    const code = path.charCodeAt(i);
    const nextCode = path.charCodeAt(i - 1);
    if (code === CHAR_FORWARD_SLASH) {
      // If we reached a path separator that was not part of a set of path
      // separators at the end of the string, stop now
      if (!matchedSlash) {
        startPart = i + 1;
        break;
      }
      continue;
    }
    if (end === -1) {
      // We saw the first non-path separator, mark this as the end of our
      // extension
      matchedSlash = false;
      end = i + 1;
    }
    if (code === CHAR_DOT &&
      // dot must not be first char of the filename
      i !== 0 &&
      // next char must not be a slash
      nextCode !== CHAR_FORWARD_SLASH &&
      // previous char must not be a start dot
      i + 1 !== startDot
    ) {
      startDot = i;
    }
  }

  if (startDot === -1 ||
      end === -1 ||
      // The (right-most) trimmed path component is exactly '..'
      (startDot === end - 1 &&
       startDot === startPart + 1)) {
    return '';
  }
  return path.slice(startDot, end);
}

module.exports = process.platform === 'win32' ? win32 : posix;
module.exports.win32 = win32;
module.exports.posix = posix;
