"use strict";

var _validatePhoneNumberLength2 = _interopRequireDefault(require("./validatePhoneNumberLength.js"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function validatePhoneNumberLength() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _validatePhoneNumberLength2["default"].apply(this, parameters);
}

describe('validatePhoneNumberLength', function () {
  it('should detect whether a phone number length is valid', function () {
    // Not a phone number.
    validatePhoneNumberLength('+').should.equal('NOT_A_NUMBER');
    validatePhoneNumberLength('abcde').should.equal('NOT_A_NUMBER'); // No country supplied for a national number.

    validatePhoneNumberLength('123').should.equal('INVALID_COUNTRY'); // Too short while the number is not considered "viable"
    // by Google's `libphonenumber`.

    validatePhoneNumberLength('2', 'US').should.equal('TOO_SHORT');
    validatePhoneNumberLength('+1', 'US').should.equal('TOO_SHORT');
    validatePhoneNumberLength('+12', 'US').should.equal('TOO_SHORT'); // Test national (significant) number length.

    validatePhoneNumberLength('444 1 44', 'TR').should.equal('TOO_SHORT');
    expect(validatePhoneNumberLength('444 1 444', 'TR')).to.be.undefined;
    validatePhoneNumberLength('444 1 4444', 'TR').should.equal('INVALID_LENGTH');
    validatePhoneNumberLength('444 1 4444444444', 'TR').should.equal('TOO_LONG');
  });
});
//# sourceMappingURL=validatePhoneNumberLength.test.js.map