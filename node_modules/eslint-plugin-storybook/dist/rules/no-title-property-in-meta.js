"use strict";
/**
 * @fileoverview No title property in meta
 * @author Yann Braga
 */
const utils_1 = require("../utils");
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
const ast_1 = require("../utils/ast");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'no-title-property-in-meta',
    defaultOptions: [],
    meta: {
        type: 'problem',
        fixable: 'code',
        hasSuggestions: true,
        docs: {
            description: 'Do not define a title in meta',
            categories: [constants_1.CategoryId.CSF_STRICT],
            recommended: 'error',
        },
        messages: {
            removeTitleInMeta: 'Remove title property from meta',
            noTitleInMeta: `CSF3 does not need a title in meta`,
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
                if (titleNode) {
                    context.report({
                        node: titleNode,
                        messageId: 'noTitleInMeta',
                        suggest: [
                            {
                                messageId: 'removeTitleInMeta',
                                fix(fixer) {
                                    const fullText = context.getSourceCode().text;
                                    const propertyTextWithExtraCharacter = fullText.slice(titleNode.range[0], titleNode.range[1] + 1);
                                    const hasComma = propertyTextWithExtraCharacter.slice(-1) === ',';
                                    const propertyRange = [
                                        titleNode.range[0],
                                        hasComma ? titleNode.range[1] + 1 : titleNode.range[1],
                                    ];
                                    return fixer.removeRange(propertyRange);
                                },
                            },
                        ],
                    });
                }
            },
        };
    },
});
