// eslint-disable-next-line no-native-reassign, no-implicit-globals, no-global-assign
expect = (function () {
  var chai = require('chai');
  chai.config.includeStack = true;
  return chai.expect;
}());

// eslint-disable-next-line no-native-reassign, no-implicit-globals, no-global-assign
assert = (function () {
  var chai = require('chai');
  chai.config.includeStack = true;
  return chai.assert;
}());

if (typeof process === 'undefined' || !process.env.NO_ES6_SHIM) {
  require('../');
}
