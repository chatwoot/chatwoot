"use strict";

var SemVer = require('../classes/semver');

var minor = function minor(a, loose) {
  return new SemVer(a, loose).minor;
};

module.exports = minor;