"use strict";

var _metadata = _interopRequireDefault(require("../metadata.js"));

var _metadataMin = _interopRequireDefault(require("../../metadata.min.json"));

var _extractNationalNumberFromPossiblyIncompleteNumber = _interopRequireDefault(require("./extractNationalNumberFromPossiblyIncompleteNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('extractNationalNumberFromPossiblyIncompleteNumber', function () {
  it('should parse a carrier code when there is no national prefix transform rule', function () {
    var meta = new _metadata["default"](_metadataMin["default"]);
    meta.country('AU');
    (0, _extractNationalNumberFromPossiblyIncompleteNumber["default"])('18311800123', meta).should.deep.equal({
      nationalPrefix: undefined,
      carrierCode: '1831',
      nationalNumber: '1800123'
    });
  });
});
//# sourceMappingURL=extractNationalNumberFromPossiblyIncompleteNumber.test.js.map