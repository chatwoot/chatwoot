"use strict";
/**
 * @fileoverview Deprecated hierarchy separator
 * @author Yann Braga
 */
const utils_1 = require("../utils");
const ast_1 = require("../utils/ast");
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'hierarchy-separator',
    defaultOptions: [],
    meta: {
        type: 'problem',
        fixable: 'code',
        hasSuggestions: true,
        docs: {
            description: 'Deprecated hierarchy separator in title property',
            categories: [constants_1.CategoryId.CSF, constants_1.CategoryId.RECOMMENDED],
            recommended: 'warn',
        },
        messages: {
            useCorrectSeparators: 'Use correct separators',
            deprecatedHierarchySeparator: 'Deprecated hierarchy separator in title property: {{metaTitle}}.',
        },
        schema: [],
    },
    create: function (context) {
        return {
            ExportDefaultDeclaration: function (node) {
                const meta = (0, utils_1.getMetaObjectExpression)(node, context);
                if (!meta) {
                    return null;
                }
                const titleNode = meta.properties.find((prop) => { var _a; return !(0, ast_1.isSpreadElement)(prop) && 'name' in prop.key && ((_a = prop.key) === null || _a === void 0 ? void 0 : _a.name) === 'title'; });
                if (!titleNode || !(0, ast_1.isLiteral)(titleNode.value)) {
                    return;
                }
                const metaTitle = titleNode.value.raw || '';
                if (metaTitle.includes('|')) {
                    context.report({
                        node: titleNode,
                        messageId: 'deprecatedHierarchySeparator',
                        data: { metaTitle },
                        // In case we want this to be auto fixed by --fix
                        fix: function (fixer) {
                            return fixer.replaceTextRange(titleNode.value.range, metaTitle.replace(/\|/g, '/'));
                        },
                        suggest: [
                            {
                                messageId: 'useCorrectSeparators',
                                fix: function (fixer) {
                                    return fixer.replaceTextRange(titleNode.value.range, metaTitle.replace(/\|/g, '/'));
                                },
                            },
                        ],
                    });
                }
            },
        };
    },
});
