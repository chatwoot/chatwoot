"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createDefaultValue = createDefaultValue;

var _utils = require("../../utils");

var _defaultValue = require("../utils/defaultValue");

function createDefaultValue(_ref) {
  var defaultValue = _ref.defaultValue;

  if (defaultValue != null) {
    var value = defaultValue.value;

    if (!(0, _defaultValue.isDefaultValueBlacklisted)(value)) {
      return (0, _utils.createSummaryValue)(value);
    }
  }

  return null;
}