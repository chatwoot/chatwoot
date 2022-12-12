"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.globToRegexp = globToRegexp;

var _picomatch = require("picomatch");

function globToRegexp(glob) {
  var regex = (0, _picomatch.makeRe)(glob, {
    fastpaths: false,
    noglobstar: false,
    bash: false
  });

  if (!regex.source.startsWith('^')) {
    throw new Error(`Invalid glob: >> ${glob} >> ${regex}`);
  }

  if (!glob.startsWith('./')) {
    return regex;
  } // makeRe is sort of funny. If you pass it a directory starting with `./` it
  // creates a matcher that expects files with no prefix (e.g. `src/file.js`)
  // but if you pass it a directory that starts with `../` it expects files that
  // start with `../`. Let's make it consistent.
  // Globs starting `**` require special treatment due to the regex they
  // produce, specifically a negative look-ahead


  return new RegExp(['^\\.', glob.startsWith('./**') ? '' : '[\\\\/]', regex.source.substring(1)].join(''));
}