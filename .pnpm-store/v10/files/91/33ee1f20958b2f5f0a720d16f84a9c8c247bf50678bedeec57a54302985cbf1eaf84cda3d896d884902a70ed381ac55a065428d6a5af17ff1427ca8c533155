"use strict";
const index_1 = require("../utils/index");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
function create(context) {
    var _a, _b;
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const df = (_b = (_a = sourceCode.parserServices).getDocumentFragment) === null || _b === void 0 ? void 0 : _b.call(_a);
    if (!df) {
        return {};
    }
    return {
        Program() {
            var _a, _b;
            for (const i18n of df.children.filter(index_1.isI18nBlock)) {
                const srcAttrs = (0, index_1.getAttribute)(i18n, 'src');
                if (srcAttrs != null) {
                    continue;
                }
                const langAttrs = (0, index_1.getAttribute)(i18n, 'lang');
                if (langAttrs == null ||
                    langAttrs.value == null ||
                    !langAttrs.value.value) {
                    context.report({
                        loc: ((_b = (_a = langAttrs === null || langAttrs === void 0 ? void 0 : langAttrs.value) !== null && _a !== void 0 ? _a : langAttrs) !== null && _b !== void 0 ? _b : i18n.startTag).loc,
                        messageId: 'required',
                        fix(fixer) {
                            if (langAttrs) {
                                return fixer.replaceTextRange(langAttrs.range, 'lang="json"');
                            }
                            const tokenStore = sourceCode.parserServices.getTemplateBodyTokenStore();
                            const closeToken = tokenStore.getLastToken(i18n.startTag);
                            const beforeToken = tokenStore.getTokenBefore(closeToken);
                            return fixer.insertTextBeforeRange(closeToken.range, `${beforeToken.range[1] < closeToken.range[0] ? '' : ' '}lang="json" `);
                        }
                    });
                }
            }
        }
    };
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'suggestion',
        docs: {
            description: 'require lang attribute on `<i18n>` block',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/prefer-sfc-lang-attr.html',
            recommended: false
        },
        fixable: 'code',
        schema: [],
        messages: {
            required: '`lang` attribute is required.'
        }
    },
    create
});
