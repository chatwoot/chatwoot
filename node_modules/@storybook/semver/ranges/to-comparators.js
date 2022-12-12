"use strict";

require("core-js/modules/es.array.join");

require("core-js/modules/es.array.map");

require("core-js/modules/es.regexp.exec");

require("core-js/modules/es.string.split");

require("core-js/modules/es.string.trim");

var Range = require('../classes/range'); // Mostly just for testing and legacy API reasons


var toComparators = function toComparators(range, options) {
  return new Range(range, options).set.map(function (comp) {
    return comp.map(function (c) {
      return c.value;
    }).join(' ').trim().split(' ');
  });
};

module.exports = toComparators;