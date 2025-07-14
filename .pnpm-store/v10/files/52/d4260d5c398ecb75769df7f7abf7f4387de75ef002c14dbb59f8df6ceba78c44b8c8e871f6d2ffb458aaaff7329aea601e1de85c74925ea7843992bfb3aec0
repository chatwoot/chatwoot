"use strict";

var _metadataMin = _interopRequireDefault(require("../metadata.min.json"));

var _AsYouType = _interopRequireDefault(require("./AsYouType.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

var AsYouType = /*#__PURE__*/function (_AsYouType_) {
  _inherits(AsYouType, _AsYouType_);

  var _super = _createSuper(AsYouType);

  function AsYouType(country_code) {
    _classCallCheck(this, AsYouType);

    return _super.call(this, country_code, _metadataMin["default"]);
  }

  return _createClass(AsYouType);
}(_AsYouType["default"]);

var USE_NON_GEOGRAPHIC_COUNTRY_CODE = false;
describe('AsYouType', function () {
  it('should use "national_prefix_formatting_rule"', function () {
    // With national prefix (full).
    new AsYouType('RU').input('88005553535').should.equal('8 (800) 555-35-35'); // With national prefix (partial).

    new AsYouType('RU').input('880055535').should.equal('8 (800) 555-35');
  });
  it('should populate national number template (digit by digit)', function () {
    var formatter = new AsYouType('US');
    formatter.input('1'); // formatter.formatter.template.should.equal('x (xxx) xxx-xxxx')

    formatter.formatter.template.should.equal('x xxx-xxxx'); // formatter.formatter.populatedNationalNumberTemplate.should.equal('1 (xxx) xxx-xxxx')

    formatter.formatter.populatedNationalNumberTemplate.should.equal('1 xxx-xxxx');
    formatter.input('213');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('1 (213) xxx-xxxx');
    formatter.input('3734253');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('1 (213) 373-4253');
  });
  it('should populate international number template (digit by digit) (default country)', function () {
    var formatter = new AsYouType('US');
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('').should.equal('');
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('+').should.equal('+');
    formatter.getTemplate().should.equal('x');
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('1').should.equal('+1');
    formatter.getTemplate().should.equal('xx'); // Hasn't started formatting the phone number using the template yet.
    // formatter.formatter.template.should.equal('xx xxx xxx xxxx')

    formatter.formatter.template.should.equal('xx xxx xxxx'); // formatter.formatter.populatedNationalNumberTemplate.should.equal('xxx xxx xxxx')

    formatter.formatter.populatedNationalNumberTemplate.should.equal('xxx xxxx'); // Has some national number digits, starts formatting the phone number using the template.

    formatter.input('213');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('213 xxx xxxx');
    formatter.input('3734253');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('213 373 4253');
  });
  it('should populate international number template (digit by digit)', function () {
    var formatter = new AsYouType();
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('').should.equal('');
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('+').should.equal('+');
    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.formatter.populatedNationalNumberTemplate).to.be.undefined;
    formatter.input('1').should.equal('+1'); // formatter.formatter.template.should.equal('xx xxx xxx xxxx')

    formatter.formatter.template.should.equal('xx xxx xxxx'); // Hasn't yet started formatting the phone number using the template.
    // formatter.formatter.populatedNationalNumberTemplate.should.equal('xxx xxx xxxx')

    formatter.formatter.populatedNationalNumberTemplate.should.equal('xxx xxxx'); // Has some national number digits, starts formatting the phone number using the template.

    formatter.input('213');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('213 xxx xxxx');
    formatter.input('3734253');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('213 373 4253');
  });
  it('should populate national number template (attempt to format complete number)', function () {
    var formatter = new AsYouType('US');
    formatter.input('12133734253').should.equal('1 (213) 373-4253');
    formatter.formatter.template.should.equal('x (xxx) xxx-xxxx');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('1 (213) 373-4253');
  });
  it('should parse and format phone numbers as you type', function () {
    // International number test
    new AsYouType().input('+12133734').should.equal('+1 213 373 4'); // Local number test

    new AsYouType('US').input('2133734').should.equal('(213) 373-4'); // US national number retains national prefix.

    new AsYouType('US').input('12133734').should.equal('1 (213) 373-4'); // US national number retains national prefix (full number).

    new AsYouType('US').input('12133734253').should.equal('1 (213) 373-4253');
    var formatter; // // Should discard national prefix from a "complete" phone number.
    // new AsYouType('RU').input('8800555353').should.equal('880 055-53-53')
    // Shouldn't extract national prefix when inputting in international format.

    new AsYouType('RU').input('+7800555353').should.equal('+7 800 555 35 3');
    new AsYouType('CH').input('044-668-1').should.equal('044 668 1'); // Test International phone number (international)

    formatter = new AsYouType(); // formatter.valid.should.be.false

    type(formatter.getCountry()).should.equal('undefined');
    type(formatter.getCountryCallingCode()).should.equal('undefined');
    formatter.getTemplate().should.equal('');
    formatter.input('+').should.equal('+'); // formatter.valid.should.be.false

    type(formatter.getCountry()).should.equal('undefined');
    type(formatter.getCountryCallingCode()).should.equal('undefined');
    formatter.getTemplate().should.equal('x');
    formatter.input('1').should.equal('+1'); // formatter.valid.should.be.false

    type(formatter.getCountry()).should.equal('undefined');
    formatter.getCountryCallingCode().should.equal('1');
    formatter.getTemplate().should.equal('xx');
    formatter.input('2').should.equal('+1 2');
    formatter.getTemplate().should.equal('xx x'); // formatter.valid.should.be.false

    type(formatter.getCountry()).should.equal('undefined');
    formatter.input('1').should.equal('+1 21');
    formatter.input('3').should.equal('+1 213');
    formatter.input(' ').should.equal('+1 213');
    formatter.input('3').should.equal('+1 213 3');
    formatter.input('3').should.equal('+1 213 33');
    formatter.input('3').should.equal('+1 213 333');
    formatter.input('4').should.equal('+1 213 333 4');
    formatter.input('4').should.equal('+1 213 333 44');
    formatter.input('4').should.equal('+1 213 333 444'); // formatter.valid.should.be.false

    type(formatter.getCountry()).should.equal('undefined');
    formatter.input('4').should.equal('+1 213 333 4444'); // formatter.valid.should.be.true

    formatter.getCountry().should.equal('US'); // This one below contains "punctuation spaces"
    // along with the regular spaces

    formatter.getTemplate().should.equal('xx xxx xxx xxxx');
    formatter.input('5').should.equal('+1 21333344445'); // formatter.valid.should.be.false

    expect(formatter.getCountry()).to.be.undefined;
    formatter.getCountryCallingCode().should.equal('1');
    expect(formatter.formatter.template).to.be.undefined; // Check that clearing an international formatter
    // also clears country metadata.

    formatter.reset();
    formatter.input('+').should.equal('+');
    formatter.input('7').should.equal('+7');
    formatter.input('9').should.equal('+7 9');
    formatter.input('99 111 22 33').should.equal('+7 999 111 22 33'); // Test Switzerland phone numbers

    formatter = new AsYouType('CH');
    formatter.input(' ').should.equal('');
    formatter.input('0').should.equal('0');
    formatter.input('4').should.equal('04');
    formatter.input(' ').should.equal('04');
    formatter.input('-').should.equal('04');
    formatter.input('4').should.equal('044');
    formatter.input('-').should.equal('044');
    formatter.input('6').should.equal('044 6');
    formatter.input('6').should.equal('044 66');
    formatter.input('8').should.equal('044 668');
    formatter.input('-').should.equal('044 668');
    formatter.input('1').should.equal('044 668 1');
    formatter.input('8').should.equal('044 668 18'); // formatter.valid.should.be.false

    formatter.getCountry().should.equal('CH');
    formatter.formatter.template.should.equal('xxx xxx xx xx');
    formatter.getTemplate().should.equal('xxx xxx xx');
    formatter.input(' 00').should.equal('044 668 18 00'); // formatter.valid.should.be.true

    formatter.getCountry().should.equal('CH');
    formatter.getTemplate().should.equal('xxx xxx xx xx');
    formatter.input('9').should.equal('04466818009'); // formatter.valid.should.be.false

    formatter.getCountry().should.equal('CH');
    expect(formatter.formatter.template).to.be.undefined; // Kazakhstan (non-main country for +7 country phone code)

    formatter = new AsYouType();
    formatter.input('+77172580659');
    formatter.getCountry().should.equal('KZ'); // Brazil

    formatter = new AsYouType('BR');
    formatter.input('11987654321').should.equal('(11) 98765-4321'); // UK (Jersey) (non-main country for +44 country phone code)

    formatter = new AsYouType();
    formatter.input('+447700300000').should.equal('+44 7700 300000');
    formatter.getTemplate().should.equal('xxx xxxx xxxxxx');
    formatter.getCountry().should.equal('JE'); // Braces must be part of the template.

    formatter = new AsYouType('RU');
    formatter.input('88005553535').should.equal('8 (800) 555-35-35');
    formatter.getTemplate().should.equal('x (xxx) xxx-xx-xx'); // Test Russian phone numbers
    // (with optional national prefix `8`)

    formatter = new AsYouType('RU');
    formatter.input('8').should.equal('8');
    formatter.input('9').should.equal('8 9');
    formatter.input('9').should.equal('8 99');
    formatter.input('9').should.equal('8 (999)');
    formatter.input('-').should.equal('8 (999)');
    formatter.input('1234').should.equal('8 (999) 123-4');
    formatter.input('567').should.equal('8 (999) 123-45-67');
    formatter.input('8').should.equal('899912345678'); // Shouldn't strip national prefix if it is optional
    // and if it's a valid phone number (international).

    formatter = new AsYouType('RU'); // formatter.input('8005553535').should.equal('(800) 555-35-35')

    formatter.input('+78005553535').should.equal('+7 800 555 35 35');
    formatter.getNationalNumber().should.equal('8005553535'); // Check that clearing an national formatter:
    //  * doesn't clear country metadata
    //  * clears all other things

    formatter.reset();
    formatter.input('8').should.equal('8');
    formatter.input('9').should.equal('8 9');
    formatter.input('9').should.equal('8 99');
    formatter.input('9').should.equal('8 (999)');
    formatter.input('-').should.equal('8 (999)');
    formatter.input('1234').should.equal('8 (999) 123-4');
    formatter.input('567').should.equal('8 (999) 123-45-67');
    formatter.input('8').should.equal('899912345678'); // National prefix should not be prepended
    // when formatting local NANPA phone numbers.

    new AsYouType('US').input('1').should.equal('1');
    new AsYouType('US').input('12').should.equal('1 2');
    new AsYouType('US').input('123').should.equal('1 23'); // Bulgaria
    // (should not prepend national prefix `0`)

    new AsYouType('BG').input('111 222 3').should.equal('1112223'); // Deutchland

    new AsYouType().input('+4915539898001').should.equal('+49 15539 898001'); // KZ detection

    formatter = new AsYouType();
    formatter.input('+7 702 211 1111');
    formatter.getCountry().should.equal('KZ'); // formatter.valid.should.equal(true)
    // New Zealand formatting fix (issue #89)

    new AsYouType('NZ').input('0212').should.equal('021 2'); // South Korea

    formatter = new AsYouType();
    formatter.input('+82111111111').should.equal('+82 11 111 1111');
    formatter.getTemplate().should.equal('xxx xx xxx xxxx');
  });
  it('should filter out formats that require a national prefix and no national prefix has been input', function () {
    // Afghanistan.
    var formatter = new AsYouType('AF'); // No national prefix, and national prefix is required in the format.
    // (not `"national_prefix_is_optional_when_formatting": true`)

    formatter.input('44444444').should.equal('44444444');
    expect(formatter.formatter.template).to.be.undefined; // With national prefix

    formatter.reset().input('044444444').should.equal('044 444 444');
    formatter.formatter.template.should.equal('xxx xxx xxxx');
  });
  it('should work when a digit is not a national prefix but a part of a valid national number', function () {
    // In Russia, `8` could be both a valid national prefix
    // and a part of a valid national number.
    var formatter = new AsYouType('RU'); // The formatter could try both variants:
    // with extracting national prefix
    // and without extracting it,
    // and then choose whichever way has `this.matchingFormats`.
    // Or there could be two instances of the formatter:
    // one that extracts national prefix and one that doesn't,
    // and then the one that has `this.matchingFormats` would be
    // used to format the phone number.
    // Something like an option `extractNationalPrefix: false`
    // and creating `this.withNationalPrefixFormatter = new AsYouType(this.defaultCountry || this.defaultCallingCode, { metadata, extractNationalPrefix: false })`
    // and something like `this.withNationalPrefixFormatter.input(nextDigits)` in `input(nextDigits)`.
    // But, for this specific case, it's not required:
    // in Russia, people are used to inputting `800` numbers with national prefix `8`:
    // `8 800 555 35 35`.
    // formatter.input('8005553535').should.equal('(800) 555-35-35')

    formatter.input('8005553535').should.equal('8005553535');
    formatter.reset();
    formatter.input('+78005553535').should.equal('+7 800 555 35 35');
  });
  it('should match formats that require a national prefix and no national prefix has been input (national prefix is mandatory for a format)', function () {
    var formatter = new AsYouType('FR');
    formatter.input('612345678').should.equal('612345678');
    formatter.reset();
    formatter.input('0612345678').should.equal('06 12 34 56 78');
  });
  it('should match formats that require a national prefix and no national prefix has been input (national prefix is not mandatory for a format)', function () {
    var formatter = new AsYouType('RU'); // Without national prefix.

    formatter.input('9991234567').should.equal('999 123-45-67');
    formatter.reset(); // With national prefix.

    formatter.input('89991234567').should.equal('8 (999) 123-45-67');
  });
  it('should not use `national_prefix_formatting_rule` when formatting international phone numbers', function () {
    // Brazil.
    // `national_prefix_formatting_rule` is `($1)`.
    // Should not add braces around `12` when being input in international format.
    new AsYouType().input('+55123456789').should.equal('+55 12 3456 789');
    new AsYouType('BR').input('+55123456789').should.equal('+55 12 3456 789');
    new AsYouType('BR').input('123456789').should.equal('(12) 3456-789');
  });
  it('should support incorrectly entered international phone numbers (with a national prefix)', function () {
    var formatter;
    formatter = new AsYouType();
    formatter.input('+1 1 877 215 5230').should.equal('+1 1 877 215 5230'); // formatter.input('+1 1 877 215 5230').should.equal('+1 1 8772155230')

    formatter.getNationalNumber().should.equal('8772155230'); // They've added another number format that has `8` leading digit
    // and 14 digits. Maybe it's something related to Kazakhstan.
    // formatter = new AsYouType()
    // formatter.input('+78800555353').should.equal('+7 880 055 53 53')
    // formatter.input('5').should.equal('+7 8 800 555 35 35')
    // formatter.getNationalNumber().should.equal('8005553535')
  });
  it('should return a partial template for current value', function () {
    var asYouType = new AsYouType('US');
    asYouType.input('').should.equal('');
    asYouType.getTemplate().should.equal('');
    asYouType.input('2').should.equal('2'); // asYouType.getTemplate().should.equal('x')
    // Doesn't format for a single digit.

    asYouType.getTemplate().should.equal('x');
    asYouType.input('1').should.equal('21');
    asYouType.getTemplate().should.equal('xx');
    asYouType.input('3').should.equal('(213)');
    asYouType.getTemplate().should.equal('(xxx)');
  });
  it("should fall back to the default country", function () {
    var formatter = new AsYouType('RU');
    formatter.input('8').should.equal('8');
    formatter.input('9').should.equal('8 9');
    formatter.input('9').should.equal('8 99');
    formatter.input('9').should.equal('8 (999)'); // formatter.valid.should.be.false

    formatter.formatter.template.should.equal('x (xxx) xxx-xx-xx');
    formatter.getCountry().should.equal('RU'); // formatter.getCountryCallingCode().should.equal('7')

    formatter.input('000000000000').should.equal('8999000000000000'); // formatter.valid.should.be.false

    expect(formatter.formatter.template).to.be.undefined;
    formatter.getCountry().should.equal('RU'); // formatter.getCountryCallingCode().should.equal('7')

    formatter.reset(); // formatter.valid.should.be.false

    expect(formatter.formatter.template).to.be.undefined;
    expect(formatter.getCountry()).to.be.undefined; // formatter.getCountryCallingCode().should.equal('7')

    formatter.input('+1-213-373-4253').should.equal('+1 213 373 4253'); // formatter.valid.should.be.true

    formatter.getTemplate().should.equal('xx xxx xxx xxxx');
    formatter.getCountry().should.equal('US');
    formatter.getCountryCallingCode().should.equal('1');
  });
  it('should work in edge cases', function () {
    var formatter;
    var thrower; // No metadata

    thrower = function thrower() {
      return new _AsYouType["default"]('RU');
    };

    thrower.should["throw"]('`metadata` argument not passed'); // Second '+' sign

    formatter = new AsYouType('RU');
    formatter.input('+').should.equal('+');
    formatter.input('7').should.equal('+7');
    formatter.input('+').should.equal('+7'); // Out-of-position '+' sign

    formatter = new AsYouType('RU');
    formatter.input('8').should.equal('8');
    formatter.input('+').should.equal('8'); // No format matched

    formatter = new AsYouType('RU');
    formatter.input('88005553535').should.equal('8 (800) 555-35-35');
    formatter.input('0').should.equal('880055535350'); // Invalid country phone code

    formatter = new AsYouType();
    formatter.input('+0123').should.equal('+0123'); // No country specified and not an international number

    formatter = new AsYouType();
    formatter.input('88005553535').should.equal('88005553535'); // Extract national prefix when no `national_prefix` is set

    formatter = new AsYouType('AD');
    formatter.input('155555').should.equal('155 555'); // Typing nonsense

    formatter = new AsYouType('RU');
    formatter.input('+1abc2').should.equal('+1'); // Should reset default country when explicitly
    // typing in an international phone number

    formatter = new AsYouType('RU');
    formatter.input('+');
    type(formatter.getCountry()).should.equal('undefined');
    type(formatter.getCountryCallingCode()).should.equal('undefined'); // Country not inferrable from the phone number,
    // while the phone number itself can already be formatted "completely".

    formatter = new AsYouType();
    formatter.input('+12223333333');
    type(formatter.getCountry()).should.equal('undefined');
    formatter.getCountryCallingCode().should.equal('1'); // Reset a chosen format when it no longer applies given the new leading digits.
    // If Google changes metadata for England then this test might not cover the case.

    formatter = new AsYouType('GB');
    formatter.input('0845').should.equal('0845'); // New leading digits don't match the format previously chosen.
    // Reset the format.

    formatter.input('0').should.equal('0845 0');
  });
  it('should choose between matching formats based on the absence or presence of a national prefix', function () {
    // The first matching format:
    // {
    //    "pattern": "(\\d{2})(\\d{5,6})",
    //    "leading_digits_patterns": [
    //       "(?:10|2[0-57-9])[19]",
    //       "(?:10|2[0-57-9])(?:10|9[56])",
    //       "(?:10|2[0-57-9])(?:100|9[56])"
    //    ],
    //    "national_prefix_formatting_rule": "0$1",
    //    "format": "$1 $2",
    //    "domestic_carrier_code_formatting_rule": "$CC $FG"
    // }
    //
    // The second matching format:
    // {
    //    "pattern": "(\\d{2})(\\d{4})(\\d{4})",
    //    "leading_digits_patterns": [
    //       "10|2(?:[02-57-9]|1[1-9])",
    //       "10|2(?:[02-57-9]|1[1-9])",
    //       "10[0-79]|2(?:[02-57-9]|1[1-79])|(?:10|21)8(?:0[1-9]|[1-9])"
    //    ],
    //    "national_prefix_formatting_rule": "0$1",
    //    "national_prefix_is_optional_when_formatting": true,
    //    "format": "$1 $2 $3",
    //    "domestic_carrier_code_formatting_rule": "$CC $FG"
    // }
    //
    var formatter = new AsYouType('CN'); // National prefix has been input.
    // Chooses the first format.

    formatter.input('01010000').should.equal('010 10000');
    formatter.reset(); // No national prefix has been input,
    // and `national_prefix_for_parsing` not matched.
    // The first format won't match, because it doesn't have
    // `"national_prefix_is_optional_when_formatting": true`.
    // The second format will match, because it does have
    // `"national_prefix_is_optional_when_formatting": true`.

    formatter.input('1010000').should.equal('10 1000 0');
  });
  it('should not accept phone number extensions', function () {
    new AsYouType().input('+1-213-373-4253 ext. 123').should.equal('+1 213 373 4253');
  });
  it('should parse non-European digits', function () {
    new AsYouType().input('+١٢١٢٢٣٢٣٢٣٢').should.equal('+1 212 232 3232');
  });
  it('should return a PhoneNumber instance', function () {
    var formatter = new AsYouType('BR'); // No country calling code.

    expect(formatter.getNumber()).to.be.undefined;
    formatter.input('+1'); // No national number digits.

    expect(formatter.getNumber()).to.be.undefined;
    formatter.input('213-373-4253');
    var phoneNumber = formatter.getNumber();
    phoneNumber.country.should.equal('US');
    phoneNumber.countryCallingCode.should.equal('1');
    phoneNumber.number.should.equal('+12133734253');
    phoneNumber.nationalNumber.should.equal('2133734253');
    formatter.reset();
    formatter.input('+1-113-373-4253');
    phoneNumber = formatter.getNumber();
    expect(phoneNumber.country).to.be.undefined;
    phoneNumber.countryCallingCode.should.equal('1'); // An incorrect NANPA international phone number.
    // (contains national prefix in an international phone number)

    formatter.reset();
    formatter.input('+1-1'); // Before leading digits < 3 matching was implemented:
    //
    // phoneNumber = formatter.getNumber()
    // expect(phoneNumber).to.not.be.undefined
    //
    // formatter.input('1')
    // phoneNumber = formatter.getNumber()
    // expect(phoneNumber.country).to.be.undefined
    // phoneNumber.countryCallingCode.should.equal('1')
    // phoneNumber.number.should.equal('+111')
    // After leading digits < 3 matching was implemented:
    //

    phoneNumber = formatter.getNumber();
    expect(phoneNumber).to.be.undefined; //

    formatter.input('1');
    phoneNumber = formatter.getNumber();
    expect(phoneNumber.country).to.be.undefined;
    phoneNumber.countryCallingCode.should.equal('1');
    phoneNumber.number.should.equal('+11');
  });
  it('should work with countries that add digits to national (significant) number', function () {
    // When formatting Argentinian mobile numbers in international format,
    // a `9` is prepended, when compared to national format.
    var asYouType = new AsYouType('AR');
    asYouType.input('+5493435551212').should.equal('+54 9 3435 55 1212');
    asYouType.reset(); // Digits shouldn't be changed when formatting in national format.
    // (no `9` is prepended).
    // First parses national (significant) number by prepending `9` to it
    // and stripping `15` from it.
    // Then uses `$2 15-$3-$4` format that strips the leading `9`
    // and adds `15`.

    asYouType.input('0343515551212').should.equal('03435 15-55-1212');
  });
  it('should return non-formatted phone number when no format matches and national (significant) number has digits added', function () {
    // When formatting Argentinian mobile numbers in international format,
    // a `9` is prepended, when compared to national format.
    var asYouType = new AsYouType('AR'); // Digits shouldn't be changed when formatting in national format.
    // (no `9` is prepended).
    // First parses national (significant) number by prepending `9` to it
    // and stripping `15` from it.
    // Then uses `$2 15-$3-$4` format that strips the leading `9`
    // and adds `15`.
    // `this.nationalSignificantNumberMatchesInput` is `false` in this case,
    // so `getNonFormattedNumber()` returns `getFullNumber(getNationalDigits())`.

    asYouType.input('0343515551212999').should.equal('0343515551212999');
  });
  it('should format Argentina numbers (starting with 011) (digit by digit)', function () {
    // Inputting a number digit-by-digit and as a whole a two different cases
    // in case of this library compared to Google's `libphonenumber`
    // that always inputs a number digit-by-digit.
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/23
    // nextDigits 0111523456789
    // nationalNumber 91123456789
    var formatter = new AsYouType('AR');
    formatter.input('0').should.equal('0');
    formatter.getTemplate().should.equal('x');
    formatter.input('1').should.equal('01');
    formatter.getTemplate().should.equal('xx');
    formatter.input('1').should.equal('011');
    formatter.getTemplate().should.equal('xxx');
    formatter.input('1').should.equal('011 1');
    formatter.getTemplate().should.equal('xxx x');
    formatter.input('5').should.equal('011 15');
    formatter.getTemplate().should.equal('xxx xx');
    formatter.input('2').should.equal('011 152');
    formatter.getTemplate().should.equal('xxx xxx');
    formatter.input('3').should.equal('011 1523');
    formatter.getTemplate().should.equal('xxx xxxx');
    formatter.input('4').should.equal('011 1523-4');
    formatter.getTemplate().should.equal('xxx xxxx-x');
    formatter.input('5').should.equal('011 1523-45');
    formatter.getTemplate().should.equal('xxx xxxx-xx');
    formatter.input('6').should.equal('011 1523-456');
    formatter.getTemplate().should.equal('xxx xxxx-xxx');
    formatter.input('7').should.equal('011 1523-4567');
    formatter.getTemplate().should.equal('xxx xxxx-xxxx');
    formatter.input('8').should.equal('011152345678');
    formatter.getTemplate().should.equal('xxxxxxxxxxxx');
    formatter.input('9').should.equal('011 15-2345-6789');
    formatter.getTemplate().should.equal('xxx xx-xxxx-xxxx'); // Private property (not public API).

    formatter.state.nationalSignificantNumber.should.equal('91123456789'); // Private property (not public API).
    // `formatter.digits` is not always `formatter.nationalPrefix`
    // plus `formatter.nationalNumberDigits`.

    formatter.state.nationalPrefix.should.equal('0');
    formatter.isPossible().should.equal(true);
    formatter.isValid().should.equal(true);
  });
  it('should format Argentina numbers (starting with 011)', function () {
    // Inputting a number digit-by-digit and as a whole a two different cases
    // in case of this library compared to Google's `libphonenumber`
    // that always inputs a number digit-by-digit.
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/23
    // nextDigits 0111523456789
    // nationalNumber 91123456789
    var formatter = new AsYouType('AR');
    formatter.input('0111523456789').should.equal('011 15-2345-6789'); // Private property (not public API).

    formatter.state.nationalSignificantNumber.should.equal('91123456789'); // Private property (not public API).
    // `formatter.digits` is not always `formatter.nationalPrefix`
    // plus `formatter.nationalNumberDigits`.

    expect(formatter.state.nationalPrefix).to.equal('0'); // expect(formatter.nationalPrefix).to.be.undefined

    formatter.isPossible().should.equal(true);
    formatter.isValid().should.equal(true);
  }); // https://gitlab.com/catamphetamine/react-phone-number-input/-/issues/93

  it('should format Indonesian numbers', function () {
    var formatter = new AsYouType('ID');
    formatter.getChars().should.equal(''); // Before leading digits < 3 matching was implemented:
    // formatter.input('081').should.equal('(081)')
    // After leading digits < 3 matching was implemented:

    formatter.input('081').should.equal('081');
  });
  it('should prepend `complexPrefixBeforeNationalSignificantNumber` (not a complete number)', function () {
    // A country having `national_prefix_for_parsing` with a "capturing group".
    // National prefix is either not used in a format or is optional.
    // Input phone number without a national prefix.
    var formatter = new AsYouType('AU');
    formatter.input('1831130345678').should.equal('1831 1303 456 78'); // Private property (not public API).

    formatter.state.nationalSignificantNumber.should.equal('130345678'); // Private property (not public API).
    // `formatter.digits` is not always `formatter.nationalPrefix`
    // plus `formatter.nationalNumberDigits`.

    expect(formatter.state.nationalPrefix).to.be.undefined;
    formatter.state.complexPrefixBeforeNationalSignificantNumber.should.equal('1831');
  });
  it('should prepend `complexPrefixBeforeNationalSignificantNumber` (complete number)', function () {
    // A country having `national_prefix_for_parsing` with a "capturing group".
    // National prefix is either not used in a format or is optional.
    // Input phone number without a national prefix.
    var formatter = new AsYouType('AU');
    formatter.input('18311303456789').should.equal('1831 1303 456 789'); // Private property (not public API).

    formatter.state.nationalSignificantNumber.should.equal('1303456789'); // Private property (not public API).
    // `formatter.digits` is not always `formatter.nationalPrefix`
    // plus `formatter.nationalNumberDigits`.

    expect(formatter.state.nationalPrefix).to.be.undefined;
    formatter.state.complexPrefixBeforeNationalSignificantNumber.should.equal('1831');
  });
  it('should work with Mexico numbers', function () {
    var asYouType = new AsYouType('MX'); // Fixed line. International.

    asYouType.input('+52(449)978-000').should.equal('+52 449 978 000');
    asYouType.input('1').should.equal('+52 449 978 0001');
    asYouType.reset(); // "Dialling tokens 01, 02, 044, 045 and 1 are removed as they are
    //  no longer valid since August 2019."
    // // Fixed line. National. With national prefix "01".
    // asYouType.input('01449978000').should.equal('01449 978 000')
    // asYouType.getTemplate().should.equal('xxxxx xxx xxx')
    // asYouType.input('1').should.equal('01449 978 0001')
    // asYouType.getTemplate().should.equal('xxxxx xxx xxxx')
    // asYouType.reset()
    // Fixed line. National. Without national prefix.

    asYouType.input('(449)978-000').should.equal('449 978 000');
    asYouType.getTemplate().should.equal('xxx xxx xxx');
    asYouType.input('1').should.equal('449 978 0001');
    asYouType.getTemplate().should.equal('xxx xxx xxxx');
    asYouType.reset(); // Mobile.

    asYouType.input('+52331234567').should.equal('+52 33 1234 567');
    asYouType.input('8').should.equal('+52 33 1234 5678');
    asYouType.reset(); // "Dialling tokens 01, 02, 044, 045 and 1 are removed as they are
    //  no longer valid since August 2019."
    // // Mobile.
    // // With `1` prepended before area code to mobile numbers in international format.
    // asYouType.input('+521331234567').should.equal('+52 133 1234 567')
    // asYouType.getTemplate().should.equal('xxx xxx xxxx xxx')
    // // Google's `libphonenumber` seems to not able to format this type of number.
    // // https://issuetracker.google.com/issues/147938979
    // asYouType.input('8').should.equal('+52 133 1234 5678')
    // asYouType.getTemplate().should.equal('xxx xxx xxxx xxxx')
    // asYouType.reset()
    //
    // // Mobile. National. With "044" prefix.
    // asYouType.input('044331234567').should.equal('04433 1234 567')
    // asYouType.input('8').should.equal('04433 1234 5678')
    // asYouType.reset()
    //
    // // Mobile. National. With "045" prefix.
    // asYouType.input('045331234567').should.equal('04533 1234 567')
    // asYouType.input('8').should.equal('04533 1234 5678')
  });
  it('should just prepend national prefix if national_prefix_formatting_rule does not produce a suitable number', function () {
    // "national_prefix": "8"
    // "national_prefix_for_parsing": "0|80?"
    var formatter = new AsYouType('BY'); // "national_prefix_formatting_rule": "8 $1"
    // That `national_prefix_formatting_rule` isn't used
    // because the user didn't input national prefix `8`.

    formatter.input('0800123').should.equal('0 800 123');
    formatter.getTemplate().should.equal('x xxx xxx');
  });
  it('should not duplicate area code for certain countries', function () {
    // https://github.com/catamphetamine/libphonenumber-js/issues/318
    var asYouType = new AsYouType('VI'); // Even though `parse("3406934")` would return a
    // "(340) 340-6934" national number, still
    // "As You Type" formatter should leave it as "(340) 6934".

    asYouType.input('340693').should.equal('(340) 693');
    asYouType.input('4').should.equal('(340) 693-4');
    asYouType.input('123').should.equal('(340) 693-4123');
  });
  it('shouldn\'t throw when passed a non-existent default country', function () {
    new AsYouType('XX').input('+78005553535').should.equal('+7 800 555 35 35');
    new AsYouType('XX').input('88005553535').should.equal('88005553535');
  });
  it('should parse carrier codes', function () {
    var formatter = new AsYouType('BR');
    formatter.input('0 15 21 5555-5555');
    var phoneNumber = formatter.getNumber();
    phoneNumber.carrierCode.should.equal('15');
    formatter.reset();
    formatter.input('+1-213-373-4253');
    phoneNumber = formatter.getNumber();
    expect(phoneNumber.carrierCode).to.be.undefined;
  });
  it('should format when default country calling code is configured', function () {
    var formatter = new AsYouType({
      defaultCallingCode: '7'
    });
    formatter.input('88005553535').should.equal('8 (800) 555-35-35');
    formatter.getNumber().countryCallingCode.should.equal('7');
    formatter.getNumber().country.should.equal('RU');
  });
  it('shouldn\'t return PhoneNumber if country calling code hasn\'t been input yet', function () {
    var formatter = new AsYouType();
    formatter.input('+80');
    expect(formatter.getNumber()).to.be.undefined;
  });
  it('should format non-geographic numbering plan phone numbers', function () {
    var formatter = new AsYouType();
    formatter.input('+').should.equal('+');
    formatter.input('8').should.equal('+8');
    formatter.input('7').should.equal('+87');
    expect(formatter.getCountry()).to.be.undefined;
    formatter.input('0').should.equal('+870');

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      formatter.getCountry().should.equal('001');
    } else {
      expect(formatter.getCountry()).to.be.undefined;
    }

    formatter.input('7').should.equal('+870 7');
    formatter.input('7').should.equal('+870 77');
    formatter.input('3').should.equal('+870 773');
    formatter.input('1').should.equal('+870 773 1');
    formatter.input('1').should.equal('+870 773 11');
    formatter.input('1').should.equal('+870 773 111');
    formatter.input('6').should.equal('+870 773 111 6');
    formatter.input('3').should.equal('+870 773 111 63');
    formatter.input('2').should.equal('+870 773 111 632');

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      formatter.getNumber().country.should.equal('001');
    } else {
      expect(formatter.getCountry()).to.be.undefined;
    }

    formatter.getNumber().countryCallingCode.should.equal('870');
  });
  it('should format non-geographic numbering plan phone numbers (default country calling code)', function () {
    var formatter = new AsYouType({
      defaultCallingCode: '870'
    });

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      formatter.getNumber().country.should.equal('001');
    } else {
      expect(formatter.getCountry()).to.be.undefined;
    }

    formatter.input('7').should.equal('7');
    formatter.input('7').should.equal('77');
    formatter.input('3').should.equal('773');
    formatter.input('1').should.equal('773 1');
    formatter.input('1').should.equal('773 11');
    formatter.input('1').should.equal('773 111');
    formatter.input('6').should.equal('773 111 6');
    formatter.input('3').should.equal('773 111 63');
    formatter.input('2').should.equal('773 111 632');

    if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
      formatter.getNumber().country.should.equal('001');
    } else {
      expect(formatter.getCountry()).to.be.undefined;
    }

    formatter.getNumber().countryCallingCode.should.equal('870');
  });
  it('should not format non-geographic numbering plan phone numbers (default country 001)', function () {
    var formatter = new AsYouType('001');
    expect(formatter.defaultCountry).to.be.undefined;
    expect(formatter.defaultCallingCode).to.be.undefined;
    formatter.input('7').should.equal('7');
    formatter.input('7').should.equal('77');
    formatter.input('3').should.equal('773');
    formatter.input('1').should.equal('7731');
    formatter.input('1').should.equal('77311');
    formatter.input('1').should.equal('773111');
    formatter.input('6').should.equal('7731116');
    formatter.input('3').should.equal('77311163');
    formatter.input('2').should.equal('773111632');
    expect(formatter.getCountry()).to.be.undefined;
    expect(formatter.getNumber()).to.be.undefined;
  });
  it('should return PhoneNumber (should strip national prefix `1` in E.164 value)', function () {
    var formatter = new AsYouType('RU');
    formatter.input('+1111');
    formatter.getNumber().number.should.equal('+111');
  });
  it('should return PhoneNumber with autocorrected international numbers without leading +', function () {
    // https://github.com/catamphetamine/libphonenumber-js/issues/316
    var formatter = new AsYouType('FR');
    formatter.input('33612902554').should.equal('33 6 12 90 25 54');
    formatter.getNumber().country.should.equal('FR');
    formatter.getNumber().nationalNumber.should.equal('612902554');
    formatter.getNumber().number.should.equal('+33612902554'); // Should also strip national prefix.

    formatter.reset();
    formatter.input('330612902554').should.equal('33 06 12 90 25 54');
    formatter.getNumber().country.should.equal('FR');
    formatter.getNumber().nationalNumber.should.equal('612902554');
    formatter.getNumber().number.should.equal('+33612902554'); // On second thought, this "prepend default area code" feature won't be added,
    // because when a user selects "British Virgin Islands" and inputs
    // "2291234", then they see "(229) 123-4" which clearly indicates that
    // they should input the complete phone number (with area code).
    // So, unless a user completely doesn't understand what they're doing,
    // they'd input the complete phone number (with area code).
    // // Should prepend the default area code in British Virgin Islands.
    // // https://github.com/catamphetamine/react-phone-number-input/issues/335
    // const formatter2 = new AsYouType('VG')
    // formatter2.input('2291234').should.equal('(229) 123-4')
    // formatter2.getNumber().country.should.equal('VG')
    // formatter2.getNumber().nationalNumber.should.equal('2842291234')
    // formatter2.getNumber().number.should.equal('+12842291234')
  });
  it('should work with out-of-country dialing prefix (like 00)', function () {
    var formatter = new AsYouType('DE');
    formatter.input('00498911196611').should.equal('00 49 89 11196611');
    formatter.getCountry().should.equal('DE');
    formatter.formatter.template.should.equal('xx xx xx xxxxxxxx');
    formatter.formatter.populatedNationalNumberTemplate.should.equal('89 11196611');
    formatter.getTemplate().should.equal('xx xx xx xxxxxxxx');
    formatter.getNumber().country.should.equal('DE');
    formatter.getNumber().nationalNumber.should.equal('8911196611');
    formatter.getNumber().number.should.equal('+498911196611');
  });
  it('shouldn\'t choose a format when there\'re too many digits for any of them', function () {
    var formatter = new AsYouType('RU');
    formatter.input('89991112233');
    formatter.formatter.chosenFormat.format().should.equal('$1 $2-$3-$4');
    formatter.reset();
    formatter.input('899911122334');
    expect(formatter.formatter.chosenFormat).to.be.undefined;
  });
  it('should get separator after national prefix', function () {
    // Russia.
    // Has separator after national prefix.
    var formatter = new AsYouType('RU');
    var format = formatter.metadata.formats()[0];
    format.nationalPrefixFormattingRule().should.equal('8 ($1)');
    formatter.formatter.getSeparatorAfterNationalPrefix(format).should.equal(' '); // Britain.
    // Has no separator after national prefix.

    var formatter2 = new AsYouType('GB');
    var format2 = formatter2.metadata.formats()[0];
    format2.nationalPrefixFormattingRule().should.equal('0$1');
    formatter2.formatter.getSeparatorAfterNationalPrefix(format2).should.equal('');
  });
  it('should return if the number is possible', function () {
    // National. Russia.
    var formatter = new AsYouType('RU');
    formatter.isPossible().should.equal(false);
    formatter.input('8');
    formatter.isPossible().should.equal(false);
    formatter.input('8005553535');
    formatter.isPossible().should.equal(true);
    formatter.input('5');
    formatter.isPossible().should.equal(false);
  });
  it('should return if the number is valid', function () {
    // National. Russia.
    var formatter = new AsYouType('RU');
    formatter.isValid().should.equal(false);
    formatter.input('88005553535');
    formatter.isValid().should.equal(true);
    formatter.input('5');
    formatter.isValid().should.equal(false);
  });
  it('should return if the number is international', function () {
    // National. Russia.
    var formatter = new AsYouType('RU');
    formatter.isInternational().should.equal(false);
    formatter.input('88005553535');
    formatter.isInternational().should.equal(false); // International. Russia.

    var formatterInt = new AsYouType();
    formatterInt.isInternational().should.equal(false);
    formatterInt.input('+');
    formatterInt.isInternational().should.equal(true);
    formatterInt.input('78005553535');
    formatterInt.isInternational().should.equal(true);
  });
  it('should return country calling code part of the number', function () {
    // National. Russia.
    var formatter = new AsYouType('RU');
    expect(formatter.getCountryCallingCode()).to.be.undefined;
    formatter.input('88005553535');
    expect(formatter.getCountryCallingCode()).to.be.undefined; // International. Russia.

    var formatterInt = new AsYouType();
    expect(formatterInt.getCountryCallingCode()).to.be.undefined;
    formatterInt.input('+');
    expect(formatterInt.getCountryCallingCode()).to.be.undefined;
    formatterInt.input('7');
    expect(formatterInt.getCountryCallingCode()).to.equal('7');
    formatterInt.input('8005553535');
    expect(formatterInt.getCountryCallingCode()).to.equal('7');
  });
  it('should return the country of the number', function () {
    // National. Russia.
    var formatter = new AsYouType('RU');
    expect(formatter.getCountry()).to.be.undefined;
    formatter.input('8');
    expect(formatter.getCountry()).to.equal('RU');
    formatter.input('8005553535');
    expect(formatter.getCountry()).to.equal('RU'); // International. Austria.

    var formatterInt = new AsYouType();
    expect(formatterInt.getCountry()).to.be.undefined;
    formatterInt.input('+');
    expect(formatterInt.getCountry()).to.be.undefined;
    formatterInt.input('43');
    expect(formatterInt.getCountry()).to.equal('AT'); // International. USA.

    var formatterIntRu = new AsYouType();
    expect(formatterIntRu.getCountry()).to.be.undefined;
    formatterIntRu.input('+');
    expect(formatterIntRu.getCountry()).to.be.undefined;
    formatterIntRu.input('1');
    expect(formatterIntRu.getCountry()).to.be.undefined;
    formatterIntRu.input('2133734253');
    expect(formatterIntRu.getCountry()).to.equal('US');
    formatterIntRu.input('1');
    expect(formatterIntRu.getCountry()).to.be.undefined;
  });
  it('should parse a long IDD prefix', function () {
    var formatter = new AsYouType('AU'); // `14880011` is a long IDD prefix in Australia.

    formatter.input('1').should.equal('1');
    formatter.input('4').should.equal('14');
    formatter.input('8').should.equal('148');
    formatter.input('8').should.equal('1488');
    formatter.input('0').should.equal('14880');
    formatter.input('0').should.equal('148800');
    formatter.input('1').should.equal('1488001');
    formatter.input('1').should.equal('14880011'); // As if were calling US using `14880011` IDD prefix,
    // though that prefix could mean something else.

    formatter.input('1').should.equal('14880011 1');
    formatter.input('2').should.equal('14880011 1 2');
    formatter.input('1').should.equal('14880011 1 21');
    formatter.input('3').should.equal('14880011 1 213');
  });
  it('should return the phone number characters entered by the user', function () {
    var formatter = new AsYouType('RU');
    formatter.getChars().should.equal('');
    formatter.input('+123');
    formatter.getChars().should.equal('+123');
    formatter.reset();
    formatter.input('123');
    formatter.getChars().should.equal('123');
  }); // A test confirming the case when input `"11"` for country `"US"`
  // produces `value` `"+11"`.
  // https://gitlab.com/catamphetamine/react-phone-number-input/-/issues/113

  it('should determine the national (significant) part correctly when input with national prefix in US', function () {
    var formatter = new AsYouType('US'); // As soon as the user has input `"11"`, no `format` matches
    // those "national number" digits in the `"US"` country metadata.
    // Since no `format` matches, the number doesn't seem like a valid one,
    // so it attempts to see if the user "forgot" to input a `"+"` at the start.
    // And it looks like they might've to.
    // So it acts as if the leading `"+"` is there,
    // as if the user's input is `"+11"`.
    // See `AsYouType.fixMissingPlus()` function.

    formatter.input('1 122 222 2222 3').should.equal('1 1 222 222 2223');
    formatter.getNumber().nationalNumber.should.equal('2222222223');
  });
});
describe('AsYouType.getNumberValue()', function () {
  it('should return E.164 number value (national number, with national prefix, default country: US)', function () {
    var formatter = new AsYouType('US');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (national number, with national prefix, default calling code: 1)', function () {
    var formatter = new AsYouType({
      defaultCallingCode: '1'
    });
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (national number, default country: US)', function () {
    var formatter = new AsYouType('US');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (national number, default calling code: 1)', function () {
    var formatter = new AsYouType({
      defaultCallingCode: '1'
    });
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (international number, not a valid calling code)', function () {
    var formatter = new AsYouType();
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('2150');
    formatter.getNumberValue().should.equal('+2150');
  });
  it('should return E.164 number value (international number, default country: US)', function () {
    var formatter = new AsYouType('US');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (international number, other default country: RU)', function () {
    var formatter = new AsYouType('RU');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (international number, default calling code: 1)', function () {
    var formatter = new AsYouType('US', {
      defaultCallingCode: '1'
    });
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (international number, other default calling code: 7)', function () {
    var formatter = new AsYouType('US', {
      defaultCallingCode: '7'
    });
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (international number)', function () {
    var formatter = new AsYouType();
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('+');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+1');
    formatter.input('2');
    formatter.getNumberValue().should.equal('+12');
    formatter.input('1');
    formatter.getNumberValue().should.equal('+121');
    formatter.input('3');
    formatter.getNumberValue().should.equal('+1213');
    formatter.input('373-4253');
    formatter.getNumberValue().should.equal('+12133734253');
    formatter.input('4');
    formatter.getNumberValue().should.equal('+121337342534');
  });
  it('should return E.164 number value (national number) (no default country or calling code)', function () {
    var formatter = new AsYouType();
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('1');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('12');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('3');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('373-4253');
    expect(formatter.getNumberValue()).to.be.undefined;
    formatter.input('4');
    expect(formatter.getNumberValue()).to.be.undefined;
  });
  it('should not drop any input digits', function () {
    // Test "+529011234567" number, proactively ensuring that no formatting is applied,
    // where a format is chosen that would otherwise have led to some digits being dropped.
    var formatter = new AsYouType('MX');
    formatter.input('9').should.equal('9');
    formatter.input('0').should.equal('90');
    formatter.input('1').should.equal('901');
    formatter.input('1').should.equal('901 1');
    formatter.input('2').should.equal('901 12');
    formatter.input('3').should.equal('901 123');
    formatter.input('4').should.equal('901 123 4');
    formatter.input('5').should.equal('901 123 45');
    formatter.input('6').should.equal('901 123 456');
    formatter.input('7').should.equal('901 123 4567');
  });
  it('should work for formats with no leading digits (`leadingDigitsPatternsCount === 0`)', function () {
    var formatter = new AsYouType({
      defaultCallingCode: 888
    });
    formatter.input('1').should.equal('1');
  });
  it('should work for SK phone numbers', function () {
    // There was a bug: "leading digits" `"2"` matched "leading digits pattern" `"90"`.
    // The incorrect `.match()` function result was `{ oveflow: true }`
    // while it should've been `undefined`.
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/66
    var formatter = new AsYouType('SK');
    formatter.input('090').should.equal('090');
    formatter.reset();
    formatter.input('080').should.equal('080');
    formatter.reset();
    formatter.input('059').should.equal('059');
  });
  it('should work for SK phone numbers (2)', function () {
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/69
    var formatter = new AsYouType('SK');
    formatter.input('421901222333').should.equal('421 901 222 333');
    formatter.getTemplate().should.equal('xxx xxx xxx xxx');
  });
  it('should choose `defaultCountry` (non-"main" one) when multiple countries match the number', function () {
    // https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/103
    var formatter = new AsYouType('CA');
    formatter.input('8004001000');
    formatter.getNumber().country.should.equal('CA');
    var formatter2 = new AsYouType('US');
    formatter2.input('4389999999');
    formatter2.getNumber().country.should.equal('CA'); // No country matches the national number digits.

    var formatter3 = new AsYouType('US');
    formatter3.input('1111111111');
    formatter3.getNumber().country.should.equal('US');
  });
});

function type(something) {
  return _typeof(something);
}
//# sourceMappingURL=AsYouType.test.js.map