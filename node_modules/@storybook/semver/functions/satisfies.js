"use strict";

var Range = require('../classes/range');

var satisfies = function satisfies(version, range, options) {
  try {
    range = new Range(range, options);
  } catch (er) {
    return false;
  }

  return range.test(version);
};

module.exports = satisfies;