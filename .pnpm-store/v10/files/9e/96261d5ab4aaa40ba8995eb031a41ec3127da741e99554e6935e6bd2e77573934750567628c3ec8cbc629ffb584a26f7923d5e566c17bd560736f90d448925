"use strict";

var _stripIddPrefix = _interopRequireDefault(require("./stripIddPrefix.js"));

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('stripIddPrefix', function () {
  it('should strip a valid IDD prefix', function () {
    (0, _stripIddPrefix["default"])('01178005553535', 'US', '1', _metadataMin["default"]).should.equal('78005553535');
  });
  it('should strip a valid IDD prefix (no country calling code)', function () {
    (0, _stripIddPrefix["default"])('011', 'US', '1', _metadataMin["default"]).should.equal('');
  });
  it('should strip a valid IDD prefix (valid country calling code)', function () {
    (0, _stripIddPrefix["default"])('0117', 'US', '1', _metadataMin["default"]).should.equal('7');
  });
  it('should strip a valid IDD prefix (not a valid country calling code)', function () {
    expect((0, _stripIddPrefix["default"])('0110', 'US', '1', _metadataMin["default"])).to.be.undefined;
  });
});
//# sourceMappingURL=stripIddPrefix.test.js.map