"use strict";

var _util = require("./util.js");

describe('findNumbers/util', function () {
  it('should generate regexp limit', function () {
    var thrower = function thrower() {
      return (0, _util.limit)(1, 0);
    };

    thrower.should["throw"]();

    thrower = function thrower() {
      return (0, _util.limit)(-1, 1);
    };

    thrower.should["throw"]();

    thrower = function thrower() {
      return (0, _util.limit)(0, 0);
    };

    thrower.should["throw"]();
  });
  it('should trimAfterFirstMatch', function () {
    (0, _util.trimAfterFirstMatch)(/\d/, 'abc123').should.equal('abc');
    (0, _util.trimAfterFirstMatch)(/\d/, 'abc').should.equal('abc');
  });
  it('should determine if a string starts with a substring', function () {
    (0, _util.startsWith)('𐍈123', '𐍈').should.equal(true);
    (0, _util.startsWith)('1𐍈', '𐍈').should.equal(false);
  });
  it('should determine if a string ends with a substring', function () {
    (0, _util.endsWith)('123𐍈', '𐍈').should.equal(true);
    (0, _util.endsWith)('𐍈1', '𐍈').should.equal(false);
  });
});
//# sourceMappingURL=util.test.js.map