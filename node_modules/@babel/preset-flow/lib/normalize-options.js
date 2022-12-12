"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = normalizeOptions;

var _helperValidatorOption = require("@babel/helper-validator-option");

const v = new _helperValidatorOption.OptionValidator("@babel/preset-flow");

function normalizeOptions(options = {}) {
  let {
    all
  } = options;
  const {
    allowDeclareFields
  } = options;
  {
    return {
      all,
      allowDeclareFields
    };
  }
}