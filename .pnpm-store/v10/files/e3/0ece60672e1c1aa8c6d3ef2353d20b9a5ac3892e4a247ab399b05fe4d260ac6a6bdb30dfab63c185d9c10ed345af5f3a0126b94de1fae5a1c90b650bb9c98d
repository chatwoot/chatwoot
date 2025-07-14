import parsePhoneNumber_ from '../parsePhoneNumber.js';
import PhoneNumber from '../PhoneNumber.js';
import metadata from '../../metadata.min.json' assert { type: 'json' };

function parsePhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(metadata);
  return parsePhoneNumber_.apply(this, parameters);
}

describe('extractPhoneContext', function () {
  it('should parse RFC 3966 phone number URIs', function () {
    // context    = ";phone-context=" descriptor
    // descriptor = domainname / global-number-digits
    var NZ_NUMBER = new PhoneNumber('64', '33316005', metadata); // Valid global-phone-digits

    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64'), NZ_NUMBER);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64;{this isn\'t part of phone-context anymore!}'), NZ_NUMBER);
    var nzFromPhoneContext = new PhoneNumber('64', '3033316005', metadata);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+64-3'), nzFromPhoneContext);
    var brFromPhoneContext = new PhoneNumber('55', '5033316005', metadata);
    expectPhoneNumbersToBeEqual(parsePhoneNumber('tel:033316005;phone-context=+(555)'), brFromPhoneContext);
    var usFromPhoneContext = new PhoneNumber('1', '23033316005', metadata);
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