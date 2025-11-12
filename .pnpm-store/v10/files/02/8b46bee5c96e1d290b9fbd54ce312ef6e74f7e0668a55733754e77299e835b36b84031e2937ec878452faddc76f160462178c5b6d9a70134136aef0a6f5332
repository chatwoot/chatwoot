"use strict";

var _getNumberType = _interopRequireDefault(require("./getNumberType.js"));

var _metadataMin = _interopRequireDefault(require("../../test/metadata/1.0.0/metadata.min.json"));

var _metadata = _interopRequireDefault(require("../metadata.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('getNumberType', function () {
  it('should get number type when using old metadata', function () {
    (0, _getNumberType["default"])({
      nationalNumber: '2133734253',
      country: 'US'
    }, {
      v2: true
    }, _metadataMin["default"]).should.equal('FIXED_LINE_OR_MOBILE');
  });
  it('should return `undefined` when the phone number is a malformed one', function () {
    expect((0, _getNumberType["default"])({}, {
      v2: true
    }, _metadataMin["default"])).to.equal(undefined);
  });
});
//# sourceMappingURL=getNumberType.test.js.map