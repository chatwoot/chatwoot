"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

// This "state" object simply holds the state of the "AsYouType" parser:
//
// * `country?: string`
// * `callingCode?: string`
// * `digits: string`
// * `international: boolean`
// * `missingPlus: boolean`
// * `IDDPrefix?: string`
// * `carrierCode?: string`
// * `nationalPrefix?: string`
// * `nationalSignificantNumber?: string`
// * `nationalSignificantNumberMatchesInput: boolean`
// * `complexPrefixBeforeNationalSignificantNumber?: string`
//
// `state.country` and `state.callingCode` aren't required to be in sync.
// For example, `state.country` could be `"AR"` and `state.callingCode` could be `undefined`.
// So `state.country` and `state.callingCode` are totally independent.
//
var AsYouTypeState = /*#__PURE__*/function () {
  function AsYouTypeState(_ref) {
    var onCountryChange = _ref.onCountryChange,
        onCallingCodeChange = _ref.onCallingCodeChange;

    _classCallCheck(this, AsYouTypeState);

    this.onCountryChange = onCountryChange;
    this.onCallingCodeChange = onCallingCodeChange;
  }

  _createClass(AsYouTypeState, [{
    key: "reset",
    value: function reset(_ref2) {
      var country = _ref2.country,
          callingCode = _ref2.callingCode;
      this.international = false;
      this.missingPlus = false;
      this.IDDPrefix = undefined;
      this.callingCode = undefined;
      this.digits = '';
      this.resetNationalSignificantNumber();
      this.initCountryAndCallingCode(country, callingCode);
    }
  }, {
    key: "resetNationalSignificantNumber",
    value: function resetNationalSignificantNumber() {
      this.nationalSignificantNumber = this.getNationalDigits();
      this.nationalSignificantNumberMatchesInput = true;
      this.nationalPrefix = undefined;
      this.carrierCode = undefined;
      this.complexPrefixBeforeNationalSignificantNumber = undefined;
    }
  }, {
    key: "update",
    value: function update(properties) {
      for (var _i = 0, _Object$keys = Object.keys(properties); _i < _Object$keys.length; _i++) {
        var key = _Object$keys[_i];
        this[key] = properties[key];
      }
    }
  }, {
    key: "initCountryAndCallingCode",
    value: function initCountryAndCallingCode(country, callingCode) {
      this.setCountry(country);
      this.setCallingCode(callingCode);
    }
  }, {
    key: "setCountry",
    value: function setCountry(country) {
      this.country = country;
      this.onCountryChange(country);
    }
  }, {
    key: "setCallingCode",
    value: function setCallingCode(callingCode) {
      this.callingCode = callingCode;
      this.onCallingCodeChange(callingCode, this.country);
    }
  }, {
    key: "startInternationalNumber",
    value: function startInternationalNumber(country, callingCode) {
      // Prepend the `+` to parsed input.
      this.international = true; // If a default country was set then reset it
      // because an explicitly international phone
      // number is being entered.

      this.initCountryAndCallingCode(country, callingCode);
    }
  }, {
    key: "appendDigits",
    value: function appendDigits(nextDigits) {
      this.digits += nextDigits;
    }
  }, {
    key: "appendNationalSignificantNumberDigits",
    value: function appendNationalSignificantNumberDigits(nextDigits) {
      this.nationalSignificantNumber += nextDigits;
    }
    /**
     * Returns the part of `this.digits` that corresponds to the national number.
     * Basically, all digits that have been input by the user, except for the
     * international prefix and the country calling code part
     * (if the number is an international one).
     * @return {string}
     */

  }, {
    key: "getNationalDigits",
    value: function getNationalDigits() {
      if (this.international) {
        return this.digits.slice((this.IDDPrefix ? this.IDDPrefix.length : 0) + (this.callingCode ? this.callingCode.length : 0));
      }

      return this.digits;
    }
  }, {
    key: "getDigitsWithoutInternationalPrefix",
    value: function getDigitsWithoutInternationalPrefix() {
      if (this.international) {
        if (this.IDDPrefix) {
          return this.digits.slice(this.IDDPrefix.length);
        }
      }

      return this.digits;
    }
  }]);

  return AsYouTypeState;
}();

exports["default"] = AsYouTypeState;
//# sourceMappingURL=AsYouTypeState.js.map