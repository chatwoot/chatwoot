"use strict";
/**
 * @fileoverview Story files should have a default export
 * @author Yann Braga
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = __importDefault(require("path"));
const constants_1 = require("../utils/constants");
const ast_1 = require("../utils/ast");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'default-exports',
    defaultOptions: [],
    meta: {
        type: 'problem',
        docs: {
            description: 'Story files should have a default export',
            categories: [constants_1.CategoryId.CSF, constants_1.CategoryId.RECOMMENDED],
            recommended: 'error',
        },
        messages: {
            shouldHaveDefaultExport: 'The file should have a default export.',
            fixSuggestion: 'Add default export',
        },
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
        const getComponentName = (node, filePath) => {
            const name = path_1.default.basename(filePath).split('.')[0];
            const imported = node.body.find((stmt) => {
                if ((0, ast_1.isImportDeclaration)(stmt) &&
                    (0, ast_1.isLiteral)(stmt.source) &&
                    stmt.source.value.startsWith(`./${name}`)) {
                    return !!stmt.specifiers.find((spec) => (0, ast_1.isIdentifier)(spec.local) && spec.local.name === name);
                }
            });
            return imported ? name : null;
        };
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        let hasDefaultExport = false;
        let hasStoriesOfImport = false;
        return {
            ImportSpecifier(node) {
                if (node.imported.name === 'storiesOf') {
                    hasStoriesOfImport = true;
                }
            },
            ExportDefaultSpecifier: function () {
                hasDefaultExport = true;
            },
            ExportDefaultDeclaration: function () {
                hasDefaultExport = true;
            },
            'Program:exit': function (program) {
                if (!hasDefaultExport && !hasStoriesOfImport) {
                    const componentName = getComponentName(program, context.getFilename());
                    const firstNonImportStatement = program.body.find((n) => !(0, ast_1.isImportDeclaration)(n));
                    const node = firstNonImportStatement || program.body[0] || program;
                    const report = {
                        node,
                        messageId: 'shouldHaveDefaultExport',
                    };
                    const fix = (fixer) => {
                        const metaDeclaration = componentName
                            ? `export default { component: ${componentName} }\n`
                            : 'export default {}\n';
                        return fixer.insertTextBefore(node, metaDeclaration);
                    };
                    context.report(Object.assign(Object.assign({}, report), { fix, suggest: [
                            {
                                messageId: 'fixSuggestion',
                                fix,
                            },
                        ] }));
                }
            },
        };
    },
});
