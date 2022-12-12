"use strict";

require("core-js/modules/es.array.for-each");

require("core-js/modules/web.dom-collections.for-each");

var SemVer = require('../classes/semver');

var Range = require('../classes/range');

var maxSatisfying = function maxSatisfying(versions, range, options) {
  var max = null;
  var maxSV = null;
  var rangeObj = null;

  try {
    rangeObj = new Range(range, options);
  } catch (er) {
    return null;
  }

  versions.forEach(function (v) {
    if (rangeObj.test(v)) {
      // satisfies(v, range, options)
      if (!max || maxSV.compare(v) === -1) {
        // compare(max, v, true)
        max = v;
        maxSV = new SemVer(max, options);
      }
    }
  });
  return max;
};

module.exports = maxSatisfying;