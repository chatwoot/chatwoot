"use strict";

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _isPossible = _interopRequireDefault(require("./isPossible.js"));

var _parsePhoneNumber = _interopRequireDefault(require("./parsePhoneNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function isPossibleNumber() {
  var v2;

  for (var _len = arguments.length, parameters = new Array(_len), _key = 0; _key < _len; _key++) {
    parameters[_key] = arguments[_key];
  }

  if (parameters.length < 1) {
    // `input` parameter.
    parameters.push(undefined);
  } else {
    // Convert string `input` to a `PhoneNumber` instance.
    if (typeof parameters[0] === 'string') {
      v2 = true;
      parameters[0] = (0, _parsePhoneNumber["default"])(parameters[0], _objectSpread(_objectSpread({}, parameters[1]), {}, {
        extract: false
      }), _metadataMin["default"]);
    }
  }

  if (parameters.length < 2) {
    // `options` parameter.
    parameters.push(undefined);
  } // Set `v2` flag.


  parameters[1] = _objectSpread({
    v2: v2
  }, parameters[1]); // Add `metadata` parameter.

  parameters.push(_metadataMin["default"]); // Call the function.

  return _isPossible["default"].apply(this, parameters);
}

describe('isPossible', function () {
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
//# sourceMappingURL=isPossible.test.js.map