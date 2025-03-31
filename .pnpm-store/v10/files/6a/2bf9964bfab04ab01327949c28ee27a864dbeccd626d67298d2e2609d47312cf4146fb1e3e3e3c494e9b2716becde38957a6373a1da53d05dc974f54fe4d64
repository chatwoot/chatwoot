"use strict";

var _formatIncompletePhoneNumber = _interopRequireDefault(require("./formatIncompletePhoneNumber.js"));

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('formatIncompletePhoneNumber', function () {
  it('should format parsed input value', function () {
    var result; // National input.

    (0, _formatIncompletePhoneNumber["default"])('880055535', 'RU', _metadataMin["default"]).should.equal('8 (800) 555-35'); // International input, no country.

    (0, _formatIncompletePhoneNumber["default"])('+780055535', null, _metadataMin["default"]).should.equal('+7 800 555 35'); // International input, no country argument.

    (0, _formatIncompletePhoneNumber["default"])('+780055535', _metadataMin["default"]).should.equal('+7 800 555 35'); // International input, with country.

    (0, _formatIncompletePhoneNumber["default"])('+780055535', 'RU', _metadataMin["default"]).should.equal('+7 800 555 35');
  });
  it('should support an object argument', function () {
    (0, _formatIncompletePhoneNumber["default"])('880055535', {
      defaultCountry: 'RU'
    }, _metadataMin["default"]).should.equal('8 (800) 555-35');
    (0, _formatIncompletePhoneNumber["default"])('880055535', {
      defaultCallingCode: '7'
    }, _metadataMin["default"]).should.equal('8 (800) 555-35');
  });
});
//# sourceMappingURL=formatIncompletePhoneNumber.test.js.map