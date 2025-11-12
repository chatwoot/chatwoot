"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        VElement(node) {
            if (node.name !== 'i18n-t') {
                return;
            }
            const pathProp = (0, index_1.getAttribute)(node, 'path') || (0, index_1.getDirective)(node, 'bind', 'path');
            if (pathProp) {
                context.report({
                    node: pathProp.key,
                    messageId: 'disallow',
                    fix(fixer) {
                        if (pathProp.directive) {
                            return fixer.replaceText(pathProp.key.argument, 'keypath');
                        }
                        else {
                            return fixer.replaceText(pathProp.key, 'keypath');
                        }
                    }
                });
            }
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using `path` prop with `<i18n-t>`',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-i18n-t-path-prop.html',
            recommended: true
        },
        fixable: 'code',
        schema: [],
        messages: {
            disallow: 'Cannot use `path` prop with `<i18n-t>` component. Use `keypath` prop instead.'
        }
    },
    create
});
