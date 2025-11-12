"use strict";
const compat_1 = require("../utils/compat");
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'suggestion',
        docs: {
            description: 'require or disallow the locale attribute on `<i18n>` block',
            category: 'Stylistic Issues',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/sfc-locale-attr.html',
            recommended: false
        },
        fixable: null,
        schema: [
            {
                enum: ['always', 'never']
            }
        ],
        messages: {
            required: '`locale` attribute is required.',
            disallowed: '`locale` attribute is disallowed.'
        }
    },
    create(context) {
        var _a, _b;
        const sourceCode = (0, compat_1.getSourceCode)(context);
        const df = (_b = (_a = sourceCode.parserServices).getDocumentFragment) === null || _b === void 0 ? void 0 : _b.call(_a);
        if (!df) {
            return {};
        }
        const always = context.options[0] !== 'never';
        return {
            Program() {
                for (const i18n of df.children.filter(index_1.isI18nBlock)) {
                    const srcAttrs = (0, index_1.getAttribute)(i18n, 'src');
                    if (srcAttrs != null) {
                        continue;
                    }
                    const localeAttrs = (0, index_1.getAttribute)(i18n, 'locale');
                    if (localeAttrs != null &&
                        localeAttrs.value != null &&
                        localeAttrs.value.value) {
                        if (always) {
                            continue;
                        }
                        context.report({
                            loc: localeAttrs.loc,
                            messageId: 'disallowed'
                        });
                    }
                    else {
                        if (!always) {
                            continue;
                        }
                        context.report({
                            loc: i18n.startTag.loc,
                            messageId: 'required'
                        });
                    }
                }
            }
        };
    }
});
