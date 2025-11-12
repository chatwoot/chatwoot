"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function checkDirective(context, node) {
    context.report({
        node,
        message: `'v-t' custom directive is used, but it is deprecated. Use 't' or '$t' instead.`
    });
}
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        "VAttribute[directive=true][key.name='t']"(node) {
            checkDirective(context, node);
        },
        "VAttribute[directive=true][key.name.name='t']"(node) {
            checkDirective(context, node);
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using deprecated `v-t` custom directive (Deprecated in Vue I18n 11.0.0, removed fully in Vue I18n 12.0.0)',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-v-t.html',
            recommended: false
        },
        fixable: null,
        schema: []
    },
    create
});
