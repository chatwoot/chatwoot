"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

var _findPhoneNumbers = _interopRequireWildcard(require("./findPhoneNumbers.js"));

var _findPhoneNumbersInitialImplementation = require("./findPhoneNumbersInitialImplementation.js");

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

describe('findPhoneNumbers', function () {
  it('should find numbers', function () {
    (0, _findPhoneNumbers["default"])('2133734253', 'US', _metadataMin["default"]).should.deep.equal([{
      phone: '2133734253',
      country: 'US',
      startsAt: 0,
      endsAt: 10
    }]);
    (0, _findPhoneNumbers["default"])('(213) 373-4253', 'US', _metadataMin["default"]).should.deep.equal([{
      phone: '2133734253',
      country: 'US',
      startsAt: 0,
      endsAt: 14
    }]);
    (0, _findPhoneNumbers["default"])('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 14,
      endsAt: 32
    }, {
      phone: '2133734253',
      country: 'US',
      startsAt: 41,
      endsAt: 55
    }]); // Opening parenthesis issue.
    // https://github.com/catamphetamine/libphonenumber-js/issues/252

    (0, _findPhoneNumbers["default"])('The number is +7 (800) 555-35-35 and not (213) 373-4253 (that\'s not even in the same country!) as written in the document.', 'US', _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 14,
      endsAt: 32
    }, {
      phone: '2133734253',
      country: 'US',
      startsAt: 41,
      endsAt: 55
    }]); // No default country.

    (0, _findPhoneNumbers["default"])('The number is +7 (800) 555-35-35 as written in the document.', _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 14,
      endsAt: 32
    }]); // Passing `options` and default country.

    (0, _findPhoneNumbers["default"])('The number is +7 (800) 555-35-35 as written in the document.', 'US', {
      leniency: 'VALID'
    }, _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 14,
      endsAt: 32
    }]); // Passing `options`.

    (0, _findPhoneNumbers["default"])('The number is +7 (800) 555-35-35 as written in the document.', {
      leniency: 'VALID'
    }, _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 14,
      endsAt: 32
    }]); // Not a phone number and a phone number.

    (0, _findPhoneNumbers["default"])('Digits 12 are not a number, but +7 (800) 555-35-35 is.', {
      leniency: 'VALID'
    }, _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      startsAt: 32,
      endsAt: 50
    }]); // Phone number extension.

    (0, _findPhoneNumbers["default"])('Date 02/17/2018 is not a number, but +7 (800) 555-35-35 ext. 123 is.', {
      leniency: 'VALID'
    }, _metadataMin["default"]).should.deep.equal([{
      phone: '8005553535',
      country: 'RU',
      ext: '123',
      startsAt: 37,
      endsAt: 64
    }]);
  });
  it('shouldn\'t find non-valid numbers', function () {
    // Not a valid phone number for US.
    (0, _findPhoneNumbers["default"])('1111111111', 'US', _metadataMin["default"]).should.deep.equal([]);
  });
  it('should find non-European digits', function () {
    // E.g. in Iraq they don't write `+442323234` but rather `+٤٤٢٣٢٣٢٣٤`.
    (0, _findPhoneNumbers["default"])('العَرَبِيَّة‎ +٤٤٣٣٣٣٣٣٣٣٣٣عَرَبِيّ‎', _metadataMin["default"]).should.deep.equal([{
      country: 'GB',
      phone: '3333333333',
      startsAt: 14,
      endsAt: 27
    }]);
  });
  it('should iterate', function () {
    var expected_numbers = [{
      country: 'RU',
      phone: '8005553535',
      // number   : '+7 (800) 555-35-35',
      startsAt: 14,
      endsAt: 32
    }, {
      country: 'US',
      phone: '2133734253',
      // number   : '(213) 373-4253',
      startsAt: 41,
      endsAt: 55
    }];

    for (var _iterator = _createForOfIteratorHelperLoose((0, _findPhoneNumbers.searchPhoneNumbers)('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', _metadataMin["default"])), _step; !(_step = _iterator()).done;) {
      var number = _step.value;
      number.should.deep.equal(expected_numbers.shift());
    }

    expected_numbers.length.should.equal(0);
  });
  it('should work in edge cases', function () {
    var thrower; // No input

    (0, _findPhoneNumbers["default"])('', _metadataMin["default"]).should.deep.equal([]); // No country metadata for this `require` country code

    thrower = function thrower() {
      return (0, _findPhoneNumbers["default"])('123', 'ZZ', _metadataMin["default"]);
    };

    thrower.should["throw"]('Unknown country'); // Numerical `value`

    thrower = function thrower() {
      return (0, _findPhoneNumbers["default"])(2141111111, 'US');
    };

    thrower.should["throw"]('A text for parsing must be a string.'); // // No metadata
    // thrower = () => findNumbers('')
    // thrower.should.throw('`metadata` argument not passed')
  });
  it('shouldn\'t find phone numbers which are not phone numbers', function () {
    // A timestamp.
    (0, _findPhoneNumbers["default"])('2012-01-02 08:00', 'US', _metadataMin["default"]).should.deep.equal([]); // A valid number (not a complete timestamp).

    (0, _findPhoneNumbers["default"])('2012-01-02 08', 'US', _metadataMin["default"]).should.deep.equal([{
      country: 'US',
      phone: '2012010208',
      startsAt: 0,
      endsAt: 13
    }]); // Invalid parens.

    (0, _findPhoneNumbers["default"])('213(3734253', 'US', _metadataMin["default"]).should.deep.equal([]); // Letters after phone number.

    (0, _findPhoneNumbers["default"])('2133734253a', 'US', _metadataMin["default"]).should.deep.equal([]); // Valid phone (same as the one found in the UUID below).

    (0, _findPhoneNumbers["default"])('The phone number is 231354125.', 'FR', _metadataMin["default"]).should.deep.equal([{
      country: 'FR',
      phone: '231354125',
      startsAt: 20,
      endsAt: 29
    }]); // Not a phone number (part of a UUID).
    // Should parse in `{ extended: true }` mode.

    var possibleNumbers = (0, _findPhoneNumbers["default"])('The UUID is CA801c26f98cd16e231354125ad046e40b.', 'FR', {
      extended: true
    }, _metadataMin["default"]);
    possibleNumbers.length.should.equal(3);
    possibleNumbers[1].country.should.equal('FR');
    possibleNumbers[1].phone.should.equal('231354125'); // Not a phone number (part of a UUID).
    // Shouldn't parse by default.

    (0, _findPhoneNumbers["default"])('The UUID is CA801c26f98cd16e231354125ad046e40b.', 'FR', _metadataMin["default"]).should.deep.equal([]);
  });
});
describe('PhoneNumberSearch', function () {
  it('should search for phone numbers', function () {
    var finder = new _findPhoneNumbersInitialImplementation.PhoneNumberSearch('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', {
      defaultCountry: 'US'
    }, _metadataMin["default"]);
    finder.hasNext().should.equal(true);
    finder.next().should.deep.equal({
      country: 'RU',
      phone: '8005553535',
      // number   : '+7 (800) 555-35-35',
      startsAt: 14,
      endsAt: 32
    });
    finder.hasNext().should.equal(true);
    finder.next().should.deep.equal({
      country: 'US',
      phone: '2133734253',
      // number   : '(213) 373-4253',
      startsAt: 41,
      endsAt: 55
    });
    finder.hasNext().should.equal(false);
  });
  it('should search for phone numbers (no options)', function () {
    var finder = new _findPhoneNumbersInitialImplementation.PhoneNumberSearch('The number is +7 (800) 555-35-35', undefined, _metadataMin["default"]);
    finder.hasNext().should.equal(true);
    finder.next().should.deep.equal({
      country: 'RU',
      phone: '8005553535',
      // number   : '+7 (800) 555-35-35',
      startsAt: 14,
      endsAt: 32
    });
    finder.hasNext().should.equal(false);
  });
  it('should work in edge cases', function () {
    // No options
    var search = new _findPhoneNumbersInitialImplementation.PhoneNumberSearch('', undefined, _metadataMin["default"]); // No next element

    var thrower = function thrower() {
      return search.next();
    };

    thrower.should["throw"]('No next element');
  });
});
//# sourceMappingURL=findPhoneNumbers.test.js.map