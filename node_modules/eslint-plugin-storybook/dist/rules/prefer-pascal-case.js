"use strict";
/**
 * @fileoverview Prefer pascal case
 * @author Yann Braga
 */
const experimental_utils_1 = require("@typescript-eslint/experimental-utils");
const csf_1 = require("@storybook/csf");
const utils_1 = require("../utils");
const ast_1 = require("../utils/ast");
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'prefer-pascal-case',
    defaultOptions: [],
    meta: {
        type: 'suggestion',
        fixable: 'code',
        hasSuggestions: true,
        docs: {
            description: 'Stories should use PascalCase',
            categories: [constants_1.CategoryId.RECOMMENDED],
            recommended: 'warn',
        },
        messages: {
            convertToPascalCase: 'Use pascal case',
            usePascalCase: 'The story should use PascalCase notation: {{name}}',
        },
        schema: [],
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        const isPascalCase = (str) => /^[A-Z]+([a-z0-9]?)+/.test(str);
        const toPascalCase = (str) => {
            return str
                .replace(new RegExp(/[-_]+/, 'g'), ' ')
                .replace(new RegExp(/[^\w\s]/, 'g'), '')
                .replace(new RegExp(/\s+(.)(\w+)/, 'g'), (_, $2, $3) => `${$2.toUpperCase() + $3.toLowerCase()}`)
                .replace(new RegExp(/\s/, 'g'), '')
                .replace(new RegExp(/\w/), (s) => s.toUpperCase());
        };
        const checkAndReportError = (id, nonStoryExportsConfig = {}) => {
            const { name } = id;
            if (!(0, csf_1.isExportStory)(name, nonStoryExportsConfig) || name === '__namedExportsOrder') {
                return null;
            }
            if (!name.startsWith('_') && !isPascalCase(name)) {
                context.report({
                    node: id,
                    messageId: 'usePascalCase',
                    data: {
                        name,
                    },
                    suggest: [
                        {
                            messageId: 'convertToPascalCase',
                            *fix(fixer) {
                                var _a;
                                const fullText = context.getSourceCode().text;
                                const fullName = fullText.slice(id.range[0], id.range[1]);
                                const suffix = fullName.substring(name.length);
                                const pascal = toPascalCase(name);
                                yield fixer.replaceTextRange(id.range, pascal + suffix);
                                const scope = context.getScope().childScopes[0];
                                if (scope) {
                                    const variable = experimental_utils_1.ASTUtils.findVariable(scope, name);
                                    const referenceCount = ((_a = variable === null || variable === void 0 ? void 0 : variable.references) === null || _a === void 0 ? void 0 : _a.length) || 0;
                                    for (let i = 0; i < referenceCount; i++) {
                                        const ref = variable.references[i];
                                        if (!ref.init) {
                                            yield fixer.replaceTextRange(ref.identifier.range, pascal);
                                        }
                                    }
                                }
                            },
                        },
                    ],
                });
            }
        };
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        let meta;
        let nonStoryExportsConfig;
        let namedExports = [];
        let hasStoriesOfImport = false;
        return {
            ImportSpecifier(node) {
                if (node.imported.name === 'storiesOf') {
                    hasStoriesOfImport = true;
                }
            },
            ExportDefaultDeclaration: function (node) {
                meta = (0, utils_1.getMetaObjectExpression)(node, context);
                if (meta) {
                    try {
                        nonStoryExportsConfig = {
                            excludeStories: (0, utils_1.getDescriptor)(meta, 'excludeStories'),
                            includeStories: (0, utils_1.getDescriptor)(meta, 'includeStories'),
                        };
                    }
                    catch (err) { }
                }
            },
            ExportNamedDeclaration: function (node) {
                // if there are specifiers, node.declaration should be null
                if (!node.declaration)
                    return;
                const decl = node.declaration;
                if ((0, ast_1.isVariableDeclaration)(decl)) {
                    const { id } = decl.declarations[0];
                    if ((0, ast_1.isIdentifier)(id)) {
                        namedExports.push(id);
                    }
                }
            },
            'Program:exit': function () {
                if (namedExports.length && !hasStoriesOfImport) {
                    namedExports.forEach((n) => checkAndReportError(n, nonStoryExportsConfig));
                }
            },
        };
    },
});
