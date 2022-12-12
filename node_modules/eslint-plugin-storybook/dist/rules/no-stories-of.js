"use strict";
/**
 * @fileoverview storiesOf is deprecated and should not be used
 * @author Yann Braga
 */
const constants_1 = require("../utils/constants");
const create_storybook_rule_1 = require("../utils/create-storybook-rule");
module.exports = (0, create_storybook_rule_1.createStorybookRule)({
    name: 'no-stories-of',
    defaultOptions: [],
    meta: {
        type: 'problem',
        docs: {
            description: 'storiesOf is deprecated and should not be used',
            categories: [constants_1.CategoryId.CSF_STRICT],
            recommended: 'error',
        },
        messages: {
            doNotUseStoriesOf: 'storiesOf is deprecated and should not be used',
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
            ImportSpecifier(node) {
                if (node.imported.name === 'storiesOf') {
                    context.report({
                        node,
                        messageId: 'doNotUseStoriesOf',
                    });
                }
            },
        };
    },
});
