"use strict";

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _metadataMin2 = _interopRequireDefault(require("../test/metadata/1.0.0/metadata.min.json"));

var _metadataMin3 = _interopRequireDefault(require("../test/metadata/1.1.11/metadata.min.json"));

var _metadataMin4 = _interopRequireDefault(require("../test/metadata/1.7.34/metadata.min.json"));

var _metadataMin5 = _interopRequireDefault(require("../test/metadata/1.7.37/metadata.min.json"));

var _metadata = _interopRequireWildcard(require("./metadata.js"));

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

describe('metadata', function () {
  it('should return undefined for non-defined types', function () {
    var FR = new _metadata["default"](_metadataMin["default"]).country('FR');
    type(FR.type('FIXED_LINE')).should.equal('undefined');
  });
  it('should validate country', function () {
    var thrower = function thrower() {
      return new _metadata["default"](_metadataMin["default"]).country('RUS');
    };

    thrower.should["throw"]('Unknown country');
  });
  it('should tell if a country is supported', function () {
    (0, _metadata.isSupportedCountry)('RU', _metadataMin["default"]).should.equal(true);
    (0, _metadata.isSupportedCountry)('XX', _metadataMin["default"]).should.equal(false);
  });
  it('should return ext prefix for a country', function () {
    (0, _metadata.getExtPrefix)('US', _metadataMin["default"]).should.equal(' ext. ');
    (0, _metadata.getExtPrefix)('CA', _metadataMin["default"]).should.equal(' ext. ');
    (0, _metadata.getExtPrefix)('GB', _metadataMin["default"]).should.equal(' x'); // expect(getExtPrefix('XX', metadata)).to.equal(undefined)

    (0, _metadata.getExtPrefix)('XX', _metadataMin["default"]).should.equal(' ext. ');
  });
  it('should cover non-occuring edge cases', function () {
    new _metadata["default"](_metadataMin["default"]).getNumberingPlanMetadata('999');
  });
  it('should support deprecated methods', function () {
    new _metadata["default"](_metadataMin["default"]).country('US').nationalPrefixForParsing().should.equal('1');
    new _metadata["default"](_metadataMin["default"]).chooseCountryByCountryCallingCode('1').nationalPrefixForParsing().should.equal('1');
  });
  it('should tell if a national prefix is mandatory when formatting a national number', function () {
    var meta = new _metadata["default"](_metadataMin["default"]); // No "national_prefix_formatting_rule".
    // "national_prefix_is_optional_when_formatting": true

    meta.country('US');
    meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(false); // "national_prefix_formatting_rule": "8 ($1)"
    // "national_prefix_is_optional_when_formatting": true

    meta.country('RU');
    meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(false); // "national_prefix": "0"
    // "national_prefix_formatting_rule": "0 $1"

    meta.country('FR');
    meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(true);
  });
  it('should validate metadata', function () {
    var thrower = function thrower() {
      return (0, _metadata.validateMetadata)();
    };

    thrower.should["throw"]('`metadata` argument not passed');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)(123);
    };

    thrower.should["throw"]('Got a number: 123.');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)('abc');
    };

    thrower.should["throw"]('Got a string: abc.');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)({
        a: true,
        b: 2
      });
    };

    thrower.should["throw"]('Got an object of shape: { a, b }.');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)({
        a: true,
        countries: 2
      });
    };

    thrower.should["throw"]('Got an object of shape: { a, countries }.');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)({
        country_calling_codes: true,
        countries: 2
      });
    };

    thrower.should["throw"]('Got an object of shape');

    thrower = function thrower() {
      return (0, _metadata.validateMetadata)({
        country_calling_codes: {},
        countries: 2
      });
    };

    thrower.should["throw"]('Got an object of shape');
    (0, _metadata.validateMetadata)({
      country_calling_codes: {},
      countries: {},
      b: 3
    });
  });
  it('should work around `nonGeographical` typo in metadata generated from `1.7.35` to `1.7.37`', function () {
    var meta = new _metadata["default"](_metadataMin5["default"]);
    meta.selectNumberingPlan('888');
    type(meta.nonGeographic()).should.equal('object');
  });
  it('should work around `nonGeographic` metadata not existing before `1.7.35`', function () {
    var meta = new _metadata["default"](_metadataMin4["default"]);
    type(meta.getNumberingPlanMetadata('800')).should.equal('object');
    type(meta.getNumberingPlanMetadata('000')).should.equal('undefined');
  });
  it('should work with metadata from version `1.1.11`', function () {
    var meta = new _metadata["default"](_metadataMin3["default"]);
    meta.selectNumberingPlan('US');
    meta.numberingPlan.possibleLengths().should.deep.equal([10]);
    meta.numberingPlan.formats().length.should.equal(1);
    meta.numberingPlan.nationalPrefix().should.equal('1');
    meta.numberingPlan.nationalPrefixForParsing().should.equal('1');
    meta.numberingPlan.type('MOBILE').pattern().should.equal('');
    meta.selectNumberingPlan('AG');
    meta.numberingPlan.leadingDigits().should.equal('268'); // Should've been "268$1" but apparently there was a bug in metadata generator
    // and no national prefix transform rules were written.

    expect(meta.numberingPlan.nationalPrefixTransformRule()).to.be["null"];
    meta.selectNumberingPlan('AF');
    meta.numberingPlan.formats()[0].nationalPrefixFormattingRule().should.equal('0$1');
    meta.selectNumberingPlan('RU');
    meta.numberingPlan.formats()[0].nationalPrefixIsOptionalWhenFormattingInNationalFormat().should.equal(true);
  });
  it('should work with metadata from version `1.0.0`', function () {
    var meta = new _metadata["default"](_metadataMin2["default"]);
    meta.selectNumberingPlan('US');
    meta.numberingPlan.formats().length.should.equal(1);
    meta.numberingPlan.nationalPrefix().should.equal('1');
    meta.numberingPlan.nationalPrefixForParsing().should.equal('1');
    type(meta.numberingPlan.type('MOBILE')).should.equal('undefined');
    meta.selectNumberingPlan('AG');
    meta.numberingPlan.leadingDigits().should.equal('268'); // Should've been "268$1" but apparently there was a bug in metadata generator
    // and no national prefix transform rules were written.

    expect(meta.numberingPlan.nationalPrefixTransformRule()).to.be["null"];
    meta.selectNumberingPlan('AF');
    meta.numberingPlan.formats()[0].nationalPrefixFormattingRule().should.equal('0$1');
    meta.selectNumberingPlan('RU');
    meta.numberingPlan.formats()[0].nationalPrefixIsOptionalWhenFormattingInNationalFormat().should.equal(true);
  });
  it('should work around "ext" data not present in metadata from version `1.0.0`', function () {
    var meta = new _metadata["default"](_metadataMin2["default"]);
    meta.selectNumberingPlan('GB');
    meta.ext().should.equal(' ext. ');
    var metaNew = new _metadata["default"](_metadataMin["default"]);
    metaNew.selectNumberingPlan('GB');
    metaNew.ext().should.equal(' x');
  });
  it('should work around "default IDD prefix" data not present in metadata from version `1.0.0`', function () {
    var meta = new _metadata["default"](_metadataMin2["default"]);
    meta.selectNumberingPlan('AU');
    type(meta.defaultIDDPrefix()).should.equal('undefined');
    var metaNew = new _metadata["default"](_metadataMin["default"]);
    metaNew.selectNumberingPlan('AU');
    metaNew.defaultIDDPrefix().should.equal('0011');
  });
});

function type(something) {
  return _typeof(something);
}
//# sourceMappingURL=metadata.test.js.map