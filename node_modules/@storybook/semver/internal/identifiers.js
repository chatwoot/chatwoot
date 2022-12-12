"use strict";

var numeric = /^[0-9]+$/;

var compareIdentifiers = function compareIdentifiers(a, b) {
  var anum = numeric.test(a);
  var bnum = numeric.test(b);

  if (anum && bnum) {
    a = +a;
    b = +b;
  }

  return a === b ? 0 : anum && !bnum ? -1 : bnum && !anum ? 1 : a < b ? -1 : 1;
};

var rcompareIdentifiers = function rcompareIdentifiers(a, b) {
  return compareIdentifiers(b, a);
};

module.exports = {
  compareIdentifiers: compareIdentifiers,
  rcompareIdentifiers: rcompareIdentifiers
};