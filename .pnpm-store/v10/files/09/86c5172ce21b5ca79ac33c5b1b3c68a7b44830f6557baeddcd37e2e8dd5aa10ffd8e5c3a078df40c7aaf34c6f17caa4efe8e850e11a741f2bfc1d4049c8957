"use strict";

var _parsePhoneNumber = _interopRequireDefault(require("../parsePhoneNumber.js"));

var _PhoneNumber = _interopRequireDefault(require("../PhoneNumber.js"));

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function parsePhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _parsePhoneNumber["default"].apply(this, parameters);
}

describe('extractPhoneContext', function () {
  it('should parse RFC 3966 phone number URIs', function () {
    // context    = ";phone-context=" descriptor
    // descriptor = domainname / global-number-digits
    var NZ_NUMBER = new _PhoneNumber["default"]('64', '33316005', _metadataMin["default"]); // Valid global-phone-digits

    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64;{this isn\'t part of phone-context anymore!}'), NZ_NUMBER);
    var nzFromPhoneContext = new _PhoneNumber["default"]('64', '3033316005', _metadataMin["default"]);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64-3'), nzFromPhoneContext);
    var brFromPhoneContext = new _PhoneNumber["default"]('55', '5033316005', _metadataMin["default"]);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+(555)'), brFromPhoneContext);
    var usFromPhoneContext = new _PhoneNumber["default"]('1', '23033316005', _metadataMin["default"]);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+-1-2.3()'), usFromPhoneContext); // Valid domainname.

    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=abc.nz', 'NZ'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=www.PHONE-numb3r.com', 'NZ'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=a', 'NZ'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=3phone.J.', 'NZ'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=a--z', 'NZ'), NZ_NUMBER); // Should strip ISDN subaddress.

    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;isub=/@;phone-context=+64', 'NZ'), NZ_NUMBER); // // Should support incorrectly-written RFC 3966 phone numbers:
    // // the ones written without a `tel:` prefix.
    // expectPhoneNumbersToBeEqual(
    // 	parsePhoneNumber('033316005;phone-context=+64', 'NZ'),
    // 	NZ_NUMBER
    // )
    // Invalid descriptor.

    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=+');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=64');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=++64');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=+abc');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=.');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=3phone');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=a-.nz');
    expectToThrowForInvalidPhoneContext('tel:033316005;phone-context=a{b}c');
  });
});

function expectToThrowForInvalidPhoneContext(string) {
  expect(parsePhoneNumber(string)).to.be.undefined;
}

function expectPhoneNumbersToBeEqual(phoneNumber1, phoneNumber2) {
  if (!phoneNumber1 || !phoneNumber2) {
    return false;
  }

  return phoneNumber1.number === phoneNumber2.number && phoneNumber1.ext === phoneNumber2.ext;
}
//# sourceMappingURL=extractPhoneContext.test.js.map