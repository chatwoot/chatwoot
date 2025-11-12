"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function checkCallExpression(context, node) {
    const funcName = (node.callee.type === 'MemberExpression' &&
        node.callee.property.type === 'Identifier' &&
        node.callee.property.name) ||
        (node.callee.type === 'Identifier' && node.callee.name) ||
        '';
    if (/^(\$tc|tc)$/.test(funcName)) {
        context.report({
            node,
            message: `'${funcName}' is used, but it is deprecated. Use 't' or '$t' instead.`
        });
        return;
    }
}
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        CallExpression(node) {
            checkCallExpression(context, node);
        }
    }, {
        CallExpression(node) {
            checkCallExpression(context, node);
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using deprecated `tc` or `$tc` (Deprecated in Vue I18n 10.0.0, removed fully in Vue I18n 11.0.0)',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-tc.html',
            recommended: true
        },
        fixable: null,
        schema: []
    },
    create
});
