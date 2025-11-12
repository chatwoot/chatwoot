"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        VElement(node) {
            if (node.name !== 'i18n' && node.name !== 'i18n-t') {
                return;
            }
            const placesProp = (0, index_1.getAttribute)(node, 'places') || (0, index_1.getDirective)(node, 'bind', 'places');
            if (placesProp) {
                context.report({
                    node: placesProp.key,
                    messageId: 'deprecated'
                });
            }
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using deprecated `places` prop (Removed in Vue I18n 9.0.0+)',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-i18n-places-prop.html',
            recommended: true
        },
        fixable: null,
        schema: [],
        messages: {
            deprecated: 'Deprecated `places` prop was found. Use v-slot instead.'
        }
    },
    create
});
