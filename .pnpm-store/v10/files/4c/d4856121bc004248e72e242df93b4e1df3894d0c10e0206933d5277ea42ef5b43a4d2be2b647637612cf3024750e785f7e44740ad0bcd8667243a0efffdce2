"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const key_path_1 = require("../utils/key-path");
const get_cwd_1 = require("../utils/get-cwd");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-duplicate-keys-in-locale');
function getMessageFilepath(fullPath, context) {
    const cwd = (0, get_cwd_1.getCwd)(context);
    if (fullPath.startsWith(cwd)) {
        return fullPath.replace(`${cwd}/`, './');
    }
    return fullPath;
}
function create(context) {
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const options = (context.options && context.options[0]) || {};
    const ignoreI18nBlock = Boolean(options.ignoreI18nBlock);
    function createInitPathStack(targetLocaleMessage, otherLocaleMessages) {
        if (targetLocaleMessage.isResolvedLocaleByFileName()) {
            const locale = targetLocaleMessage.locales[0];
            return createInitLocalePathStack(locale, otherLocaleMessages);
        }
        else {
            return {
                keyPath: [],
                locale: null,
                otherDictionaries: []
            };
        }
    }
    function createInitLocalePathStack(locale, otherLocaleMessages) {
        return {
            keyPath: [],
            locale,
            otherDictionaries: otherLocaleMessages.map(lm => {
                return {
                    dict: lm.getMessagesFromLocale(locale),
                    source: lm
                };
            })
        };
    }
    function createVerifyContext(targetLocaleMessage, otherLocaleMessages) {
        let pathStack = createInitPathStack(targetLocaleMessage, otherLocaleMessages);
        const existsKeyNodes = {};
        const existsLocaleNodes = {};
        function pushKey(exists, key, reportNode) {
            const keyNodes = exists[key] || (exists[key] = []);
            keyNodes.push(reportNode);
        }
        return {
            enterKey(key, reportNode) {
                if (pathStack.locale == null) {
                    const locale = key;
                    pushKey(existsLocaleNodes, locale, reportNode);
                    pathStack = Object.assign({ upper: pathStack, node: reportNode }, createInitLocalePathStack(locale, otherLocaleMessages));
                    return;
                }
                const keyOtherValues = pathStack.otherDictionaries.map(dict => {
                    return {
                        value: dict.dict[key],
                        source: dict.source
                    };
                });
                const keyPath = [...pathStack.keyPath, key];
                const keyPathStr = (0, key_path_1.joinPath)(...keyPath);
                const nextOtherDictionaries = [];
                const reportFiles = [];
                for (const value of keyOtherValues) {
                    if (value.value == null) {
                        continue;
                    }
                    if (typeof value.value !== 'object') {
                        reportFiles.push(`"${getMessageFilepath(value.source.fullpath, context)}"`);
                    }
                    else {
                        nextOtherDictionaries.push({
                            dict: value.value,
                            source: value.source
                        });
                    }
                }
                if (reportFiles.length) {
                    reportFiles.sort();
                    const last = reportFiles.pop();
                    context.report({
                        message: `duplicate key '${keyPathStr}' in '${pathStack.locale}'. ${reportFiles.length === 0
                            ? last
                            : `${reportFiles.join(', ')}, and ${last}`} has the same key`,
                        loc: reportNode.loc
                    });
                }
                pushKey(existsKeyNodes[pathStack.locale] ||
                    (existsKeyNodes[pathStack.locale] = {}), keyPathStr, reportNode);
                pathStack = {
                    upper: pathStack,
                    node: reportNode,
                    keyPath,
                    locale: pathStack.locale,
                    otherDictionaries: nextOtherDictionaries
                };
            },
            leaveKey(node) {
                if (pathStack.node === node) {
                    pathStack = pathStack.upper;
                }
            },
            reports() {
                for (const localeNodes of [
                    existsLocaleNodes,
                    ...Object.values(existsKeyNodes)
                ]) {
                    for (const key of Object.keys(localeNodes)) {
                        const keyNodes = localeNodes[key];
                        if (keyNodes.length > 1) {
                            for (const keyNode of keyNodes) {
                                context.report({
                                    message: `duplicate key '${key}'`,
                                    loc: keyNode.loc
                                });
                            }
                        }
                    }
                }
            }
        };
    }
    function createVisitorForJson(_sourceCode, targetLocaleMessage, otherLocaleMessages) {
        const verifyContext = createVerifyContext(targetLocaleMessage, otherLocaleMessages);
        return {
            JSONProperty(node) {
                const key = node.key.type === 'JSONLiteral' ? `${node.key.value}` : node.key.name;
                verifyContext.enterKey(key, node.key);
            },
            'JSONProperty:exit'(node) {
                verifyContext.leaveKey(node.key);
            },
            'JSONArrayExpression > *'(node) {
                const key = node.parent.elements.indexOf(node);
                verifyContext.enterKey(key, node);
            },
            'JSONArrayExpression > *:exit'(node) {
                verifyContext.leaveKey(node);
            },
            'Program:exit'() {
                verifyContext.reports();
            }
        };
    }
    function createVisitorForYaml(sourceCode, targetLocaleMessage, otherLocaleMessages) {
        const verifyContext = createVerifyContext(targetLocaleMessage, otherLocaleMessages);
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
        return {
            YAMLPair(node) {
                if (node.key != null) {
                    if (withinKey(node)) {
                        return;
                    }
                    yamlKeyNodes.add(node.key);
                }
                else {
                    return;
                }
                const keyValue = node.key.type !== 'YAMLScalar'
                    ? sourceCode.getText(node.key)
                    : node.key.value;
                const key = typeof keyValue === 'boolean' || keyValue === null
                    ? String(keyValue)
                    : keyValue;
                verifyContext.enterKey(key, node.key);
            },
            'YAMLPair:exit'(node) {
                verifyContext.leaveKey(node.key);
            },
            'YAMLSequence > *'(node) {
                const key = node.parent.entries.indexOf(node);
                verifyContext.enterKey(key, node);
            },
            'YAMLSequence > *:exit'(node) {
                verifyContext.leaveKey(node);
            },
            'Program:exit'() {
                verifyContext.reports();
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
            const otherLocaleMessages = ignoreI18nBlock
                ? []
                : localeMessages.localeMessages.filter(lm => lm !== targetLocaleMessage);
            return createVisitorForJson((0, compat_1.getSourceCode)(ctx), targetLocaleMessage, otherLocaleMessages);
        }, ctx => {
            const localeMessages = (0, index_1.getLocaleMessages)(context);
            const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
            if (!targetLocaleMessage) {
                return {};
            }
            const otherLocaleMessages = ignoreI18nBlock
                ? []
                : localeMessages.localeMessages.filter(lm => lm !== targetLocaleMessage);
            return createVisitorForYaml((0, compat_1.getSourceCode)(ctx), targetLocaleMessage, otherLocaleMessages);
        });
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in no-duplicate-keys-in-locale`);
            return {};
        }
        const otherLocaleMessages = localeMessages.localeMessages.filter(lm => lm !== targetLocaleMessage);
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(sourceCode, targetLocaleMessage, otherLocaleMessages);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(sourceCode, targetLocaleMessage, otherLocaleMessages);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in no-duplicate-keys-in-locale`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow duplicate localization keys within the same locale',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-duplicate-keys-in-locale.html',
            recommended: false
        },
        fixable: null,
        schema: [
            {
                type: 'object',
                properties: {
                    ignoreI18nBlock: {
                        type: 'boolean'
                    }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
