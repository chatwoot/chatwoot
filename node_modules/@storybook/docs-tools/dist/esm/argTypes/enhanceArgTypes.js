import { combineParameters } from '@storybook/store';
export var enhanceArgTypes = function enhanceArgTypes(context) {
  var component = context.component,
      userArgTypes = context.argTypes,
      _context$parameters$d = context.parameters.docs,
      docs = _context$parameters$d === void 0 ? {} : _context$parameters$d;
  var extractArgTypes = docs.extractArgTypes;
  var extractedArgTypes = extractArgTypes && component ? extractArgTypes(component) : {};
  var withExtractedTypes = extractedArgTypes ? combineParameters(extractedArgTypes, userArgTypes) : userArgTypes;
  return withExtractedTypes;
};