"use strict";

var SemVer = require('../classes/semver');

var major = function major(a, loose) {
  return new SemVer(a, loose).major;
};

module.exports = major;