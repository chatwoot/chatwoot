"use strict";
/**
 * @fileoverview Component property should be set
 * @author Yann Braga
 */
const utils_1 = require("../utils");
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
const ast_1 = require("../utils/ast");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'csf-component',
    defaultOptions: [],
    meta: {
        type: 'suggestion',
        docs: {
            description: 'The component property should be set',
            categories: [constants_1.CategoryId.CSF],
            recommended: 'warn',
        },
        messages: {
            missingComponentProperty: 'Missing component property.',
        },
        schema: [],
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        // any helper functions should go here or else delete this section
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        return {
            ExportDefaultDeclaration(node) {
                const meta = (0, utils_1.getMetaObjectExpression)(node, context);
                if (!meta) {
                    return null;
                }
                const componentProperty = meta.properties.find((property) => !(0, ast_1.isSpreadElement)(property) &&
                    'name' in property.key &&
                    property.key.name === 'component');
                if (!componentProperty) {
                    context.report({
                        node,
                        messageId: 'missingComponentProperty',
                    });
                }
            },
        };
    },
});
