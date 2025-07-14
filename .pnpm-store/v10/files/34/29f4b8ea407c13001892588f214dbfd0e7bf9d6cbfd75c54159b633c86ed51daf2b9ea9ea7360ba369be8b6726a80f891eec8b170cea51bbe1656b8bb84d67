"use strict";

var _examplesMobile = _interopRequireDefault(require("../examples.mobile.json"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _getExampleNumber = _interopRequireDefault(require("./getExampleNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('getExampleNumber', function () {
  it('should get an example number', function () {
    var phoneNumber = (0, _getExampleNumber["default"])('RU', _examplesMobile["default"], _metadataMin["default"]);
    phoneNumber.nationalNumber.should.equal('9123456789');
    phoneNumber.number.should.equal('+79123456789');
    phoneNumber.countryCallingCode.should.equal('7');
    phoneNumber.country.should.equal('RU');
  });
  it('should handle a non-existing country', function () {
    expect((0, _getExampleNumber["default"])('XX', _examplesMobile["default"], _metadataMin["default"])).to.be.undefined;
  });
});
//# sourceMappingURL=getExampleNumber.test.js.map