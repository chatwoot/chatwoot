import stripIddPrefix from './stripIddPrefix.js';
import metadata from '../../metadata.min.json' assert { type: 'json' };
describe('stripIddPrefix', function () {
  it('should strip a valid IDD prefix', function () {
    stripIddPrefix('01178005553535', 'US', '1', metadata).should.equal('78005553535');
  });
  it('should strip a valid IDD prefix (no country calling code)', function () {
    stripIddPrefix('011', 'US', '1', metadata).should.equal('');
  });
  it('should strip a valid IDD prefix (valid country calling code)', function () {
    stripIddPrefix('0117', 'US', '1', metadata).should.equal('7');
  });
  it('should strip a valid IDD prefix (not a valid country calling code)', function () {
    expect(stripIddPrefix('0110', 'US', '1', metadata)).to.be.undefined;
  });
});
//# sourceMappingURL=stripIddPrefix.test.js.map