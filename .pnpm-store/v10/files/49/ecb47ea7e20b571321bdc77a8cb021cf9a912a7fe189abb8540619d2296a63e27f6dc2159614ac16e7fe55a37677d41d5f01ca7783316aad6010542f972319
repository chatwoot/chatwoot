"use strict";

var _parsePhoneNumber2 = _interopRequireDefault(require("./parsePhoneNumber.js"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function parsePhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _parsePhoneNumber2["default"].apply(this, parameters);
}

var USE_NON_GEOGRAPHIC_COUNTRY_CODE = false;
describe('parsePhoneNumber', function () {
  it('should parse phone numbers from string', function () {
    parsePhoneNumber('Phone: 8 (800) 555 35 35.', 'RU').nationalNumber.should.equal('8005553535');
    expect(parsePhoneNumber('3', 'RU')).to.be.undefined;
  });
  it('should work in edge cases', function () {
    expect(parsePhoneNumber('')).to.be.undefined;
  });
  it('should parse phone numbers when invalid country code is passed', function () {
    parsePhoneNumber('Phone: +7 (800) 555 35 35.', 'XX').nationalNumber.should.equal('8005553535');
    expect(parsePhoneNumber('Phone: 8 (800) 555-35-35.', 'XX')).to.be.undefined;
  });
  it('should parse non-geographic numbering plan phone numbers (extended)', function () {
    var phoneNumber = parsePhoneNumber('+870773111632');
    phoneNumber.number.should.equal('+870773111632');

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      phoneNumber.country.should.equal('001');
    } else {
      expect(phoneNumber.country).to.be.undefined;
    }

    phoneNumber.countryCallingCode.should.equal('870');
  });
  it('should parse non-geographic numbering plan phone numbers (default country code) (extended)', function () {
    var phoneNumber = parsePhoneNumber('773111632', {
      defaultCallingCode: '870'
    });
    phoneNumber.number.should.equal('+870773111632');

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      phoneNumber.country.should.equal('001');
    } else {
      expect(phoneNumber.country).to.be.undefined;
    }

    phoneNumber.countryCallingCode.should.equal('870');
  });
  it('should determine the possibility of non-geographic phone numbers', function () {
    var phoneNumber = parsePhoneNumber('+870773111632');
    phoneNumber.isPossible().should.equal(true);
    var phoneNumber2 = parsePhoneNumber('+8707731116321');
    phoneNumber2.isPossible().should.equal(false);
  });
  it('should support `extract: false` flag', function () {
    var testCorrectness = function testCorrectness(number, expectedResult) {
      var result = expect(parsePhoneNumber(number, {
        extract: false,
        defaultCountry: 'US'
      }));

      if (expectedResult) {
        result.to.not.be.undefined;
      } else {
        result.to.be.undefined;
      }
    };

    testCorrectness('Call: (213) 373-4253', false);
    testCorrectness('(213) 373-4253x', false);
    testCorrectness('(213) 373-4253', true);
    testCorrectness('- (213) 373-4253 -', true);
    testCorrectness('+1 (213) 373-4253', true);
    testCorrectness(' +1 (213) 373-4253', false);
  });
  it('should not prematurely strip a possible national prefix from Chinese numbers', function () {
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/57
    var phoneNumber = parsePhoneNumber('+86123456789');
    phoneNumber.isPossible().should.equal(true);
    phoneNumber.isValid().should.equal(false);
    phoneNumber.nationalNumber.should.equal('123456789');
  });
});
//# sourceMappingURL=parsePhoneNumber.test.js.map