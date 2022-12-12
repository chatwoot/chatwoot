'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = extractValueFromTSNonNullExpression;
var extractValueFromThisExpression = require('./ThisExpression').default;

/**
 * Extractor function for a TSNonNullExpression type value node.
 * A TSNonNullExpression is accessing a TypeScript Non-Null Assertion
 * Operator !
 *
 * @param - value - AST Value object with type `TSNonNullExpression`
 * @returns - The extracted value converted to correct type
 *  and maintaing `obj.property` convention.
 */
function extractValueFromTSNonNullExpression(value) {
  // eslint-disable-next-line global-require
  // const getValue = require('.').default;
  var errorMessage = 'The prop value with an expression type of TSNonNullExpression could not be resolved. Please file issue to get this fixed immediately.';

  // it's just the name
  if (value.type === 'Identifier') {
    var name = value.name;

    return name;
  }

  if (value.type === 'ThisExpression') {
    return extractValueFromThisExpression();
  }

  // does not contains properties & is not parenthesized
  if (value.type === 'TSNonNullExpression' && (!value.extra || value.extra.parenthesized === false)) {
    var expression = value.expression;

    return extractValueFromTSNonNullExpression(expression) + '!';
  }

  // does not contains properties & is parenthesized
  if (value.type === 'TSNonNullExpression' && value.extra && value.extra.parenthesized === true) {
    var _expression = value.expression;

    return '(' + extractValueFromTSNonNullExpression(_expression) + '!' + ')';
  }

  // contains a property & is not parenthesized
  if (value.type === 'MemberExpression' && (!value.extra || value.extra.parenthesized === false)) {
    return '' + extractValueFromTSNonNullExpression(value.object) + (value.optional ? '?.' : '.') + extractValueFromTSNonNullExpression(value.property);
  }

  // contains a property & is parenthesized
  if (value.type === 'MemberExpression' && value.extra && value.extra.parenthesized === true) {
    return '(' + extractValueFromTSNonNullExpression(value.object) + (value.optional ? '?.' : '.') + extractValueFromTSNonNullExpression(value.property) + ')';
  }

  // try to fail silently, if specs for TSNonNullExpression change
  // not throw, only log error. Similar to how it was done previously
  if (value.expression) {
    var _expression2 = value.expression;

    while (_expression2) {
      if (_expression2.type === 'Identifier') {
        // eslint-disable-next-line no-console
        console.error(errorMessage);
        return _expression2.name;
      }
      var _expression3 = _expression2;
      _expression2 = _expression3.expression;
    }
  }

  // eslint-disable-next-line no-console
  console.error(errorMessage);
  return '';
}