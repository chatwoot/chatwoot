"use strict";

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

var _isValidNumberForRegion2 = _interopRequireDefault(require("./isValidNumberForRegion.js"));

var _isValidNumberForRegion_ = _interopRequireDefault(require("./isValidNumberForRegion_.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function isValidNumberForRegion() {
  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  parameters.push(_metadataMin["default"]);
  return _isValidNumberForRegion2["default"].apply(this, parameters);
}

describe('isValidNumberForRegion', function () {
  it('should detect if is valid number for region', function () {
    isValidNumberForRegion('07624369230', 'GB').should.equal(false);
    isValidNumberForRegion('07624369230', 'IM').should.equal(true);
  });
  it('should validate arguments', function () {
    expect(function () {
      return isValidNumberForRegion({
        phone: '7624369230',
        country: 'GB'
      });
    }).to["throw"]('number must be a string');
    expect(function () {
      return isValidNumberForRegion('7624369230');
    }).to["throw"]('country must be a string');
  });
  it('should work in edge cases', function () {
    // Not a "viable" phone number.
    isValidNumberForRegion('7', 'GB').should.equal(false); // `options` argument `if/else` coverage.

    (0, _isValidNumberForRegion_["default"])('07624369230', 'GB', {}, _metadataMin["default"]).should.equal(false);
  });
});
//# sourceMappingURL=isValidNumberForRegion.test.js.map