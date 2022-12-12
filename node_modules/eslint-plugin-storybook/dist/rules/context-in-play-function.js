"use strict";
/**
 * @fileoverview Pass a context object when invoking a play function
 * @author Yann Braga
 */
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
const constants_1 = require("../utils/constants");
const ast_1 = require("../utils/ast");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'context-in-play-function',
    defaultOptions: [],
    meta: {
        type: 'problem',
        docs: {
            description: 'Pass a context when invoking play function of another story',
            categories: [constants_1.CategoryId.RECOMMENDED, constants_1.CategoryId.ADDON_INTERACTIONS],
            recommended: 'error',
        },
        messages: {
            passContextToPlayFunction: 'Pass a context when invoking play function of another story',
        },
        fixable: undefined,
        schema: [],
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        // any helper functions should go here or else delete this section
        const isPlayFunctionFromAnotherStory = (expr) => {
            if ((0, ast_1.isTSNonNullExpression)(expr.callee) &&
                (0, ast_1.isMemberExpression)(expr.callee.expression) &&
                (0, ast_1.isIdentifier)(expr.callee.expression.property) &&
                expr.callee.expression.property.name === 'play') {
                return true;
            }
            if ((0, ast_1.isMemberExpression)(expr.callee) &&
                (0, ast_1.isIdentifier)(expr.callee.property) &&
                expr.callee.property.name === 'play') {
                return true;
            }
            return false;
        };
        // Expression passing an argument called context OR spreading a variable called context
        const isNotPassingContextCorrectly = (expr) => {
            const firstExpressionArgument = expr.arguments[0];
            if (!firstExpressionArgument) {
                return true;
            }
            if (expr.arguments.length === 1 &&
                (0, ast_1.isIdentifier)(firstExpressionArgument) &&
                firstExpressionArgument.name === 'context') {
                return false;
            }
            if ((0, ast_1.isObjectExpression)(firstExpressionArgument) &&
                firstExpressionArgument.properties.some((prop) => {
                    return ((0, ast_1.isSpreadElement)(prop) && (0, ast_1.isIdentifier)(prop.argument) && prop.argument.name === 'context');
                })) {
                return false;
            }
            return true;
        };
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        let invocationsWithoutProperContext = [];
        return {
            CallExpression(node) {
                if (isPlayFunctionFromAnotherStory(node) && isNotPassingContextCorrectly(node)) {
                    invocationsWithoutProperContext.push(node);
                }
            },
            'Program:exit': function () {
                invocationsWithoutProperContext.forEach((node) => {
                    context.report({
                        node,
                        messageId: 'passContextToPlayFunction',
                    });
                });
            },
        };
    },
});
