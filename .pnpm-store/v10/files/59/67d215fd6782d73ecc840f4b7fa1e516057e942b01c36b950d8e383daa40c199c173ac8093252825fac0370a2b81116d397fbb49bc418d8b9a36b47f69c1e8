"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const collect_keys_1 = require("../utils/collect-keys");
const collect_linked_keys_1 = require("../utils/collect-linked-keys");
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const key_path_1 = require("../utils/key-path");
const get_cwd_1 = require("../utils/get-cwd");
const rule_1 = require("../utils/rule");
const regexp_1 = require("../utils/regexp");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-unused-keys');
function isDef(v) {
    return v != null;
}
function getUsedKeysMap(targetLocaleMessage, values, usedkeys, context) {
    const usedKeysMap = {};
    for (const key of [...usedkeys, ...(0, collect_linked_keys_1.collectLinkedKeys)(values, context)]) {
        usedKeysMap[key] = {};
        const paths = (0, key_path_1.parsePath)(key);
        let map = usedKeysMap;
        while (paths.length) {
            const path = paths.shift();
            map = map[path] = map[path] || {};
        }
    }
    if (targetLocaleMessage.localeKey === 'key') {
        return targetLocaleMessage.locales.reduce((keys, locale) => {
            keys[locale] = usedKeysMap;
            return keys;
        }, {});
    }
    return usedKeysMap;
}
function create(context) {
    const filename = (0, compat_1.getFilename)(context);
    const options = (context.options && context.options[0]) || {};
    const enableFix = options.enableFix;
    const ignores = (options.ignores || []).map(regexp_1.toRegExp);
    function createVerifyContext(usedKeys, { buildFixer, buildAllFixer }) {
        let pathStack = { usedKeys, keyPath: [] };
        const reports = [];
        return {
            enterKey(key, reportNode, ignoreReport) {
                const keyPath = [...pathStack.keyPath, key];
                pathStack = {
                    upper: pathStack,
                    node: reportNode,
                    usedKeys: (pathStack.usedKeys && pathStack.usedKeys[key]) ||
                        false,
                    keyPath
                };
                const isUnused = !pathStack.usedKeys;
                if (isUnused) {
                    if (!ignoreReport)
                        reports.push({
                            node: reportNode,
                            keyPath
                        });
                }
            },
            leaveKey(reportNode) {
                if (pathStack.node === reportNode) {
                    pathStack = pathStack.upper;
                }
            },
            reports() {
                for (const { node, keyPath } of reports) {
                    const keyPathStr = (0, key_path_1.joinPath)(...keyPath);
                    if (ignores.some(reg => reg.test(keyPathStr))) {
                        continue;
                    }
                    const fix = buildFixer(node);
                    context.report({
                        message: `unused '${keyPathStr}' key`,
                        loc: node.loc,
                        fix: enableFix ? fix : null,
                        suggest: [
                            {
                                desc: `Remove the '${keyPathStr}' key.`,
                                fix
                            },
                            reports.length > 1
                                ? {
                                    desc: 'Remove all unused keys.',
                                    fix: buildAllFixer(reports.map(({ node: n }) => n))
                                }
                                : null
                        ].filter(isDef)
                    });
                }
            }
        };
    }
    function createVisitorForJson(sourceCode, usedKeys) {
        const verifyContext = createVerifyContext(usedKeys, {
            buildFixer(node) {
                return fixer => fixer.removeRange(fixRemoveRange(node));
            },
            buildAllFixer(nodes) {
                return function* (fixer) {
                    yield* fixAllRemoveKeys(fixer, nodes);
                };
            }
        });
        function isIgnore(node) {
            return (node.type === 'JSONArrayExpression' ||
                node.type === 'JSONObjectExpression');
        }
        return {
            JSONProperty(node) {
                const key = node.key.type === 'JSONLiteral' ? `${node.key.value}` : node.key.name;
                verifyContext.enterKey(key, node.key, isIgnore(node.value));
            },
            'JSONProperty:exit'(node) {
                verifyContext.leaveKey(node.key);
            },
            'JSONArrayExpression > *'(node) {
                const key = node.parent.elements.indexOf(node);
                verifyContext.enterKey(key, node, isIgnore(node));
            },
            'JSONArrayExpression > *:exit'(node) {
                verifyContext.leaveKey(node);
            },
            'Program:exit'() {
                verifyContext.reports();
            }
        };
        function* fixAllRemoveKeys(fixer, nodes) {
            const removed = new Set();
            let preLast = 0;
            for (const node of nodes) {
                const range = fixRemoveRange(node, removed);
                const start = Math.max(preLast, range[0]);
                yield fixer.removeRange([start, range[1]]);
                preLast = range[1];
            }
        }
        function fixRemoveRange(node, removedNodes = new Set()) {
            const parent = node.parent;
            let removeNode;
            let isFirst = false;
            let isLast = false;
            if (parent.type === 'JSONProperty') {
                removeNode = parent;
                const properties = parent.parent.properties.filter(p => !removedNodes.has(p));
                const index = properties.indexOf(parent);
                isFirst = index === 0;
                isLast = index === properties.length - 1;
            }
            else {
                removeNode = node;
                if (parent.type === 'JSONArrayExpression') {
                    const elements = parent.elements.filter(e => e == null || !removedNodes.has(e));
                    const index = elements.indexOf(node);
                    isFirst = index === 0;
                    isLast = index === elements.length - 1;
                }
            }
            removedNodes.add(removeNode);
            const range = [...removeNode.range];
            if (isLast || isFirst) {
                const after = sourceCode.getTokenAfter(removeNode);
                if (after && after.type === 'Punctuator' && after.value === ',') {
                    range[1] = after.range[1];
                }
            }
            const before = sourceCode.getTokenBefore(removeNode);
            if (before) {
                if (before.type === 'Punctuator' && before.value === ',') {
                    range[0] = before.range[0];
                }
                else {
                    range[0] = before.range[1];
                }
            }
            return range;
        }
    }
    function createVisitorForYaml(sourceCode, usedKeys) {
        const verifyContext = createVerifyContext(usedKeys, {
            buildFixer(node) {
                return function* (fixer) {
                    const parentToCheck = node.parent;
                    const removeNode = parentToCheck.type === 'YAMLPair' ? parentToCheck : node;
                    const parent = removeNode.parent;
                    if (parent.type === 'YAMLMapping' || parent.type === 'YAMLSequence') {
                        if (parent.style === 'flow') {
                            yield fixForFlow(fixer, removeNode);
                        }
                        else {
                            yield* fixForBlock(fixer, removeNode);
                        }
                    }
                };
            },
            buildAllFixer(nodes) {
                return function* (fixer) {
                    const removed = new Set();
                    const removeNodes = nodes.map(node => {
                        const parentToCheck = node.parent;
                        return parentToCheck.type === 'YAMLPair' ? parentToCheck : node;
                    });
                    for (const removeNode of removeNodes) {
                        if (removed.has(removeNode)) {
                            continue;
                        }
                        const parent = removeNode.parent;
                        if (parent.type === 'YAMLMapping') {
                            if (parent.pairs.every(p => removeNodes.includes(p))) {
                                const before = sourceCode.getTokenBefore(parent);
                                if (before) {
                                    yield fixer.replaceTextRange([before.range[1], parent.range[1]], ' {}');
                                }
                                else {
                                    yield fixer.replaceText(parent, '{}');
                                }
                                parent.pairs.forEach(n => removed.add(n));
                                continue;
                            }
                            removed.add(removeNode);
                            if (parent.style === 'flow') {
                                yield fixForFlow(fixer, removeNode);
                            }
                            else {
                                yield* fixForBlock(fixer, removeNode);
                            }
                        }
                        else if (parent.type === 'YAMLSequence') {
                            if (parent.entries.every(p => p && removeNodes.includes(p))) {
                                const before = sourceCode.getTokenBefore(parent);
                                if (before) {
                                    yield fixer.replaceTextRange([before.range[1], parent.range[1]], ' []');
                                }
                                else {
                                    yield fixer.replaceText(parent, '[]');
                                }
                                parent.entries.forEach(n => removed.add(n));
                                continue;
                            }
                            removed.add(removeNode);
                            if (parent.style === 'flow') {
                                yield fixForFlow(fixer, removeNode);
                            }
                            else {
                                yield* fixForBlock(fixer, removeNode);
                            }
                        }
                    }
                };
            }
        });
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
        function isIgnore(node) {
            return Boolean(node && (node.type === 'YAMLMapping' || node.type === 'YAMLSequence'));
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
                verifyContext.enterKey(key, node.key, isIgnore(node.value));
            },
            'YAMLPair:exit'(node) {
                verifyContext.leaveKey(node.key);
            },
            'YAMLSequence > *'(node) {
                const key = node.parent.entries.indexOf(node);
                verifyContext.enterKey(key, node, isIgnore(node));
            },
            'YAMLSequence > *:exit'(node) {
                verifyContext.leaveKey(node);
            },
            'Program:exit'() {
                verifyContext.reports();
            }
        };
        function* fixForBlock(fixer, removeNode) {
            const parent = removeNode.parent;
            if (parent.type === 'YAMLMapping') {
                if (parent.pairs.length === 1) {
                    const before = sourceCode.getTokenBefore(parent);
                    if (before) {
                        yield fixer.replaceTextRange([before.range[1], parent.range[1]], ' {}');
                    }
                    else {
                        yield fixer.replaceText(parent, '{}');
                    }
                }
                else {
                    const before = sourceCode.getTokenBefore(removeNode);
                    yield fixer.removeRange([
                        before ? before.range[1] : removeNode.range[0],
                        removeNode.range[1]
                    ]);
                }
            }
            else if (parent.type === 'YAMLSequence') {
                if (parent.entries.length === 1) {
                    const before = sourceCode.getTokenBefore(parent);
                    if (before) {
                        yield fixer.replaceTextRange([before.range[1], parent.range[1]], ' []');
                    }
                    else {
                        yield fixer.replaceText(parent, '[]');
                    }
                }
                else {
                    const hyphen = sourceCode.getTokenBefore(removeNode);
                    const before = sourceCode.getTokenBefore(hyphen || removeNode);
                    yield fixer.removeRange([
                        before
                            ? before.range[1]
                            : hyphen
                                ? hyphen.range[0]
                                : removeNode.range[0],
                        removeNode.range[1]
                    ]);
                }
            }
        }
        function fixForFlow(fixer, removeNode) {
            const parent = removeNode.parent;
            let isFirst = false;
            let isLast = false;
            if (parent.type === 'YAMLMapping') {
                const index = parent.pairs.indexOf(removeNode);
                isFirst = index === 0;
                isLast = index === parent.pairs.length - 1;
            }
            else if (parent.type === 'YAMLSequence') {
                const index = parent.entries.indexOf(removeNode);
                isFirst = index === 0;
                isLast = index === parent.entries.length - 1;
            }
            const range = [...removeNode.range];
            if (isLast || isFirst) {
                const after = sourceCode.getTokenAfter(removeNode);
                if (after && after.type === 'Punctuator' && after.value === ',') {
                    range[1] = after.range[1];
                }
            }
            const before = sourceCode.getTokenBefore(removeNode);
            if (before) {
                if (before.type === 'Punctuator' && before.value === ',') {
                    range[0] = before.range[0];
                }
                else {
                    range[0] = before.range[1];
                }
            }
            return fixer.removeRange(range);
        }
    }
    const sourceCode = (0, compat_1.getSourceCode)(context);
    if ((0, path_1.extname)(filename) === '.vue') {
        const createCustomBlockRule = (createVisitor) => {
            return ctx => {
                const localeMessages = (0, index_1.getLocaleMessages)(context);
                const usedLocaleMessageKeys = (0, collect_keys_1.collectKeysFromAST)(sourceCode.ast, sourceCode.visitorKeys);
                const targetLocaleMessage = localeMessages.findBlockLocaleMessage(ctx.parserServices.customBlock);
                if (!targetLocaleMessage) {
                    return {};
                }
                const usedKeys = getUsedKeysMap(targetLocaleMessage, targetLocaleMessage.messages, usedLocaleMessageKeys, context);
                return createVisitor((0, compat_1.getSourceCode)(ctx), usedKeys);
            };
        };
        return (0, index_1.defineCustomBlocksVisitor)(context, createCustomBlockRule(createVisitorForJson), createCustomBlockRule(createVisitorForYaml));
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in no-unused-keys`);
            return {};
        }
        const src = options.src || (0, get_cwd_1.getCwd)(context);
        const extensions = options.extensions || ['.js', '.vue'];
        const usedLocaleMessageKeys = collect_keys_1.usedKeysCache.collectKeysFromFiles([src], extensions, context);
        const usedKeys = getUsedKeysMap(targetLocaleMessage, targetLocaleMessage.messages, usedLocaleMessageKeys, context);
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(sourceCode, usedKeys);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(sourceCode, usedKeys);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in no-unused-keys`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'suggestion',
        docs: {
            description: 'disallow unused localization keys',
            category: 'Best Practices',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-unused-keys.html',
            recommended: false
        },
        fixable: 'code',
        hasSuggestions: true,
        schema: [
            {
                type: 'object',
                properties: {
                    src: {
                        type: 'string'
                    },
                    extensions: {
                        type: 'array',
                        items: { type: 'string' },
                        default: ['.js', '.vue']
                    },
                    ignores: {
                        type: 'array',
                        items: { type: 'string' }
                    },
                    enableFix: {
                        type: 'boolean'
                    }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
