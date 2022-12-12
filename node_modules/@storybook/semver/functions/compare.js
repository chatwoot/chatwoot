"use strict";

var SemVer = require('../classes/semver');

var compare = function compare(a, b, loose) {
  return new SemVer(a, loose).compare(new SemVer(b, loose));
};

module.exports = compare;