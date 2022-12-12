"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.enhanceArgTypes = void 0;

var _store = require("@storybook/store");

var enhanceArgTypes = function enhanceArgTypes(context) {
  var component = context.component,
      userArgTypes = context.argTypes,
      _context$parameters$d = context.parameters.docs,
      docs = _context$parameters$d === void 0 ? {} : _context$parameters$d;
  var extractArgTypes = docs.extractArgTypes;
  var extractedArgTypes = extractArgTypes && component ? extractArgTypes(component) : {};
  var withExtractedTypes = extractedArgTypes ? (0, _store.combineParameters)(extractedArgTypes, userArgTypes) : userArgTypes;
  return withExtractedTypes;
};

exports.enhanceArgTypes = enhanceArgTypes;