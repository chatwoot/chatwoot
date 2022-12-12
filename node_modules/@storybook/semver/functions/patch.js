"use strict";

var SemVer = require('../classes/semver');

var patch = function patch(a, loose) {
  return new SemVer(a, loose).patch;
};

module.exports = patch;