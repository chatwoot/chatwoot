"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
function create(context) {
    return (0, index_1.defineTemplateBodyVisitor)(context, {
        VElement(node) {
            if (node.name !== 'i18n') {
                return;
            }
            const sourceCode = (0, compat_1.getSourceCode)(context);
            const tokenStore = sourceCode.parserServices.getTemplateBodyTokenStore();
            const tagNameToken = tokenStore.getFirstToken(node.startTag);
            context.report({
                node: tagNameToken,
                messageId: 'deprecated',
                *fix(fixer) {
                    yield fixer.replaceText(tagNameToken, '<i18n-t');
                    let hasTag = false;
                    for (const attr of node.startTag.attributes) {
                        if (attr.directive) {
                            if (attr.key.name.name !== 'bind') {
                                continue;
                            }
                            if (!attr.key.argument ||
                                attr.key.argument.type !== 'VIdentifier') {
                                continue;
                            }
                            if (attr.key.argument.name === 'path') {
                                yield fixer.replaceText(attr.key.argument, 'keypath');
                            }
                            else if (attr.key.argument.name === 'tag') {
                                hasTag = true;
                                if (attr.value &&
                                    attr.value.expression &&
                                    attr.value.expression.type === 'Literal' &&
                                    typeof attr.value.expression.value === 'boolean') {
                                    if (attr.value.expression.value) {
                                        yield fixer.replaceText(attr, 'tag="span"');
                                    }
                                    else {
                                        yield fixer.remove(attr);
                                    }
                                }
                            }
                        }
                        else {
                            if (attr.key.name === 'path') {
                                yield fixer.replaceText(attr.key, 'keypath');
                            }
                            else if (attr.key.name === 'tag') {
                                hasTag = true;
                            }
                        }
                    }
                    if (!hasTag) {
                        yield fixer.insertTextAfter((node.startTag.attributes.length > 0 &&
                            node.startTag.attributes[node.startTag.attributes.length - 1]) ||
                            tagNameToken, ' tag="span"');
                    }
                    if (node.endTag) {
                        yield fixer.replaceText(tokenStore.getFirstToken(node.endTag), '</i18n-t');
                    }
                }
            });
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow using deprecated `<i18n>` components (in Vue I18n 9.0.0+)',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-i18n-component.html',
            recommended: true
        },
        fixable: 'code',
        schema: [],
        messages: {
            deprecated: 'Deprecated <i18n> component was found. For VueI18n v9.0, use <i18n-t> component instead.'
        }
    },
    create
});
