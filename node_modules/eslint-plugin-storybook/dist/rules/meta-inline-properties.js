"use strict";
/**
 * @fileoverview Meta should have inline properties
 * @author Yann Braga
 */
const utils_1 = require("../utils");
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'meta-inline-properties',
    defaultOptions: [{ csfVersion: 3 }],
    meta: {
        type: 'problem',
        docs: {
            description: 'Meta should only have inline properties',
            categories: [constants_1.CategoryId.CSF, constants_1.CategoryId.RECOMMENDED],
            excludeFromConfig: true,
            recommended: 'error',
        },
        messages: {
            metaShouldHaveInlineProperties: 'Meta should only have inline properties: {{property}}',
        },
        schema: [
            {
                type: 'object',
                properties: {
                    csfVersion: {
                        type: 'number',
                    },
                },
                additionalProperties: false,
            },
        ],
    },
    create(context) {
        // variables should be defined here
        // In case we need to get options defined in the rule schema
        // const options = context.options[0] || {}
        // const csfVersion = options.csfVersion
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        const isInline = (node) => {
            if (!('value' in node)) {
                return false;
            }
            return (node.value.type === 'ObjectExpression' ||
                node.value.type === 'Literal' ||
                node.value.type === 'ArrayExpression');
        };
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
                const ruleProperties = ['title', 'args'];
                let dynamicProperties = [];
                const metaNodes = meta.properties.filter((prop) => 'key' in prop && 'name' in prop.key && ruleProperties.includes(prop.key.name));
                metaNodes.forEach((metaNode) => {
                    if (!isInline(metaNode)) {
                        dynamicProperties.push(metaNode);
                    }
                });
                if (dynamicProperties.length > 0) {
                    dynamicProperties.forEach((propertyNode) => {
                        var _a;
                        context.report({
                            node: propertyNode,
                            messageId: 'metaShouldHaveInlineProperties',
                            data: {
                                property: (_a = propertyNode.key) === null || _a === void 0 ? void 0 : _a.name,
                            },
                        });
                    });
                }
            },
        };
    },
});
