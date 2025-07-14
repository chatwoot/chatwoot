import PatternMatcher from './AsYouTypeFormatter.PatternMatcher.js';
describe('AsYouTypeFormatter.PatternMatcher', function () {
  it('should throw when no pattern is passed', function () {
    expect(function () {
      return new PatternMatcher();
    }).to["throw"]('Pattern is required');
  });
  it('should throw when no string is passed', function () {
    var matcher = new PatternMatcher('1');
    expect(function () {
      return matcher.match();
    }).to["throw"]('String is required');
  });
  it('should throw on illegal characters', function () {
    expect(function () {
      return new PatternMatcher('4(5|6)7');
    }).to["throw"]('Illegal characters');
  });
  it('should throw on an illegal ] operator', function () {
    expect(function () {
      return new PatternMatcher('4]7');
    }).to["throw"]('"]" operator must be preceded by "[" operator');
  });
  it('should throw on an illegal - operator in a one-of set', function () {
    expect(function () {
      return new PatternMatcher('[-5]');
    }).to["throw"]('Couldn\'t parse a one-of set pattern: -5');
  });
  it('should throw on a non-finalized context', function () {
    expect(function () {
      return new PatternMatcher('4(?:5|7');
    }).to["throw"]('Non-finalized contexts left when pattern parse ended');
  });
  it('should throw on an illegal (|) operator', function () {
    expect(function () {
      return new PatternMatcher('4(?:5|)7');
    }).to["throw"]('No instructions found after "|" operator in an "or" group');
  });
  it('should throw on an illegal ) operator', function () {
    expect(function () {
      return new PatternMatcher('4[56)]7');
    }).to["throw"]('")" operator must be preceded by "(?:" operator');
  });
  it('should throw on an illegal | operator', function () {
    expect(function () {
      return new PatternMatcher('4[5|6]7');
    }).to["throw"]('operator can only be used inside "or" groups');
  });
  it('should match a one-digit pattern', function () {
    var matcher = new PatternMatcher('4');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('44')).to.be.undefined;
    matcher.match('44', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a two-digit pattern', function () {
    var matcher = new PatternMatcher('44');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      partialMatch: true
    });
    matcher.match('44').should.deep.equal({
      match: true
    });
    expect(matcher.match('444')).to.be.undefined;
    matcher.match('444', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    expect(matcher.match('55')).to.be.undefined;
  });
  it('should match a one-digit one-of set (single digit)', function () {
    var matcher = new PatternMatcher('[4]');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('44')).to.be.undefined;
    matcher.match('44', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a one-digit one-of set (multiple digits)', function () {
    var matcher = new PatternMatcher('[479]');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('44')).to.be.undefined;
    matcher.match('44', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a one-digit one-of set using a dash notation (not inclusive)', function () {
    var matcher = new PatternMatcher('[2-5]');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('44')).to.be.undefined;
    matcher.match('44', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a one-digit one-of set using a dash notation (inclusive)', function () {
    var matcher = new PatternMatcher('[3-4]');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('44')).to.be.undefined;
    matcher.match('44', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a one-digit one-of set including a dash notation', function () {
    var matcher = new PatternMatcher('[124-68]');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('1').should.deep.equal({
      match: true
    });
    matcher.match('2').should.deep.equal({
      match: true
    });
    expect(matcher.match('3')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      match: true
    });
    matcher.match('5').should.deep.equal({
      match: true
    });
    matcher.match('6').should.deep.equal({
      match: true
    });
    expect(matcher.match('7')).to.be.undefined;
    matcher.match('8').should.deep.equal({
      match: true
    });
    expect(matcher.match('9')).to.be.undefined;
    expect(matcher.match('88')).to.be.undefined;
    matcher.match('88', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a two-digit one-of set', function () {
    var matcher = new PatternMatcher('[479][45]');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('5')).to.be.undefined;
    expect(matcher.match('55')).to.be.undefined;
    matcher.match('44').should.deep.equal({
      match: true
    });
    expect(matcher.match('444')).to.be.undefined;
    matcher.match('444', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match a two-digit one-of set (regular digit and a one-of set)', function () {
    var matcher = new PatternMatcher('1[45]');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('1').should.deep.equal({
      partialMatch: true
    });
    matcher.match('15').should.deep.equal({
      match: true
    });
    expect(matcher.match('16')).to.be.undefined;
  });
  it('should match a pattern with an or group', function () {
    var matcher = new PatternMatcher('7(?:1[0-68]|2[1-9])');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('7').should.deep.equal({
      partialMatch: true
    });
    matcher.match('71').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('73')).to.be.undefined;
    matcher.match('711').should.deep.equal({
      match: true
    });
    expect(matcher.match('717')).to.be.undefined;
    expect(matcher.match('720')).to.be.undefined;
    matcher.match('722').should.deep.equal({
      match: true
    });
    expect(matcher.match('7222')).to.be.undefined;
    matcher.match('7222', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match an or pattern containing or groups', function () {
    var matcher = new PatternMatcher('2(?:2[024-9]|3[0-59]|47|6[245]|9[02-8])|3(?:3[28]|4[03-9]|5[2-46-8]|7[1-578]|8[2-9])');
    expect(matcher.match('1')).to.be.undefined;
    matcher.match('2').should.deep.equal({
      partialMatch: true
    });
    matcher.match('3').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('4')).to.be.undefined;
    expect(matcher.match('21')).to.be.undefined;
    matcher.match('22').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('221')).to.be.undefined;
    matcher.match('222').should.deep.equal({
      match: true
    });
    expect(matcher.match('2222')).to.be.undefined;
    matcher.match('2222', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    matcher.match('3').should.deep.equal({
      partialMatch: true
    });
    matcher.match('33').should.deep.equal({
      partialMatch: true
    });
    matcher.match('332').should.deep.equal({
      match: true
    });
    expect(matcher.match('333')).to.be.undefined;
  });
  it('should match an or pattern', function () {
    var matcher = new PatternMatcher('6|8');
    expect(matcher.match('5')).to.be.undefined;
    matcher.match('6').should.deep.equal({
      match: true
    });
    expect(matcher.match('7')).to.be.undefined;
    matcher.match('8').should.deep.equal({
      match: true
    });
  });
  it('should match an or pattern (one-of sets)', function () {
    var matcher = new PatternMatcher('[123]|[5-8]');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('1').should.deep.equal({
      match: true
    });
    matcher.match('2').should.deep.equal({
      match: true
    });
    matcher.match('3').should.deep.equal({
      match: true
    });
    expect(matcher.match('4')).to.be.undefined;
    matcher.match('5').should.deep.equal({
      match: true
    });
    matcher.match('6').should.deep.equal({
      match: true
    });
    matcher.match('7').should.deep.equal({
      match: true
    });
    matcher.match('8').should.deep.equal({
      match: true
    });
    expect(matcher.match('9')).to.be.undefined;
    expect(matcher.match('18')).to.be.undefined;
    matcher.match('18', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
  });
  it('should match an or pattern (different lengths)', function () {
    var matcher = new PatternMatcher('60|8');
    expect(matcher.match('5')).to.be.undefined;
    matcher.match('6').should.deep.equal({
      partialMatch: true
    });
    matcher.match('60').should.deep.equal({
      match: true
    });
    expect(matcher.match('61')).to.be.undefined;
    expect(matcher.match('7')).to.be.undefined;
    matcher.match('8').should.deep.equal({
      match: true
    });
    expect(matcher.match('68')).to.be.undefined;
  });
  it('should match an or pattern (one-of sets) (different lengths)', function () {
    var matcher = new PatternMatcher('[123]|[5-8][2-8]');
    expect(matcher.match('0')).to.be.undefined;
  });
  it('should match an or pattern (one-of sets and regular digits) (different lengths)', function () {
    var matcher = new PatternMatcher('[2358][2-5]|4');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('2').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('21')).to.be.undefined;
    matcher.match('22').should.deep.equal({
      match: true
    });
    matcher.match('25').should.deep.equal({
      match: true
    });
    expect(matcher.match('26')).to.be.undefined;
    expect(matcher.match('222')).to.be.undefined;
    matcher.match('222', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    matcher.match('3').should.deep.equal({
      partialMatch: true
    });
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('6')).to.be.undefined;
  });
  it('should match an or pattern (one-of sets and regular digits mixed) (different lengths)', function () {
    var matcher = new PatternMatcher('[2358]2|4');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('2').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('21')).to.be.undefined;
    matcher.match('22').should.deep.equal({
      match: true
    });
    expect(matcher.match('222')).to.be.undefined;
    matcher.match('222', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    matcher.match('3').should.deep.equal({
      partialMatch: true
    });
    matcher.match('4').should.deep.equal({
      match: true
    });
    expect(matcher.match('6')).to.be.undefined;
  });
  it('should match an or pattern (one-of sets groups and regular digits mixed) (different lengths)', function () {
    var matcher = new PatternMatcher('1(?:11|[2-9])');
    matcher.match('1').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('10')).to.be.undefined;
    matcher.match('11').should.deep.equal({
      partialMatch: true
    });
    matcher.match('111').should.deep.equal({
      match: true
    });
    expect(matcher.match('1111')).to.be.undefined;
    matcher.match('1111', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    matcher.match('12').should.deep.equal({
      match: true
    });
    expect(matcher.match('122')).to.be.undefined;
    matcher.match('19').should.deep.equal({
      match: true
    });
    expect(matcher.match('5')).to.be.undefined;
  });
  it('should match nested or groups', function () {
    var matcher = new PatternMatcher('1(?:2(?:3(?:4|5)|6)|7(?:8|9))0');
    matcher.match('1').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('2')).to.be.undefined;
    expect(matcher.match('11')).to.be.undefined;
    matcher.match('12').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('121')).to.be.undefined;
    matcher.match('123').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('1231')).to.be.undefined;
    matcher.match('1234').should.deep.equal({
      partialMatch: true
    });
    matcher.match('12340').should.deep.equal({
      match: true
    });
    expect(matcher.match('123401')).to.be.undefined;
    matcher.match('123401', {
      allowOverflow: true
    }).should.deep.equal({
      overflow: true
    });
    matcher.match('12350').should.deep.equal({
      match: true
    });
    expect(matcher.match('12360')).to.be.undefined;
    matcher.match('1260').should.deep.equal({
      match: true
    });
    expect(matcher.match('1270')).to.be.undefined;
    expect(matcher.match('1770')).to.be.undefined;
    matcher.match('1780').should.deep.equal({
      match: true
    });
    matcher.match('1790').should.deep.equal({
      match: true
    });
    expect(matcher.match('18')).to.be.undefined;
  });
  it('should match complex patterns', function () {
    var matcher = new PatternMatcher('(?:31|4)6|51|6(?:5[0-3579]|[6-9])|7(?:20|32|8)|[89]');
    expect(matcher.match('0')).to.be.undefined;
    matcher.match('3').should.deep.equal({
      partialMatch: true
    });
    matcher.match('31').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('32')).to.be.undefined;
    matcher.match('316').should.deep.equal({
      match: true
    });
    expect(matcher.match('315')).to.be.undefined;
    matcher.match('4').should.deep.equal({
      partialMatch: true
    });
    matcher.match('46').should.deep.equal({
      match: true
    });
    expect(matcher.match('47')).to.be.undefined;
    matcher.match('5').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('50')).to.be.undefined;
    matcher.match('51').should.deep.equal({
      match: true
    });
    matcher.match('6').should.deep.equal({
      partialMatch: true
    });
    expect(matcher.match('64')).to.be.undefined;
    matcher.match('65').should.deep.equal({
      partialMatch: true
    });
    matcher.match('650').should.deep.equal({
      match: true
    });
    expect(matcher.match('654')).to.be.undefined;
    matcher.match('69').should.deep.equal({
      match: true
    });
    matcher.match('8').should.deep.equal({
      match: true
    });
    matcher.match('9').should.deep.equal({
      match: true
    });
  });
  it('shouldn\'t match things that shouldn\'t match', function () {
    // There was a bug: "leading digits" `"2"` matched "leading digits pattern" `"90"`.
    // The incorrect `.match()` function result was `{ oveflow: true }`
    // while it should've been `undefined`.
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/66
    expect(new PatternMatcher('2').match('90', {
      allowOverflow: true
    })).to.be.undefined;
  });
});
//# sourceMappingURL=AsYouTypeFormatter.PatternMatcher.test.js.map