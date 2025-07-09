"use strict";

var _isValidPhoneNumber2 = _interopRequireDefault(require("./isValidPhoneNumber.js"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function isValidPhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _isValidPhoneNumber2["default"].apply(this, parameters);
}

describe('isValidPhoneNumber', function () {
  it('should detect whether a phone number is valid', function () {
    isValidPhoneNumber('8 (800) 555 35 35', 'RU').should.equal(true);
    isValidPhoneNumber('8 (800) 555 35 35 0', 'RU').should.equal(false);
    isValidPhoneNumber('Call: 8 (800) 555 35 35', 'RU').should.equal(false);
    isValidPhoneNumber('8 (800) 555 35 35', {
      defaultCountry: 'RU'
    }).should.equal(true);
    isValidPhoneNumber('+7 (800) 555 35 35').should.equal(true);
    isValidPhoneNumber('+7 1 (800) 555 35 35').should.equal(false);
    isValidPhoneNumber(' +7 (800) 555 35 35').should.equal(false);
    isValidPhoneNumber(' ').should.equal(false);
  });
});
//# sourceMappingURL=isValidPhoneNumber.test.js.map