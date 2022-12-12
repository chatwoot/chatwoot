"use strict";

var parse = require('./parse');

var prerelease = function prerelease(version, options) {
  var parsed = parse(version, options);
  return parsed && parsed.prerelease.length ? parsed.prerelease : null;
};

module.exports = prerelease;