"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

var _toConsumableArray2 = _interopRequireDefault(require("@babel/runtime/helpers/toConsumableArray"));

var _axeCore = require("axe-core");

var _jsxAstUtils = require("jsx-ast-utils");

var _schemas = require("../util/schemas");

/**
 * @fileoverview Ensure autocomplete attribute is correct.
 * @author Wilco Fiers
 */
// ----------------------------------------------------------------------------
// Rule Definition
// ----------------------------------------------------------------------------
var schema = (0, _schemas.generateObjSchema)({
  inputComponents: _schemas.arraySchema
});
module.exports = {
  meta: {
    docs: {
      url: 'https://github.com/evcohen/eslint-plugin-jsx-a11y/tree/master/docs/rules/autocomplete-valid.md'
    },
    schema: [schema]
  },
  create: function create(context) {
    return {
      JSXOpeningElement: function JSXOpeningElement(node) {
        var options = context.options[0] || {};
        var _options$inputCompone = options.inputComponents,
            inputComponents = _options$inputCompone === void 0 ? [] : _options$inputCompone;
        var inputTypes = ['input'].concat((0, _toConsumableArray2["default"])(inputComponents));
        var elType = (0, _jsxAstUtils.elementType)(node);
        var autocomplete = (0, _jsxAstUtils.getLiteralPropValue)((0, _jsxAstUtils.getProp)(node.attributes, 'autocomplete'));

        if (typeof autocomplete !== 'string' || !inputTypes.includes(elType)) {
          return;
        }

        var type = (0, _jsxAstUtils.getLiteralPropValue)((0, _jsxAstUtils.getProp)(node.attributes, 'type'));

        var _runVirtualRule = (0, _axeCore.runVirtualRule)('autocomplete-valid', {
          nodeName: 'input',
          attributes: {
            autocomplete,
            // Which autocomplete is valid depends on the input type
            type: type === null ? undefined : type
          }
        }),
            violations = _runVirtualRule.violations;

        if (violations.length === 0) {
          return;
        } // Since we only test one rule, with one node, return the message from first (and only) instance of each


        context.report({
          node,
          message: violations[0].nodes[0].all[0].message
        });
      }
    };
  }
};