"use strict";
/**
 * @fileoverview Use expect from '@storybook/jest'
 * @author Yann Braga
 */
const constants_1 = require("../utils/constants");
const ast_1 = require("../utils/ast");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'use-storybook-expect',
    defaultOptions: [],
    meta: {
        type: 'suggestion',
        fixable: 'code',
        hasSuggestions: true,
        schema: [],
        docs: {
            description: 'Use expect from `@storybook/jest`',
            categories: [constants_1.CategoryId.ADDON_INTERACTIONS, constants_1.CategoryId.RECOMMENDED],
            recommended: 'error',
        },
        messages: {
            updateImports: 'Update imports',
            useExpectFromStorybook: 'Do not use expect from jest directly in the story. You should use from `@storybook/jest` instead.',
        },
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        const isExpectFromStorybookImported = (node) => {
            return (node.source.value === '@storybook/jest' &&
                node.specifiers.find((spec) => (0, ast_1.isImportSpecifier)(spec) && spec.imported.name === 'expect'));
        };
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        let isImportingFromStorybookExpect = false;
        let expectInvocations = [];
        return {
            ImportDeclaration(node) {
                if (isExpectFromStorybookImported(node)) {
                    isImportingFromStorybookExpect = true;
                }
            },
            CallExpression(node) {
                if (!(0, ast_1.isIdentifier)(node.callee)) {
                    return null;
                }
                if (node.callee.name === 'expect') {
                    expectInvocations.push(node.callee);
                }
            },
            'Program:exit': function () {
                if (!isImportingFromStorybookExpect && expectInvocations.length) {
                    expectInvocations.forEach((node) => {
                        context.report({
                            node,
                            messageId: 'useExpectFromStorybook',
                            fix: function (fixer) {
                                return fixer.insertTextAfterRange([0, 0], "import { expect } from '@storybook/jest';\n");
                            },
                            suggest: [
                                {
                                    messageId: 'updateImports',
                                    fix: function (fixer) {
                                        return fixer.insertTextAfterRange([0, 0], "import { expect } from '@storybook/jest';\n");
                                    },
                                },
                            ],
                        });
                    });
                }
            },
        };
    },
});
