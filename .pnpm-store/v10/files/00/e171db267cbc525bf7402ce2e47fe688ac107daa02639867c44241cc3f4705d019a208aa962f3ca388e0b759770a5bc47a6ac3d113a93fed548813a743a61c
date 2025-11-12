"use strict";

var _isPossiblePhoneNumber2 = _interopRequireDefault(require("./isPossiblePhoneNumber.js"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _metadataMin2 = _interopRequireDefault(require("../test/metadata/1.0.0/metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function isPossiblePhoneNumber() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _isPossiblePhoneNumber2["default"].apply(this, parameters);
}

describe('isPossiblePhoneNumber', function () {
  it('should detect whether a phone number is possible', function () {
    isPossiblePhoneNumber('8 (800) 555 35 35', 'RU').should.equal(true);
    isPossiblePhoneNumber('8 (800) 555 35 35 0', 'RU').should.equal(false);
    isPossiblePhoneNumber('Call: 8 (800) 555 35 35', 'RU').should.equal(false);
    isPossiblePhoneNumber('8 (800) 555 35 35', {
      defaultCountry: 'RU'
    }).should.equal(true);
    isPossiblePhoneNumber('+7 (800) 555 35 35').should.equal(true);
    isPossiblePhoneNumber('+7 1 (800) 555 35 35').should.equal(false);
    isPossiblePhoneNumber(' +7 (800) 555 35 35').should.equal(false);
    isPossiblePhoneNumber(' ').should.equal(false);
  });
  it('should detect whether a phone number is possible when using old metadata', function () {
    expect(function () {
      return (0, _isPossiblePhoneNumber2["default"])('8 (800) 555 35 35', 'RU', _metadataMin2["default"]);
    }).to["throw"]('Missing "possibleLengths" in metadata.');
    (0, _isPossiblePhoneNumber2["default"])('+888 123 456 78901', _metadataMin2["default"]).should.equal(true);
  });
});
//# sourceMappingURL=isPossiblePhoneNumber.test.js.map