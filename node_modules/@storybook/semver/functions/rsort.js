"use strict";

require("core-js/modules/es.array.sort");

var compareBuild = require('./compare-build');

var rsort = function rsort(list, loose) {
  return list.sort(function (a, b) {
    return compareBuild(b, a, loose);
  });
};

module.exports = rsort;