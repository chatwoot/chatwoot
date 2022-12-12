"use strict";

var SemVer = require('../classes/semver');

var compareBuild = function compareBuild(a, b, loose) {
  var versionA = new SemVer(a, loose);
  var versionB = new SemVer(b, loose);
  return versionA.compare(versionB) || versionA.compareBuild(versionB);
};

module.exports = compareBuild;