"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const key_path_1 = require("../utils/key-path");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-missing-keys-in-other-locales');
function create(context) {
    var _a;
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const ignoreLocales = ((_a = context.options[0]) === null || _a === void 0 ? void 0 : _a.ignoreLocales) || [];
    function reportMissing(keyPath, locales, reportNode) {
        const quotedLocales = locales.map(s => `'${s}'`);
        context.report({
            message: "'{{path}}' does not exist in {{locales}} locale(s)",
            data: {
                path: (0, key_path_1.joinPath)(...keyPath),
                locales: [quotedLocales.pop(), quotedLocales.join(', ')]
                    .filter(loc => loc)
                    .reverse()
                    .join(' and ')
            },
            loc: reportNode.loc
        });
    }
    function isLeafMessageNode(node) {
        if (node == null) {
            return false;
        }
        if (node.type === 'JSONLiteral') {
            if (node.value == null && node.regex == null && node.bigint == null) {
                return false;
            }
            return true;
        }
        if (node.type === 'JSONIdentifier' || node.type === 'JSONTemplateLiteral') {
            return true;
        }
        if (node.type === 'JSONUnaryExpression') {
            return isLeafMessageNode(node.argument);
        }
        if (node.type === 'YAMLScalar') {
            if (node.value == null) {
                return false;
            }
            return true;
        }
        if (node.type === 'YAMLWithMeta') {
            return isLeafMessageNode(node.value);
        }
        if (node.type === 'YAMLAlias') {
            return true;
        }
        return false;
    }
    function createVerifyContext(targetLocaleMessage, localeMessages) {
        function getOtherLocaleMessages(locale) {
            const ignores = new Set([...ignoreLocales, locale]);
            return localeMessages.locales
                .filter(locale => !ignores.has(locale))
                .map(locale => {
                return {
                    locale,
                    dictList: localeMessages.localeMessages.map(lm => lm.getMessagesFromLocale(locale))
                };
            });
        }
        let keyStack;
        if (targetLocaleMessage.isResolvedLocaleByFileName()) {
            const locale = targetLocaleMessage.locales[0];
            keyStack = {
                locale,
                otherLocaleMessages: getOtherLocaleMessages(locale),
                keyPath: []
            };
        }
        else {
            keyStack = {
                locale: null,
                otherLocaleMessages: null
            };
        }
        return {
            enterKey(key, node, needsVerify) {
                if (keyStack.locale == null) {
                    const locale = key;
                    keyStack = {
                        node,
                        locale,
                        otherLocaleMessages: getOtherLocaleMessages(locale),
                        keyPath: [],
                        upper: keyStack
                    };
                }
                else {
                    const keyPath = [...keyStack.keyPath, key];
                    const nextOtherLocaleMessages = [];
                    const missingLocales = [];
                    for (const { locale, dictList } of keyStack.otherLocaleMessages) {
                        const nextDictList = [];
                        let exists = false;
                        for (const dict of dictList) {
                            const nextDict = dict[key];
                            if (nextDict != null) {
                                exists = true;
                                if (typeof nextDict === 'object') {
                                    nextDictList.push(nextDict);
                                }
                            }
                        }
                        if (!exists && needsVerify) {
                            missingLocales.push(locale);
                        }
                        nextOtherLocaleMessages.push({ locale, dictList: nextDictList });
                    }
                    if (missingLocales.length) {
                        reportMissing(keyPath, missingLocales, node);
                    }
                    keyStack = {
                        node,
                        locale: keyStack.locale,
                        otherLocaleMessages: nextOtherLocaleMessages,
                        keyPath,
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
    function createVisitorForJson(targetLocaleMessage, localeMessages) {
        const ctx = createVerifyContext(targetLocaleMessage, localeMessages);
        return {
            JSONProperty(node) {
                const key = node.key.type === 'JSONLiteral' ? `${node.key.value}` : node.key.name;
                ctx.enterKey(key, node.key, isLeafMessageNode(node.value));
            },
            'JSONProperty:exit'(node) {
                ctx.leaveKey(node.key);
            },
            'JSONArrayExpression > *'(node) {
                const key = node.parent.elements.indexOf(node);
                ctx.enterKey(key, node, isLeafMessageNode(node));
            },
            'JSONArrayExpression > *:exit'(node) {
                ctx.leaveKey(node);
            }
        };
    }
    function createVisitorForYaml(targetLocaleMessage, localeMessages) {
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
        const ctx = createVerifyContext(targetLocaleMessage, localeMessages);
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
                    ctx.enterKey(key, node.key, isLeafMessageNode(node.value));
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
                ctx.enterKey(key, node, isLeafMessageNode(node));
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
            return createVisitorForJson(targetLocaleMessage, localeMessages);
        }, ctx => {
            const localeMessages = (0, index_1.getLocaleMessages)(context);
            const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
            if (!targetLocaleMessage) {
                return {};
            }
            return createVisitorForYaml(targetLocaleMessage, localeMessages);
        });
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in no-missing-keys-in-other-locales`);
            return {};
        }
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(targetLocaleMessage, localeMessages);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(targetLocaleMessage, localeMessages);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in no-missing-keys-in-other-locales`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'layout',
        docs: {
            description: 'disallow missing locale message keys in other locales',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-missing-keys-in-other-locales.html',
            recommended: false
        },
        fixable: null,
        schema: [
            {
                type: 'object',
                properties: {
                    ignoreLocales: {
                        type: 'array',
                        items: { type: 'string' }
                    }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
