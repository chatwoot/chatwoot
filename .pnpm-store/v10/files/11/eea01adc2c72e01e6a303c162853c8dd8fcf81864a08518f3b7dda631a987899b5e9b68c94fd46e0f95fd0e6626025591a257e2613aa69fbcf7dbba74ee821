"use strict";

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _getCountryCallingCode = _interopRequireDefault(require("./getCountryCallingCode.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('getCountryCallingCode', function () {
  it('should get country calling code', function () {
    (0, _getCountryCallingCode["default"])('US', _metadataMin["default"]).should.equal('1');
  });
  it('should throw if country is unknown', function () {
    expect(function () {
      return (0, _getCountryCallingCode["default"])('ZZ', _metadataMin["default"]);
    }).to["throw"]('Unknown country: ZZ');
  });
});
//# sourceMappingURL=getCountryCallingCode.test.js.map