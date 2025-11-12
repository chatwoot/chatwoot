"use strict";
const vue_eslint_parser_1 = require("vue-eslint-parser");
const jsonc_eslint_parser_1 = require("jsonc-eslint-parser");
const index_1 = require("../utils/index");
const casing_1 = require("../utils/casing");
const rule_1 = require("../utils/rule");
const regexp_1 = require("../utils/regexp");
const compat_1 = require("../utils/compat");
function getFixQuote(quotes, code) {
    if (!code.includes('\n')) {
        for (const q of ["'", '"']) {
            if (!quotes.has(q) && !code.includes(q)) {
                return q;
            }
        }
    }
    if (!quotes.has('`') && !code.includes('`')) {
        return '`';
    }
    return null;
}
const hasOnlyWhitespace = (value) => /^[\r\n\s\t\f\v]+$/.test(value);
const INNER_START_OFFSET = '<template>'.length;
function getTargetAttrs(tagName, config) {
    const result = [];
    for (const { name, attrs } of config.attributes) {
        name.lastIndex = 0;
        if (name.test(tagName)) {
            result.push(...attrs);
        }
    }
    if ((0, casing_1.isKebabCase)(tagName)) {
        result.push(...getTargetAttrs((0, casing_1.pascalCase)(tagName), config));
    }
    return new Set(result);
}
function calculateRange(node, base) {
    const range = node.range;
    if (!base) {
        return range;
    }
    const offset = base.range[0] + 1 - INNER_START_OFFSET;
    return [offset + range[0], offset + range[1]];
}
function calculateLoc(node, base, context) {
    if (!base) {
        return node.loc;
    }
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const range = calculateRange(node, base);
    return {
        start: sourceCode.getLocFromIndex(range[0]),
        end: sourceCode.getLocFromIndex(range[1])
    };
}
function testValue(value, config) {
    if (typeof value === 'string') {
        return (hasOnlyWhitespace(value) ||
            config.ignorePattern.test(value.trim()) ||
            config.ignoreText.includes(value.trim()));
    }
    else {
        return false;
    }
}
function checkVAttributeDirective(context, node, config, baseNode, scope) {
    const attrNode = node.parent;
    if (attrNode.key && attrNode.key.type === 'VDirectiveKey') {
        if ((attrNode.key.name === 'text' ||
            attrNode.key.name.name === 'text') &&
            node.expression) {
            checkExpressionContainerText(context, node.expression, config, baseNode, scope);
        }
    }
}
function checkVExpressionContainer(context, node, config, baseNode, scope) {
    if (!node.expression) {
        return;
    }
    if (node.parent && node.parent.type === 'VElement') {
        checkExpressionContainerText(context, node.expression, config, baseNode, scope);
    }
    else if (node.parent &&
        node.parent.type === 'VAttribute' &&
        node.parent.directive) {
        checkVAttributeDirective(context, node, config, baseNode, scope);
    }
}
function checkExpressionContainerText(context, expression, config, baseNode, scope) {
    if ((0, index_1.isStaticLiteral)(expression)) {
        checkLiteral(context, expression, config, baseNode, scope);
    }
    else if (expression.type === 'ConditionalExpression') {
        const targets = [expression.consequent, expression.alternate];
        targets.forEach(target => {
            if ((0, index_1.isStaticLiteral)(target)) {
                checkLiteral(context, target, config, baseNode, scope);
            }
        });
    }
}
function checkLiteral(context, literal, config, baseNode, scope) {
    const value = (0, index_1.getStaticLiteralValue)(literal);
    if (testValue(value, config)) {
        return;
    }
    const loc = calculateLoc(literal, baseNode, context);
    context.report({
        loc,
        message: `raw text '${value}' is used`,
        suggest: buildSuggest()
    });
    function buildSuggest() {
        if (scope === 'template-option') {
            if (!withoutEscape(context, baseNode)) {
                return null;
            }
        }
        else if (scope !== 'template') {
            return null;
        }
        const replaceRange = calculateRange(literal, baseNode);
        const suggest = [];
        for (const key of extractMessageKeys(context, `${value}`)) {
            suggest.push({
                desc: `Replace to "$t('${key}')".`,
                fix(fixer) {
                    return fixer.replaceTextRange(replaceRange, `$t('${key}')`);
                }
            });
        }
        const i18nBlocks = getFixableI18nBlocks(context, `${value}`);
        if (i18nBlocks) {
            suggest.push({
                desc: "Add the resource to the '<i18n>' block.",
                fix(fixer) {
                    return generateFixAddI18nBlock(context, fixer, i18nBlocks, `${value}`, [
                        fixer.insertTextBeforeRange(replaceRange, '$t('),
                        fixer.insertTextAfterRange(replaceRange, ')')
                    ]);
                }
            });
        }
        return suggest;
    }
}
function checkVAttribute(context, attribute, config, baseNode, scope) {
    if (!attribute.value) {
        return;
    }
    const literal = attribute.value;
    const value = literal.value;
    if (testValue(value, config)) {
        return;
    }
    const loc = calculateLoc(literal, baseNode, context);
    context.report({
        loc,
        message: `raw text '${value}' is used`,
        suggest: buildSuggest()
    });
    function buildSuggest() {
        if (scope === 'template-option') {
            if (!withoutEscape(context, baseNode)) {
                return null;
            }
        }
        else if (scope !== 'template') {
            return null;
        }
        const literalRange = calculateRange(literal, baseNode);
        const replaceRange = [literalRange[0] + 1, literalRange[1] - 1];
        const keyRange = calculateRange(attribute.key, baseNode);
        const sourceCode = (0, compat_1.getSourceCode)(context);
        const attrQuote = sourceCode.text[literalRange[0]];
        const quotes = new Set(attrQuote);
        if (baseNode) {
            const baseQuote = sourceCode.text[baseNode.range[0]];
            quotes.add(baseQuote);
        }
        const suggest = [];
        for (const key of extractMessageKeys(context, `${value}`)) {
            const quote = getFixQuote(quotes, key);
            if (quote) {
                suggest.push({
                    desc: `Replace to "$t('${key}')".`,
                    fix(fixer) {
                        return [
                            fixer.insertTextBeforeRange(keyRange, ':'),
                            fixer.replaceTextRange(replaceRange, `$t(${quote}${key}${quote})`)
                        ];
                    }
                });
            }
        }
        const i18nBlocks = getFixableI18nBlocks(context, `${value}`);
        const quote = getFixQuote(quotes, sourceCode.text.slice(...replaceRange));
        if (i18nBlocks && quote) {
            suggest.push({
                desc: "Add the resource to the '<i18n>' block.",
                fix(fixer) {
                    return generateFixAddI18nBlock(context, fixer, i18nBlocks, `${value}`, [
                        fixer.insertTextBeforeRange(keyRange, ':'),
                        fixer.insertTextBeforeRange(replaceRange, `$t(${quote}`),
                        fixer.insertTextAfterRange(replaceRange, `${quote})`)
                    ]);
                }
            });
        }
        return suggest;
    }
}
function checkText(context, textNode, config, baseNode, scope) {
    const value = textNode.value;
    if (testValue(value, config)) {
        return;
    }
    const loc = calculateLoc(textNode, baseNode, context);
    context.report({
        loc,
        message: `raw text '${value}' is used`,
        suggest: buildSuggest()
    });
    function buildSuggest() {
        if (scope === 'template-option') {
            if (!withoutEscape(context, baseNode)) {
                return null;
            }
        }
        const replaceRange = calculateRange(textNode, baseNode);
        const sourceCode = (0, compat_1.getSourceCode)(context);
        const quotes = new Set();
        if (baseNode) {
            const baseQuote = sourceCode.text[baseNode.range[0]];
            quotes.add(baseQuote);
        }
        const suggest = [];
        for (const key of extractMessageKeys(context, value)) {
            const quote = getFixQuote(quotes, key);
            if (quote) {
                const before = `${scope === 'jsx' ? '{' : '{{'}$t(${quote}`;
                const after = `${quote})${scope === 'jsx' ? '}' : '}}'}`;
                suggest.push({
                    desc: `Replace to "${before}${key}${after}".`,
                    fix(fixer) {
                        return fixer.replaceTextRange(replaceRange, before + key + after);
                    }
                });
            }
        }
        const i18nBlocks = getFixableI18nBlocks(context, `${value}`);
        const quote = getFixQuote(quotes, sourceCode.text.slice(...replaceRange));
        if (i18nBlocks && quote) {
            const before = `${scope === 'jsx' ? '{' : '{{'}$t(${quote}`;
            const after = `${quote})${scope === 'jsx' ? '}' : '}}'}`;
            suggest.push({
                desc: "Add the resource to the '<i18n>' block.",
                fix(fixer) {
                    return generateFixAddI18nBlock(context, fixer, i18nBlocks, `${value}`, [
                        fixer.insertTextBeforeRange(replaceRange, before),
                        fixer.insertTextAfterRange(replaceRange, after)
                    ]);
                }
            });
        }
        return suggest;
    }
}
function findVariable(variables, name) {
    return variables.find(variable => variable.name === name);
}
function getComponentTemplateValueNode(context, node) {
    const templateNode = node.properties.find((p) => p.type === 'Property' &&
        p.key.type === 'Identifier' &&
        p.key.name === 'template');
    if (templateNode) {
        if ((0, index_1.isStaticLiteral)(templateNode.value)) {
            return templateNode.value;
        }
        else if (templateNode.value.type === 'Identifier') {
            const sourceCode = (0, compat_1.getSourceCode)(context);
            const templateVariable = findVariable(sourceCode.getScope(node).variables, templateNode.value.name);
            if (templateVariable) {
                const varDeclNode = templateVariable.defs[0]
                    .node;
                if (varDeclNode.init) {
                    if ((0, index_1.isStaticLiteral)(varDeclNode.init)) {
                        return varDeclNode.init;
                    }
                }
            }
        }
    }
    return null;
}
function getComponentTemplateNode(node) {
    return (0, vue_eslint_parser_1.parse)(`<template>${(0, index_1.getStaticLiteralValue)(node)}</template>`, {})
        .templateBody;
}
function withoutEscape(context, baseNode) {
    if (!baseNode) {
        return false;
    }
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const sourceText = sourceCode.getText(baseNode).slice(1, -1);
    const templateText = `${(0, index_1.getStaticLiteralValue)(baseNode)}`;
    return sourceText === templateText;
}
function getFixableI18nBlocks(context, newKey) {
    var _a, _b;
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const df = (_b = (_a = sourceCode.parserServices).getDocumentFragment) === null || _b === void 0 ? void 0 : _b.call(_a);
    if (!df) {
        return null;
    }
    const i18nBlocks = [];
    for (const i18n of df.children.filter(index_1.isI18nBlock)) {
        const attrs = (0, index_1.getStaticAttributes)(i18n);
        if (attrs.src != null ||
            (attrs.lang != null && attrs.lang !== 'json' && attrs.lang !== 'json5')) {
            return null;
        }
        const textNode = i18n.children[0];
        const sourceString = textNode != null && textNode.type === 'VText' && textNode.value;
        if (!sourceString) {
            return null;
        }
        try {
            const ast = (0, jsonc_eslint_parser_1.parseJSON)(sourceString);
            const root = ast.body[0].expression;
            if (root.type !== 'JSONObjectExpression') {
                return null;
            }
            const objects = [];
            if (attrs.locale) {
                objects.push(root);
            }
            else {
                for (const prop of root.properties) {
                    if (prop.value.type !== 'JSONObjectExpression') {
                        return null;
                    }
                    objects.push(prop.value);
                }
            }
            for (const objNode of objects) {
                if (objNode.properties.some(prop => {
                    const keyValue = `${(0, jsonc_eslint_parser_1.getStaticJSONValue)(prop.key)}`;
                    return keyValue === newKey;
                })) {
                    return null;
                }
            }
            const offset = textNode.range[0];
            const getIndex = (index) => offset + index;
            i18nBlocks.push({
                attrs,
                i18n,
                objects,
                offsets: {
                    getLoc: (index) => {
                        return sourceCode.getLocFromIndex(getIndex(index));
                    },
                    getIndex
                }
            });
        }
        catch (_c) {
            return null;
        }
    }
    return i18nBlocks;
}
function* generateFixAddI18nBlock(context, fixer, i18nBlocks, resource, replaceFixes) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const text = JSON.stringify(resource);
    const df = sourceCode.parserServices.getDocumentFragment();
    const tokenStore = sourceCode.parserServices.getTemplateBodyTokenStore();
    if (!i18nBlocks.length) {
        let baseToken = df.children.find(index_1.isVElement);
        let beforeToken = tokenStore.getTokenBefore(baseToken, {
            includeComments: true
        });
        while (beforeToken && beforeToken.type === 'HTMLComment') {
            baseToken = beforeToken;
            beforeToken = tokenStore.getTokenBefore(beforeToken, {
                includeComments: true
            });
        }
        yield fixer.insertTextBeforeRange(baseToken.range, `<i18n>\n{\n  "en": {\n    ${text}: ${text}\n  }\n}\n</i18n>\n\n`);
        yield* replaceFixes;
        return;
    }
    const replaceFix = replaceFixes[0];
    const after = i18nBlocks.find(e => replaceFix.range[1] < e.i18n.range[0]);
    for (const { i18n, offsets, objects } of i18nBlocks) {
        if (after && after.i18n === i18n) {
            yield* replaceFixes;
        }
        for (const objectNode of objects) {
            const first = objectNode.properties[0];
            let indent = `${/^\s*/.exec(sourceCode.lines[offsets.getLoc(objectNode.range[0]).line - 1])[0]}  `;
            let next = '';
            if (first) {
                if (objectNode.loc.start.line === first.loc.start.line) {
                    next = `,\n${indent}`;
                }
                else {
                    indent = /^\s*/.exec(sourceCode.lines[offsets.getLoc(first.range[0]).line - 1])[0];
                    next = ',';
                }
            }
            yield fixer.insertTextAfterRange([
                offsets.getIndex(objectNode.range[0]),
                offsets.getIndex(objectNode.range[0] + 1)
            ], `\n${indent}${text}: ${text}${next}`);
        }
    }
    if (after == null) {
        yield* replaceFixes;
    }
}
function extractMessageKeys(context, targetValue) {
    const keys = new Set();
    const localeMessages = (0, index_1.getLocaleMessages)(context, {
        ignoreMissingSettingsError: true
    });
    for (const localeMessage of localeMessages.localeMessages) {
        for (const locale of localeMessage.locales) {
            const messages = localeMessage.getMessagesFromLocale(locale);
            for (const key of extractMessageKeysFromObject(messages, [])) {
                keys.add(key);
            }
        }
    }
    return [...keys].sort();
    function* extractMessageKeysFromObject(messages, paths) {
        for (const key of Object.keys(messages)) {
            const value = messages[key];
            if (value == null) {
                continue;
            }
            if (typeof value !== 'object') {
                if (targetValue === value) {
                    yield [...paths, key].join('.');
                }
            }
            else {
                yield* extractMessageKeysFromObject(value, [...paths, key]);
            }
        }
    }
}
function parseTargetAttrs(options) {
    const regexps = [];
    for (const tagName of Object.keys(options)) {
        const attrs = new Set(options[tagName]);
        regexps.push({
            name: (0, regexp_1.toRegExp)(tagName),
            attrs
        });
    }
    return regexps;
}
function create(context) {
    const options = context.options[0] || {};
    const config = {
        attributes: [],
        ignorePattern: /^$/,
        ignoreNodes: [],
        ignoreText: []
    };
    if (options.ignorePattern) {
        config.ignorePattern = new RegExp(options.ignorePattern, 'u');
    }
    if (options.ignoreNodes) {
        config.ignoreNodes = options.ignoreNodes;
    }
    if (options.ignoreText) {
        config.ignoreText = options.ignoreText;
    }
    if (options.attributes) {
        config.attributes = parseTargetAttrs(options.attributes);
    }
    const templateVisitor = {
        VExpressionContainer(node, baseNode = null, scope = 'template') {
            checkVExpressionContainer(context, node, config, baseNode, scope);
        },
        VAttribute(node, baseNode = null, scope = 'template') {
            if (node.directive) {
                return;
            }
            const tagName = node.parent.parent.rawName;
            const attrName = node.key.name;
            if (!getTargetAttrs(tagName, config).has(attrName)) {
                return;
            }
            checkVAttribute(context, node, config, baseNode, scope);
        },
        VText(node, baseNode = null, scope = 'template') {
            if (config.ignoreNodes.includes(node.parent.name)) {
                return;
            }
            checkText(context, node, config, baseNode, scope);
        }
    };
    return (0, index_1.defineTemplateBodyVisitor)(context, templateVisitor, {
        ObjectExpression(node) {
            const valueNode = getComponentTemplateValueNode(context, node);
            if (!valueNode) {
                return;
            }
            if ((0, index_1.getVueObjectType)(context, node) == null ||
                (valueNode.type === 'Literal' && valueNode.value == null)) {
                return;
            }
            const templateNode = getComponentTemplateNode(valueNode);
            vue_eslint_parser_1.AST.traverseNodes(templateNode, {
                enterNode(node) {
                    const visitor = templateVisitor[node.type];
                    if (visitor) {
                        visitor(node, valueNode, 'template-option');
                    }
                },
                leaveNode() {
                }
            });
        },
        JSXText(node) {
            checkText(context, node, config, null, 'jsx');
        }
    });
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'suggestion',
        docs: {
            description: 'disallow to string literal in template or JSX',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-raw-text.html',
            recommended: true
        },
        fixable: null,
        hasSuggestions: true,
        schema: [
            {
                type: 'object',
                properties: {
                    attributes: {
                        type: 'object',
                        patternProperties: {
                            '^(?:\\S+|/.*/[a-z]*)$': {
                                type: 'array',
                                items: { type: 'string' },
                                uniqueItems: true
                            }
                        },
                        additionalProperties: false
                    },
                    ignoreNodes: {
                        type: 'array'
                    },
                    ignorePattern: {
                        type: 'string'
                    },
                    ignoreText: {
                        type: 'array'
                    }
                }
            }
        ]
    },
    create
});
