"use strict";

var _extractNationalNumber = _interopRequireDefault(require("./extractNationalNumber.js"));

var _metadata = _interopRequireDefault(require("../metadata.js"));

var _metadataMin = _interopRequireDefault(require("../../test/metadata/1.0.0/metadata.min.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

describe('extractNationalNumber', function () {
  it('should extract a national number when using old metadata', function () {
    var _oldMetadata = new _metadata["default"](_metadataMin["default"]);

    _oldMetadata.selectNumberingPlan('RU');

    (0, _extractNationalNumber["default"])('88005553535', _oldMetadata).should.deep.equal({
      nationalNumber: '8005553535',
      carrierCode: undefined
    });
  });
});
//# sourceMappingURL=extractNationalNumber.test.js.map