"use strict";

var parse = require('./parse');

var valid = function valid(version, options) {
  var v = parse(version, options);
  return v ? v.version : null;
};

module.exports = valid;