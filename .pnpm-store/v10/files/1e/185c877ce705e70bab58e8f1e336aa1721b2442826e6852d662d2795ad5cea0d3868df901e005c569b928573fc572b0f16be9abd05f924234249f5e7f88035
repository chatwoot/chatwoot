"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        VElement(node) {
            if (node.name !== 'i18n' && node.name !== 'i18n-t') {
                return;
            }
            for (const child of node.children) {
                if (child.type !== 'VElement') {
                    continue;
                }
                const placeAttr = (0, index_1.getAttribute)(child, 'place') || (0, index_1.getDirective)(child, 'bind', 'place');
                if (placeAttr) {
                    context.report({
                        node: placeAttr.key,
                        messageId: 'deprecated'
                    });
                }
            }
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using deprecated `place` attribute (Removed in Vue I18n 9.0.0+)',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-i18n-place-attr.html',
            recommended: true
        },
        fixable: null,
        schema: [],
        messages: {
            deprecated: 'Deprecated `place` attribute was found. Use v-slot instead.'
        }
    },
    create
});
