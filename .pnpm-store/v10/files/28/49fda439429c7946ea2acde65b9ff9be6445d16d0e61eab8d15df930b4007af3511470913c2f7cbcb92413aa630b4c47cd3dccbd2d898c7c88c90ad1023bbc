"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
function getNodeName(context, node) {
    if (node.type === 'Identifier') {
        return node.name;
    }
    const sourceCode = (0, compat_1.getSourceCode)(context);
    if (sourceCode.ast.range[0] <= node.range[0] &&
        node.range[1] <= sourceCode.ast.range[1]) {
        return sourceCode
            .getTokens(node)
            .map(t => t.value)
            .join('');
    }
    const tokenStore = sourceCode.parserServices.getTemplateBodyTokenStore();
    return tokenStore
        .getTokens(node)
        .map(t => t.value)
        .join('');
}
function checkDirective(context, node) {
    if (node.value &&
        node.value.type === 'VExpressionContainer' &&
        node.value.expression &&
        !(0, index_1.isStaticLiteral)(node.value.expression)) {
        const name = getNodeName(context, node.value.expression);
        context.report({
            node,
            message: `'${name}' dynamic key is used'`
        });
    }
}
function checkComponent(context, node) {
    if (node.name.type === 'VIdentifier' &&
        node.name.name === 'bind' &&
        node.argument &&
        node.argument.type === 'VIdentifier' &&
        node.argument.name === 'path' &&
        node.parent.value &&
        node.parent.value.type === 'VExpressionContainer' &&
        node.parent.value.expression &&
        !(0, index_1.isStaticLiteral)(node.parent.value.expression)) {
        const name = getNodeName(context, node.parent.value.expression);
        context.report({
            node,
            message: `'${name}' dynamic key is used'`
        });
    }
}
function checkCallExpression(context, node) {
    const funcName = (node.callee.type === 'MemberExpression' &&
        node.callee.property.type === 'Identifier' &&
        node.callee.property.name) ||
        (node.callee.type === 'Identifier' && node.callee.name) ||
        '';
    if (!/^(\$t|t|\$tc|tc)$/.test(funcName) ||
        !node.arguments ||
        !node.arguments.length) {
        return;
    }
    const [keyNode] = node.arguments;
    if (!(0, index_1.isStaticLiteral)(keyNode)) {
        const name = getNodeName(context, keyNode);
        context.report({
            node,
            message: `'${name}' dynamic key is used'`
        });
    }
}
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        "VAttribute[directive=true][key.name='t']"(node) {
            checkDirective(context, node);
        },
        "VAttribute[directive=true][key.name.name='t']"(node) {
            checkDirective(context, node);
        },
        'VElement:matches([name=i18n], [name=i18n-t]) > VStartTag > VAttribute[directive=true] > VDirectiveKey'(node) {
            checkComponent(context, node);
        },
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
        type: 'suggestion',
        docs: {
            description: 'disallow localization dynamic keys at localization methods',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-dynamic-keys.html',
            recommended: false
        },
        fixable: null,
        schema: []
    },
    create
});
