"use strict";

// Determine if version is greater than all the versions possible in the range.
var outside = require('./outside');

var gtr = function gtr(version, range, options) {
  return outside(version, range, '>', options);
};

module.exports = gtr;