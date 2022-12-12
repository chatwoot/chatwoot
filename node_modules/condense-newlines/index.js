/*!
 * condense-newlines <https://github.com/jonschlinkert/condense-newlines>
 *
 * Copyright (c) 2014 Jon Schlinkert, contributors.
 * Licensed under the MIT License
 */

'use strict';

var isWhitespace = require('is-whitespace');
var extend = require('extend-shallow');
var typeOf = require('kind-of');

module.exports = function(str, options) {
  var opts = extend({}, options);
  var sep = opts.sep || '\n\n';
  var min = opts.min;
  var re;

  if (typeof min === 'number' && min !== 2) {
    re = new RegExp('(\\r\\n|\\n|\\u2424) {' + min + ',}');
  }
  if (typeof re === 'undefined') {
    re = opts.regex || /(\r\n|\n|\u2424){2,}/g;
  }

  // if a line is 100% whitespace it will be trimmed, so that
  // later we can condense newlines correctly
  if (opts.keepWhitespace !== true) {
    str = str.split('\n').map(function(line) {
      return isWhitespace(line) ? line.trim() : line;
    }).join('\n');
  }

  str = trailingNewline(str, opts);
  return str.replace(re, sep);
};

function trailingNewline(str, options) {
  var val = options.trailingNewline;
  if (val === false) {
    return str;
  }

  switch (typeOf(val)) {
    case 'string':
      str = str.replace(/\s+$/, options.trailingNewline);
      break;
    case 'function':
      str = options.trailingNewline(str);
      break;
    case 'undefined':
    case 'boolean':
    default: {
      str = str.replace(/\s+$/, '\n');
      break;
    }
  }
  return str;
}
