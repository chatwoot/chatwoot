"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const is_language_code_1 = require("is-language-code");
const debug_1 = __importDefault(require("debug"));
const rule_1 = require("../utils/rule");
const index_1 = require("../utils/index");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-unknown-locale');
function create(context) {
    var _a, _b;
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const locales = ((_a = context.options[0]) === null || _a === void 0 ? void 0 : _a.locales) || [];
    const disableRFC5646 = ((_b = context.options[0]) === null || _b === void 0 ? void 0 : _b.disableRFC5646) || false;
    function verifyLocaleCode(locale, reportNode) {
        if (locales.includes(locale)) {
            return;
        }
        if (!disableRFC5646 && (0, is_language_code_1.isLangCode)(locale).res) {
            return;
        }
        context.report({
            message: "'{{locale}}' is unknown locale name",
            data: {
                locale
            },
            loc: (reportNode === null || reportNode === void 0 ? void 0 : reportNode.loc) || { line: 1, column: 0 }
        });
    }
    function createVerifyContext(targetLocaleMessage, block) {
        let keyStack;
        if (targetLocaleMessage.isResolvedLocaleByFileName()) {
            const locale = targetLocaleMessage.locales[0];
            keyStack = {
                locale
            };
            verifyLocaleCode(locale, block && (0, index_1.getAttribute)(block, 'locale'));
        }
        else {
            keyStack = {
                locale: null
            };
        }
        return {
            enterKey(key, node) {
                if (keyStack.locale == null) {
                    const locale = String(key);
                    keyStack = {
                        node,
                        locale,
                        upper: keyStack
                    };
                    verifyLocaleCode(locale, node);
                }
                else {
                    keyStack = {
                        node,
                        locale: keyStack.locale,
                        upper: keyStack
                    };
                }
            },
            leaveKey(node) {
                if (keyStack.node === node) {
                    keyStack = keyStack.upper;
                }
            }
        };
    }
    function createVisitorForJson(targetLocaleMessage, block) {
        const ctx = createVerifyContext(targetLocaleMessage, block);
        return {
            JSONProperty(node) {
                const key = node.key.type === 'JSONLiteral' ? `${node.key.value}` : node.key.name;
                ctx.enterKey(key, node.key);
            },
            'JSONProperty:exit'(node) {
                ctx.leaveKey(node.key);
            },
            'JSONArrayExpression > *'(node) {
                const key = node.parent.elements.indexOf(node);
                ctx.enterKey(key, node);
            },
            'JSONArrayExpression > *:exit'(node) {
                ctx.leaveKey(node);
            }
        };
    }
    function createVisitorForYaml(targetLocaleMessage, block) {
        const yamlKeyNodes = new Set();
        function withinKey(node) {
            for (const keyNode of yamlKeyNodes) {
                if (keyNode.range[0] <= node.range[0] &&
                    node.range[0] < keyNode.range[1]) {
                    return true;
                }
            }
            return false;
        }
        const ctx = createVerifyContext(targetLocaleMessage, block);
        return {
            YAMLPair(node) {
                if (node.key != null) {
                    if (withinKey(node)) {
                        return;
                    }
                    yamlKeyNodes.add(node.key);
                }
                if (node.key != null && node.key.type === 'YAMLScalar') {
                    const keyValue = node.key.value;
                    const key = typeof keyValue === 'string' ? keyValue : String(keyValue);
                    ctx.enterKey(key, node.key);
                }
            },
            'YAMLPair:exit'(node) {
                if (node.key != null) {
                    ctx.leaveKey(node.key);
                }
            },
            'YAMLSequence > *'(node) {
                if (withinKey(node)) {
                    return;
                }
                const key = node.parent.entries.indexOf(node);
                ctx.enterKey(key, node);
            },
            'YAMLSequence > *:exit'(node) {
                ctx.leaveKey(node);
            }
        };
    }
    if ((0, path_1.extname)(filename) === '.vue') {
        return (0, index_1.defineCustomBlocksVisitor)(context, ctx => {
            const localeMessages = (0, index_1.getLocaleMessages)(context);
            const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
            if (!targetLocaleMessage) {
                return {};
            }
            return createVisitorForJson(targetLocaleMessage, ctx.parserServices.customBlock);
        }, ctx => {
            const localeMessages = (0, index_1.getLocaleMessages)(context);
            const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
            if (!targetLocaleMessage) {
                return {};
            }
            return createVisitorForYaml(targetLocaleMessage, ctx.parserServices.customBlock);
        });
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in no-unknown-locale`);
            return {};
        }
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(targetLocaleMessage, null);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(targetLocaleMessage, null);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in no-unknown-locale`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'suggestion',
        docs: {
            description: 'disallow unknown locale name',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-unknown-locale.html',
            recommended: false
        },
        fixable: null,
        schema: [
            {
                type: 'object',
                properties: {
                    locales: {
                        type: 'array',
                        items: { type: 'string' }
                    },
                    disableRFC5646: { type: 'boolean' }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
