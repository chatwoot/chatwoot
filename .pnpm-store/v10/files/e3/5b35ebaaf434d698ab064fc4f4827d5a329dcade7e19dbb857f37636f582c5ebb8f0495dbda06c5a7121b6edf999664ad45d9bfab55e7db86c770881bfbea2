"use strict";

var _metadata2 = _interopRequireDefault(require("../metadata.js"));

var _metadataMax = _interopRequireDefault(require("../../metadata.max.json"));

var _metadataMin = _interopRequireDefault(require("../../test/metadata/1.0.0/metadata.min.json"));

var _checkNumberLength = require("./checkNumberLength.js");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('checkNumberLength', function () {
  it('should check phone number length', function () {
    // Too short.
    checkNumberLength('800555353', 'FIXED_LINE', 'RU').should.equal('TOO_SHORT'); // Normal.

    checkNumberLength('8005553535', 'FIXED_LINE', 'RU').should.equal('IS_POSSIBLE'); // Too long.

    checkNumberLength('80055535355', 'FIXED_LINE', 'RU').should.equal('TOO_LONG'); // No such type.

    checkNumberLength('169454850', 'VOIP', 'AC').should.equal('INVALID_LENGTH'); // No such possible length.

    checkNumberLength('1694548', undefined, 'AD').should.equal('INVALID_LENGTH'); // FIXED_LINE_OR_MOBILE

    checkNumberLength('1694548', 'FIXED_LINE_OR_MOBILE', 'AD').should.equal('INVALID_LENGTH'); // No mobile phones.

    checkNumberLength('8123', 'FIXED_LINE_OR_MOBILE', 'TA').should.equal('IS_POSSIBLE'); // No "possible lengths" for "mobile".

    checkNumberLength('81234567', 'FIXED_LINE_OR_MOBILE', 'SZ').should.equal('IS_POSSIBLE');
  });
  it('should work for old metadata', function () {
    var _oldMetadata = new _metadata2["default"](_metadataMin["default"]);

    _oldMetadata.country('RU');

    (0, _checkNumberLength.checkNumberLengthForType)('8005553535', 'FIXED_LINE', _oldMetadata).should.equal('IS_POSSIBLE');
  });
});

function checkNumberLength(number, type, country) {
  var _metadata = new _metadata2["default"](_metadataMax["default"]);

  _metadata.country(country);

  return (0, _checkNumberLength.checkNumberLengthForType)(number, type, _metadata);
}
//# sourceMappingURL=checkNumberLength.test.js.map