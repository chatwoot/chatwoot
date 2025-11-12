"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function create(context) {
    return (0, index_1.compositingVisitors)((0, index_1.defineTemplateBodyVisitor)(context, {
        "VAttribute[directive=true][key.name='t']"(node) {
            checkDirective(context, node);
        },
        "VAttribute[directive=true][key.name.name='t']"(node) {
            checkDirective(context, node);
        },
        ["VElement:matches([name=i18n], [name=i18n-t]) > VStartTag > VAttribute[key.name='path']," +
            "VElement[name=i18n-t] > VStartTag > VAttribute[key.name='keypath']"](node) {
            checkComponent(context, node);
        },
        CallExpression(node) {
            checkCallExpression(context, node);
        }
    }), {
        CallExpression(node) {
            checkCallExpression(context, node);
        }
    });
}
function checkDirective(context, node) {
    const localeMessages = (0, index_1.getLocaleMessages)(context);
    if (localeMessages.isEmpty()) {
        return;
    }
    if (node.value &&
        node.value.type === 'VExpressionContainer' &&
        (0, index_1.isStaticLiteral)(node.value.expression)) {
        const key = (0, index_1.getStaticLiteralValue)(node.value.expression);
        if (!key) {
            return;
        }
        const missingPath = localeMessages.findMissingPath(String(key));
        if (missingPath) {
            context.report({
                node,
                messageId: 'missing',
                data: { path: missingPath }
            });
        }
    }
}
function checkComponent(context, node) {
    const localeMessages = (0, index_1.getLocaleMessages)(context);
    if (localeMessages.isEmpty()) {
        return;
    }
    if (node.value && node.value.type === 'VLiteral') {
        const key = node.value.value;
        if (!key) {
            return;
        }
        const missingPath = localeMessages.findMissingPath(key);
        if (missingPath) {
            context.report({
                node,
                messageId: 'missing',
                data: { path: missingPath }
            });
        }
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
    const localeMessages = (0, index_1.getLocaleMessages)(context);
    if (localeMessages.isEmpty()) {
        return;
    }
    const [keyNode] = node.arguments;
    if (!(0, index_1.isStaticLiteral)(keyNode)) {
        return;
    }
    const key = (0, index_1.getStaticLiteralValue)(keyNode);
    if (!key) {
        return;
    }
    const missingPath = localeMessages.findMissingPath(String(key));
    if (missingPath) {
        context.report({ node, messageId: 'missing', data: { path: missingPath } });
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow missing locale message key at localization methods',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-missing-keys.html',
            recommended: true
        },
        fixable: null,
        schema: [],
        messages: {
            missing: "'{{path}}' does not exist in localization message resources"
        }
    },
    create
});
