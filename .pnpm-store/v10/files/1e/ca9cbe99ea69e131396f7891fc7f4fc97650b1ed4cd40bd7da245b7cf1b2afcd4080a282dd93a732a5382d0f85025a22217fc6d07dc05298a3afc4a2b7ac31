"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

var _parseIncompletePhoneNumber = _interopRequireWildcard(require("./parseIncompletePhoneNumber.js"));

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

describe('parseIncompletePhoneNumber', function () {
  it('should parse phone number character', function () {
    // Accepts leading `+`.
    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('+').should.equal('+'); // Doesn't accept non-leading `+`.

    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('+', '+')).to.be.undefined; // Parses digits.

    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('1').should.equal('1'); // Parses non-European digits.

    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('٤').should.equal('4'); // Dismisses other characters.

    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('-')).to.be.undefined;
  });
  it('should parse incomplete phone number', function () {
    (0, _parseIncompletePhoneNumber["default"])('').should.equal(''); // Doesn't accept non-leading `+`.

    (0, _parseIncompletePhoneNumber["default"])('++').should.equal('+'); // Accepts leading `+`.

    (0, _parseIncompletePhoneNumber["default"])('+7 800 555').should.equal('+7800555'); // Parses digits.

    (0, _parseIncompletePhoneNumber["default"])('8 (800) 555').should.equal('8800555'); // Parses non-European digits.

    (0, _parseIncompletePhoneNumber["default"])('+٤٤٢٣٢٣٢٣٤').should.equal('+442323234');
  });
  it('should work with a new `context` argument in `parsePhoneNumberCharacter()` function (international number)', function () {
    var stopped = false;

    var emit = function emit(event) {
      switch (event) {
        case 'end':
          stopped = true;
          break;
      }
    };

    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('+', undefined, emit).should.equal('+');
    expect(stopped).to.equal(false);
    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('1', '+', emit).should.equal('1');
    expect(stopped).to.equal(false);
    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('+', '+1', emit)).to.equal(undefined);
    expect(stopped).to.equal(true);
    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('2', '+1', emit)).to.equal('2');
    expect(stopped).to.equal(true);
  });
  it('should work with a new `context` argument in `parsePhoneNumberCharacter()` function (national number)', function () {
    var stopped = false;

    var emit = function emit(event) {
      switch (event) {
        case 'end':
          stopped = true;
          break;
      }
    };

    (0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('2', undefined, emit).should.equal('2');
    expect(stopped).to.equal(false);
    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('+', '2', emit)).to.equal(undefined);
    expect(stopped).to.equal(true);
    expect((0, _parseIncompletePhoneNumber.parsePhoneNumberCharacter)('1', '2', emit)).to.equal('1');
    expect(stopped).to.equal(true);
  });
});
//# sourceMappingURL=parseIncompletePhoneNumber.test.js.map