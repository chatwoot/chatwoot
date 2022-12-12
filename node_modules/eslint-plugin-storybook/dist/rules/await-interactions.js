"use strict";
/**
 * @fileoverview Interactions should be awaited
 * @author Yann Braga
 */
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
const constants_1 = require("../utils/constants");
const ast_1 = require("../utils/ast");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'await-interactions',
    defaultOptions: [],
    meta: {
        docs: {
            description: 'Interactions should be awaited',
            categories: [constants_1.CategoryId.ADDON_INTERACTIONS, constants_1.CategoryId.RECOMMENDED],
            recommended: 'error', // or 'warn'
        },
        messages: {
            interactionShouldBeAwaited: 'Interaction should be awaited: {{method}}',
            fixSuggestion: 'Add `await` to method',
        },
        type: 'problem',
        fixable: 'code',
        hasSuggestions: true,
        schema: [],
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        // any helper functions should go here or else delete this section
        const FUNCTIONS_TO_BE_AWAITED = [
            'waitFor',
            'waitForElementToBeRemoved',
            'wait',
            'waitForElement',
            'waitForDomChange',
            'userEvent',
            'play',
        ];
        const getMethodThatShouldBeAwaited = (expr) => {
            const shouldAwait = (name) => {
                return FUNCTIONS_TO_BE_AWAITED.includes(name) || name.startsWith('findBy');
            };
            // When an expression is a return value it doesn't need to be awaited
            if ((0, ast_1.isArrowFunctionExpression)(expr.parent) || (0, ast_1.isReturnStatement)(expr.parent)) {
                return null;
            }
            if ((0, ast_1.isMemberExpression)(expr.callee) &&
                (0, ast_1.isIdentifier)(expr.callee.object) &&
                shouldAwait(expr.callee.object.name)) {
                return expr.callee.object;
            }
            if ((0, ast_1.isTSNonNullExpression)(expr.callee) &&
                (0, ast_1.isMemberExpression)(expr.callee.expression) &&
                (0, ast_1.isIdentifier)(expr.callee.expression.property) &&
                shouldAwait(expr.callee.expression.property.name)) {
                return expr.callee.expression.property;
            }
            if ((0, ast_1.isMemberExpression)(expr.callee) &&
                (0, ast_1.isIdentifier)(expr.callee.property) &&
                shouldAwait(expr.callee.property.name)) {
                return expr.callee.property;
            }
            if ((0, ast_1.isMemberExpression)(expr.callee) &&
                (0, ast_1.isCallExpression)(expr.callee.object) &&
                (0, ast_1.isIdentifier)(expr.callee.object.callee) &&
                (0, ast_1.isIdentifier)(expr.callee.property) &&
                expr.callee.object.callee.name === 'expect') {
                return expr.callee.property;
            }
            if ((0, ast_1.isIdentifier)(expr.callee) && shouldAwait(expr.callee.name)) {
                return expr.callee;
            }
            return null;
        };
        const getClosestFunctionAncestor = (node) => {
            const parent = node.parent;
            if (!parent || (0, ast_1.isProgram)(parent))
                return undefined;
            if ((0, ast_1.isArrowFunctionExpression)(parent) ||
                (0, ast_1.isFunctionExpression)(parent) ||
                (0, ast_1.isFunctionDeclaration)(parent)) {
                return node.parent;
            }
            return getClosestFunctionAncestor(parent);
        };
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        /**
         * @param {import('eslint').Rule.Node} node
         */
        let invocationsThatShouldBeAwaited = [];
        return {
            CallExpression(node) {
                var _a;
                const method = getMethodThatShouldBeAwaited(node);
                if (method && !(0, ast_1.isAwaitExpression)(node.parent) && !(0, ast_1.isAwaitExpression)((_a = node.parent) === null || _a === void 0 ? void 0 : _a.parent)) {
                    invocationsThatShouldBeAwaited.push({ node, method });
                }
            },
            'Program:exit': function () {
                if (invocationsThatShouldBeAwaited.length) {
                    invocationsThatShouldBeAwaited.forEach(({ node, method }) => {
                        const parentFnNode = getClosestFunctionAncestor(node);
                        const parentFnNeedsAsync = parentFnNode && !('async' in parentFnNode && parentFnNode.async);
                        const fixFn = (fixer) => {
                            const fixerResult = [fixer.insertTextBefore(node, 'await ')];
                            if (parentFnNeedsAsync) {
                                fixerResult.push(fixer.insertTextBefore(parentFnNode, 'async '));
                            }
                            return fixerResult;
                        };
                        context.report({
                            node,
                            messageId: 'interactionShouldBeAwaited',
                            data: {
                                method: method.name,
                            },
                            fix: fixFn,
                            suggest: [
                                {
                                    messageId: 'fixSuggestion',
                                    fix: fixFn,
                                },
                            ],
                        });
                    });
                }
            },
        };
    },
});
