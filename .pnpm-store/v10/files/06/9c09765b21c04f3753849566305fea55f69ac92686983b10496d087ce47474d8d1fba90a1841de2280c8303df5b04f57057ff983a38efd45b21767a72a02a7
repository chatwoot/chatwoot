"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const casing_1 = require("../utils/casing");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:key-format-style');
const allowedCaseOptions = [
    'camelCase',
    'kebab-case',
    'lowercase',
    'snake_case',
    'SCREAMING_SNAKE_CASE'
];
function create(context) {
    var _a, _b, _c;
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const expectCasing = (_a = context.options[0]) !== null && _a !== void 0 ? _a : 'camelCase';
    const checker = (0, casing_1.getCasingChecker)(expectCasing);
    const allowArray = (_b = context.options[1]) === null || _b === void 0 ? void 0 : _b.allowArray;
    const splitByDotsOption = (_c = context.options[1]) === null || _c === void 0 ? void 0 : _c.splitByDots;
    function reportUnknown(reportNode) {
        context.report({
            message: `Unexpected object key. Use ${expectCasing} string key instead`,
            loc: reportNode.loc
        });
    }
    function verifyKeyForString(key, reportNode) {
        for (const target of splitByDotsOption && key.includes('.')
            ? splitByDots(key, reportNode)
            : [{ key, loc: reportNode.loc }]) {
            if (!checker(target.key)) {
                context.report({
                    message: `"{{key}}" is not {{expectCasing}}`,
                    loc: target.loc,
                    data: {
                        key: target.key,
                        expectCasing
                    }
                });
            }
        }
    }
    function verifyKeyForNumber(key, reportNode) {
        if (!allowArray) {
            context.report({
                message: `Unexpected array element`,
                loc: reportNode.loc
            });
        }
    }
    function splitByDots(key, reportNode) {
        const result = [];
        let startIndex = 0;
        let index;
        while ((index = key.indexOf('.', startIndex)) >= 0) {
            const getLoc = buildGetLocation(startIndex, index);
            result.push({
                key: key.slice(startIndex, index),
                get loc() {
                    return getLoc();
                }
            });
            startIndex = index + 1;
        }
        const getLoc = buildGetLocation(startIndex, key.length);
        result.push({
            key: key.slice(startIndex, index),
            get loc() {
                return getLoc();
            }
        });
        return result;
        function buildGetLocation(start, end) {
            const offset = reportNode.type === 'JSONLiteral' ||
                (reportNode.type === 'YAMLScalar' &&
                    (reportNode.style === 'double-quoted' ||
                        reportNode.style === 'single-quoted'))
                ? reportNode.range[0] + 1
                : reportNode.range[0];
            let cachedLoc;
            return () => {
                if (cachedLoc) {
                    return cachedLoc;
                }
                return (cachedLoc = {
                    start: sourceCode.getLocFromIndex(offset + start),
                    end: sourceCode.getLocFromIndex(offset + end)
                });
            };
        }
    }
    function createVisitorForJson(targetLocaleMessage) {
        let keyStack = {
            inLocale: targetLocaleMessage.isResolvedLocaleByFileName()
        };
        return {
            JSONProperty(node) {
                const { inLocale } = keyStack;
                keyStack = {
                    node,
                    inLocale: true,
                    upper: keyStack
                };
                if (!inLocale) {
                    return;
                }
                const key = node.key.type === 'JSONLiteral' ? `${node.key.value}` : node.key.name;
                verifyKeyForString(key, node.key);
            },
            'JSONProperty:exit'() {
                keyStack = keyStack.upper;
            },
            'JSONArrayExpression > *'(node) {
                const key = node.parent.elements.indexOf(node);
                verifyKeyForNumber(key, node);
            }
        };
    }
    function createVisitorForYaml(targetLocaleMessage) {
        const yamlKeyNodes = new Set();
        let keyStack = {
            inLocale: targetLocaleMessage.isResolvedLocaleByFileName()
        };
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
                const { inLocale } = keyStack;
                keyStack = {
                    node,
                    inLocale: true,
                    upper: keyStack
                };
                if (!inLocale) {
                    return;
                }
                if (node.key != null) {
                    if (withinKey(node)) {
                        return;
                    }
                    yamlKeyNodes.add(node.key);
                }
                if (node.key == null) {
                    reportUnknown(node);
                }
                else if (node.key.type === 'YAMLScalar') {
                    const keyValue = node.key.value;
                    const key = typeof keyValue === 'string' ? keyValue : String(keyValue);
                    verifyKeyForString(key, node.key);
                }
                else {
                    reportUnknown(node);
                }
            },
            'YAMLPair:exit'() {
                keyStack = keyStack.upper;
            },
            'YAMLSequence > *'(node) {
                if (withinKey(node)) {
                    return;
                }
                const key = node.parent.entries.indexOf(node);
                verifyKeyForNumber(key, node);
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
            return createVisitorForJson(targetLocaleMessage);
        }, ctx => {
            const localeMessages = (0, index_1.getLocaleMessages)(context);
            const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
            if (!targetLocaleMessage) {
                return {};
            }
            return createVisitorForYaml(targetLocaleMessage);
        });
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in key-format-style`);
            return {};
        }
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(targetLocaleMessage);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(targetLocaleMessage);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in key-format-style`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'layout',
        docs: {
            description: 'enforce specific casing for localization keys',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/key-format-style.html',
            recommended: false
        },
        fixable: null,
        schema: [
            {
                enum: [...allowedCaseOptions]
            },
            {
                type: 'object',
                properties: {
                    allowArray: {
                        type: 'boolean'
                    },
                    splitByDots: {
                        type: 'boolean'
                    }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
