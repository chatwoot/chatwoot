import { closeNonPairedParens, stripNonPairedParens, repeat } from './AsYouTypeFormatter.util.js';
describe('closeNonPairedParens', function () {
  it('should close non-paired braces', function () {
    closeNonPairedParens('(000) 123-45 (9  )', 15).should.equal('(000) 123-45 (9  )');
  });
});
describe('stripNonPairedParens', function () {
  it('should strip non-paired braces', function () {
    stripNonPairedParens('(000) 123-45 (9').should.equal('(000) 123-45 9');
    stripNonPairedParens('(000) 123-45 (9)').should.equal('(000) 123-45 (9)');
  });
});
describe('repeat', function () {
  it('should repeat string N times', function () {
    repeat('a', 0).should.equal('');
    repeat('a', 3).should.equal('aaa');
    repeat('a', 4).should.equal('aaaa');
  });
});
//# sourceMappingURL=AsYouTypeFormatter.util.test.js.map