"use strict";

var compare = require('./compare');

var compareLoose = function compareLoose(a, b) {
  return compare(a, b, true);
};

module.exports = compareLoose;