"use strict";

var _extractCountryCallingCode = _interopRequireDefault(require("./extractCountryCallingCode.js"));

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('extractCountryCallingCode', function () {
  it('should extract country calling code from a number', function () {
    (0, _extractCountryCallingCode["default"])('+78005553535', null, null, _metadataMin["default"]).should.deep.equal({
      countryCallingCodeSource: 'FROM_NUMBER_WITH_PLUS_SIGN',
      countryCallingCode: '7',
      number: '8005553535'
    });
    (0, _extractCountryCallingCode["default"])('+7800', null, null, _metadataMin["default"]).should.deep.equal({
      countryCallingCodeSource: 'FROM_NUMBER_WITH_PLUS_SIGN',
      countryCallingCode: '7',
      number: '800'
    });
    (0, _extractCountryCallingCode["default"])('', null, null, _metadataMin["default"]).should.deep.equal({});
  });
});
//# sourceMappingURL=extractCountryCallingCode.test.js.map