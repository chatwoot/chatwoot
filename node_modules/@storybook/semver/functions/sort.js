"use strict";

require("core-js/modules/es.array.sort");

var compareBuild = require('./compare-build');

var sort = function sort(list, loose) {
  return list.sort(function (a, b) {
    return compareBuild(a, b, loose);
  });
};

module.exports = sort;