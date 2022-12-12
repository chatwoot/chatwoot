"use strict";
/**
 * @fileoverview A story file must contain at least one story export
 * @author Yann Braga
 */
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
const constants_1 = require("../utils/constants");
const utils_1 = require("../utils");
const ast_1 = require("../utils/ast");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'story-exports',
    defaultOptions: [],
    meta: {
        type: 'problem',
        docs: {
            description: 'A story file must contain at least one story export',
            categories: [constants_1.CategoryId.RECOMMENDED, constants_1.CategoryId.CSF],
            recommended: 'error',
        },
        messages: {
            shouldHaveStoryExport: 'The file should have at least one story export',
            addStoryExport: 'Add a story export',
        },
        fixable: undefined,
        schema: [],
    },
    create(context) {
        // variables should be defined here
        //----------------------------------------------------------------------
        // Helpers
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        // Public
        //----------------------------------------------------------------------
        let hasStoriesOfImport = false;
        let nonStoryExportsConfig = {};
        let meta;
        let namedExports = [];
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
                namedExports.push(...(0, utils_1.getAllNamedExports)(node));
            },
            'Program:exit': function (program) {
                if (hasStoriesOfImport || !meta) {
                    return;
                }
                const storyExports = namedExports.filter((exp) => (0, utils_1.isValidStoryExport)(exp, nonStoryExportsConfig));
                if (storyExports.length) {
                    return;
                }
                const firstNonImportStatement = program.body.find((n) => !(0, ast_1.isImportDeclaration)(n));
                const node = firstNonImportStatement || program.body[0] || program;
                // @TODO: bring apply this autofix with CSF3 release
                // const fix = (fixer) => fixer.insertTextAfter(node, `\n\nexport const Default = {}`)
                const report = {
                    node,
                    messageId: 'shouldHaveStoryExport',
                    // fix,
                };
                context.report(report);
            },
        };
    },
});
