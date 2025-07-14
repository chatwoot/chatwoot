"use strict";

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

var _isPossibleNumber2 = _interopRequireDefault(require("./isPossibleNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function isPossibleNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _isPossibleNumber2["default"].apply(this, parameters);
}

describe('isPossibleNumber', function () {
  it('should work', function () {
    isPossibleNumber('+79992223344').should.equal(true);
    isPossibleNumber({
      phone: '1112223344',
      country: 'RU'
    }).should.equal(true);
    isPossibleNumber({
      phone: '111222334',
      country: 'RU'
    }).should.equal(false);
    isPossibleNumber({
      phone: '11122233445',
      country: 'RU'
    }).should.equal(false);
    isPossibleNumber({
      phone: '1112223344',
      countryCallingCode: 7
    }).should.equal(true);
  });
  it('should work v2', function () {
    isPossibleNumber({
      nationalNumber: '111222334',
      countryCallingCode: 7
    }, {
      v2: true
    }).should.equal(false);
    isPossibleNumber({
      nationalNumber: '1112223344',
      countryCallingCode: 7
    }, {
      v2: true
    }).should.equal(true);
    isPossibleNumber({
      nationalNumber: '11122233445',
      countryCallingCode: 7
    }, {
      v2: true
    }).should.equal(false);
  });
  it('should work in edge cases', function () {
    // Invalid `PhoneNumber` argument.
    expect(function () {
      return isPossibleNumber({}, {
        v2: true
      });
    }).to["throw"]('Invalid phone number object passed'); // Empty input is passed.
    // This is just to support `isValidNumber({})`
    // for cases when `parseNumber()` returns `{}`.

    isPossibleNumber({}).should.equal(false);
    expect(function () {
      return isPossibleNumber({
        phone: '1112223344'
      });
    }).to["throw"]('Invalid phone number object passed'); // Incorrect country.

    expect(function () {
      return isPossibleNumber({
        phone: '1112223344',
        country: 'XX'
      });
    }).to["throw"]('Unknown country');
  });
});
//# sourceMappingURL=isPossibleNumber.test.js.map