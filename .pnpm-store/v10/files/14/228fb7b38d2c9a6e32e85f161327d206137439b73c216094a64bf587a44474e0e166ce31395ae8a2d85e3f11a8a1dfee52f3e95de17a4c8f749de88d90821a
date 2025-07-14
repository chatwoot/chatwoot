import { limit, trimAfterFirstMatch, startsWith, endsWith } from './util.js';
describe('findNumbers/util', function () {
  it('should generate regexp limit', function () {
    var thrower = function thrower() {
      return limit(1, 0);
    };

    thrower.should["throw"]();

    thrower = function thrower() {
      return limit(-1, 1);
    };

    thrower.should["throw"]();

    thrower = function thrower() {
      return limit(0, 0);
    };

    thrower.should["throw"]();
  });
  it('should trimAfterFirstMatch', function () {
    trimAfterFirstMatch(/\d/, 'abc123').should.equal('abc');
    trimAfterFirstMatch(/\d/, 'abc').should.equal('abc');
  });
  it('should determine if a string starts with a substring', function () {
    startsWith('𐍈123', '𐍈').should.equal(true);
    startsWith('1𐍈', '𐍈').should.equal(false);
  });
  it('should determine if a string ends with a substring', function () {
    endsWith('123𐍈', '𐍈').should.equal(true);
    endsWith('𐍈1', '𐍈').should.equal(false);
  });
});
//# sourceMappingURL=util.test.js.map