"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function checkDirective(context, node) {
    if (node.value &&
        node.value.type === 'VExpressionContainer' &&
        node.value.expression &&
        node.value.expression.type === 'CallExpression') {
        const expressionNode = node.value.expression;
        const funcName = (expressionNode.callee.type === 'MemberExpression' &&
            expressionNode.callee.property.type === 'Identifier' &&
            expressionNode.callee.property.name) ||
            (expressionNode.callee.type === 'Identifier' &&
                expressionNode.callee.name) ||
            '';
        if (!/^(\$t|t|\$tc|tc)$/.test(funcName) ||
            !expressionNode.arguments ||
            !expressionNode.arguments.length) {
            return;
        }
        context.report({
            node,
            message: `Using ${funcName} on 'v-html' directive can lead to XSS attack.`
        });
    }
}
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        "VAttribute[directive=true][key.name='html']"(node) {
            checkDirective(context, node);
        },
        "VAttribute[directive=true][key.name.name='html']"(node) {
            checkDirective(context, node);
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow use of localization methods on v-html to prevent XSS attack',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-v-html.html',
            recommended: true
        },
        fixable: null,
        schema: []
    },
    create
});
