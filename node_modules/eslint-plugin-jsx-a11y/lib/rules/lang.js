"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

var _jsxAstUtils = require("jsx-ast-utils");

var _languageTags = _interopRequireDefault(require("language-tags"));

var _schemas = require("../util/schemas");

/**
 * @fileoverview Enforce lang attribute has a valid value.
 * @author Ethan Cohen
 */
// ----------------------------------------------------------------------------
// Rule Definition
// ----------------------------------------------------------------------------
var errorMessage = 'lang attribute must have a valid value.';
var schema = (0, _schemas.generateObjSchema)();
module.exports = {
  meta: {
    docs: {
      url: 'https://github.com/evcohen/eslint-plugin-jsx-a11y/tree/master/docs/rules/lang.md'
    },
    schema: [schema]
  },
  create: function create(context) {
    return {
      JSXAttribute: function JSXAttribute(node) {
        var name = (0, _jsxAstUtils.propName)(node);

        if (name && name.toUpperCase() !== 'LANG') {
          return;
        }

        var parent = node.parent;
        var type = (0, _jsxAstUtils.elementType)(parent);

        if (type && type !== 'html') {
          return;
        }

        var value = (0, _jsxAstUtils.getLiteralPropValue)(node); // Don't check identifiers

        if (value === null) {
          return;
        }

        if (value === undefined) {
          context.report({
            node,
            message: errorMessage
          });
          return;
        }

        if (_languageTags["default"].check(value)) {
          return;
        }

        context.report({
          node,
          message: errorMessage
        });
      }
    };
  }
};