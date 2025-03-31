"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.compositingVisitors = exports.skipTSAsExpression = exports.getStaticAttributes = exports.isI18nBlock = exports.isVElement = exports.getScriptSetupElement = exports.getVueObjectType = exports.defineCustomBlocksVisitor = exports.getLocaleMessages = exports.getStaticLiteralValue = exports.isStaticLiteral = exports.getDirective = exports.getAttribute = exports.defineTemplateBodyVisitor = void 0;
const glob_1 = require("glob");
const path_1 = require("path");
const locale_messages_1 = require("./locale-messages");
const cache_loader_1 = require("./cache-loader");
const cache_function_1 = require("./cache-function");
const jsoncESLintParser = __importStar(require("jsonc-eslint-parser"));
const yamlESLintParser = __importStar(require("yaml-eslint-parser"));
const get_cwd_1 = require("./get-cwd");
const compat_1 = require("./compat");
const UNEXPECTED_ERROR_LOCATION = { line: 1, column: 0 };
function defineTemplateBodyVisitor(context, templateBodyVisitor, scriptVisitor) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    if (sourceCode.parserServices.defineTemplateBodyVisitor == null) {
        const filename = (0, compat_1.getFilename)(context);
        if ((0, path_1.extname)(filename) === '.vue') {
            context.report({
                loc: UNEXPECTED_ERROR_LOCATION,
                message: 'Use the latest vue-eslint-parser. See also https://github.com/vuejs/eslint-plugin-vue#what-is-the-use-the-latest-vue-eslint-parser-error'
            });
        }
        return {};
    }
    return sourceCode.parserServices.defineTemplateBodyVisitor(templateBodyVisitor, scriptVisitor);
}
exports.defineTemplateBodyVisitor = defineTemplateBodyVisitor;
function getAttribute(node, name) {
    return (node.startTag.attributes
        .map(node => (!node.directive ? node : null))
        .find(node => {
        return node && node.key.name === name;
    }) || null);
}
exports.getAttribute = getAttribute;
function getDirective(node, name, argument) {
    return (node.startTag.attributes
        .map(node => (node.directive ? node : null))
        .find(node => {
        return (node &&
            node.key.name.name === name &&
            (argument === undefined ||
                (node.key.argument &&
                    node.key.argument.type === 'VIdentifier' &&
                    node.key.argument.name) === argument));
    }) || null);
}
exports.getDirective = getDirective;
function isStaticLiteral(node) {
    return Boolean(node &&
        (node.type === 'Literal' ||
            (node.type === 'TemplateLiteral' && node.expressions.length === 0)));
}
exports.isStaticLiteral = isStaticLiteral;
function getStaticLiteralValue(node) {
    return node.type !== 'TemplateLiteral'
        ? node.value
        : node.quasis[0].value.cooked || node.quasis[0].value.raw;
}
exports.getStaticLiteralValue = getStaticLiteralValue;
function loadLocaleMessages(localeFilesList, cwd) {
    const results = [];
    const checkDupeMap = {};
    for (const { files, localeKey, localePattern } of localeFilesList) {
        for (const file of files) {
            const localeKeys = checkDupeMap[file] || (checkDupeMap[file] = []);
            if (localeKeys.includes(localeKey)) {
                continue;
            }
            localeKeys.push(localeKey);
            const fullpath = (0, path_1.resolve)(cwd, file);
            results.push(new locale_messages_1.FileLocaleMessage({ fullpath, localeKey, localePattern }));
        }
    }
    return results;
}
const puttedSettingsError = new WeakSet();
function getLocaleMessages(context, options) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const { settings } = context;
    const localeDir = (settings['vue-i18n'] && settings['vue-i18n'].localeDir) || null;
    const documentFragment = sourceCode.parserServices.getDocumentFragment &&
        sourceCode.parserServices.getDocumentFragment();
    const i18nBlocks = (documentFragment &&
        documentFragment.children.filter((node) => node.type === 'VElement' && node.name === 'i18n')) ||
        [];
    if (!localeDir && !i18nBlocks.length) {
        if (!puttedSettingsError.has(context) &&
            !(options === null || options === void 0 ? void 0 : options.ignoreMissingSettingsError)) {
            context.report({
                loc: UNEXPECTED_ERROR_LOCATION,
                message: `You need to set 'localeDir' at 'settings', or '<i18n>' blocks. See the 'eslint-plugin-vue-i18n' documentation`
            });
            puttedSettingsError.add(context);
        }
        return new locale_messages_1.LocaleMessages([]);
    }
    return new locale_messages_1.LocaleMessages([
        ...(getLocaleMessagesFromI18nBlocks(context, i18nBlocks) || []),
        ...((localeDir &&
            localeDirLocaleMessagesCache.getLocaleMessagesFromLocaleDir(context, localeDir)) ||
            [])
    ]);
}
exports.getLocaleMessages = getLocaleMessages;
class LocaleDirLocaleMessagesCache {
    constructor() {
        this._targetFilesLoader = new cache_loader_1.CacheLoader((pattern, cwd) => (0, glob_1.sync)(pattern, { cwd }));
        this._loadLocaleMessages = (0, cache_function_1.defineCacheFunction)((localeFilesList, cwd) => {
            return loadLocaleMessages(localeFilesList, cwd);
        });
    }
    getLocaleMessagesFromLocaleDir(context, localeDir) {
        const cwd = (0, get_cwd_1.getCwd)(context);
        let localeFilesList;
        if (Array.isArray(localeDir)) {
            localeFilesList = localeDir.map(dir => this._toLocaleFiles(dir, cwd));
        }
        else {
            localeFilesList = [this._toLocaleFiles(localeDir, cwd)];
        }
        return this._loadLocaleMessages(localeFilesList, cwd);
    }
    _toLocaleFiles(localeDir, cwd) {
        var _a;
        const targetFilesLoader = this._targetFilesLoader;
        if (typeof localeDir === 'string') {
            return {
                files: targetFilesLoader.get(localeDir, cwd),
                localeKey: 'file'
            };
        }
        else {
            return {
                files: targetFilesLoader.get(localeDir.pattern, cwd),
                localeKey: String((_a = localeDir.localeKey) !== null && _a !== void 0 ? _a : 'file'),
                localePattern: localeDir.localePattern
            };
        }
    }
}
const localeDirLocaleMessagesCache = new LocaleDirLocaleMessagesCache();
const i18nBlockLocaleMessages = new WeakMap();
function getLocaleMessagesFromI18nBlocks(context, i18nBlocks) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    let localeMessages = i18nBlockLocaleMessages.get(sourceCode.ast);
    if (localeMessages) {
        return localeMessages;
    }
    const filename = (0, compat_1.getFilename)(context);
    localeMessages = i18nBlocks
        .map(block => {
        const attrs = getStaticAttributes(block);
        let localeMessage = null;
        if (attrs.src) {
            const fullpath = (0, path_1.resolve)((0, path_1.dirname)(filename), attrs.src);
            if (attrs.locale) {
                localeMessage = new locale_messages_1.FileLocaleMessage({
                    fullpath,
                    locales: [attrs.locale],
                    localeKey: 'file'
                });
            }
            else {
                localeMessage = new locale_messages_1.FileLocaleMessage({
                    fullpath,
                    localeKey: 'key'
                });
            }
        }
        else if (block.endTag) {
            if (attrs.locale) {
                localeMessage = new locale_messages_1.BlockLocaleMessage({
                    block,
                    fullpath: filename,
                    locales: [attrs.locale],
                    localeKey: 'file',
                    context,
                    lang: attrs.lang
                });
            }
            else {
                localeMessage = new locale_messages_1.BlockLocaleMessage({
                    block,
                    fullpath: filename,
                    localeKey: 'key',
                    context,
                    lang: attrs.lang
                });
            }
        }
        if (localeMessage) {
            return localeMessage;
        }
        return null;
    })
        .filter(e => e);
    i18nBlockLocaleMessages.set(sourceCode.ast, localeMessages);
    return localeMessages;
}
function defineCustomBlocksVisitor(context, jsonRule, yamlRule) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    if (!sourceCode.parserServices.defineCustomBlocksVisitor) {
        return {};
    }
    const jsonVisitor = sourceCode.parserServices.defineCustomBlocksVisitor(context, jsoncESLintParser, {
        target(lang, block) {
            if (block.name !== 'i18n') {
                return false;
            }
            return !lang || lang === 'json' || lang === 'json5';
        },
        create: jsonRule
    });
    const yamlVisitor = sourceCode.parserServices.defineCustomBlocksVisitor(context, yamlESLintParser, {
        target(lang, block) {
            if (block.name !== 'i18n') {
                return false;
            }
            return lang === 'yaml' || lang === 'yml';
        },
        create: yamlRule
    });
    return compositingVisitors(jsonVisitor, yamlVisitor);
}
exports.defineCustomBlocksVisitor = defineCustomBlocksVisitor;
function getVueObjectType(context, node) {
    if (node.type !== 'ObjectExpression' || !node.parent) {
        return null;
    }
    const parent = node.parent;
    if (parent.type === 'ExportDefaultDeclaration') {
        const ext = (0, path_1.extname)((0, compat_1.getFilename)(context)).toLowerCase();
        if ((ext === '.vue' || ext === '.jsx' || !ext) &&
            skipTSAsExpression(parent.declaration) === node) {
            const scriptSetup = getScriptSetupElement(context);
            if (scriptSetup &&
                scriptSetup.range[0] <= parent.range[0] &&
                parent.range[1] <= scriptSetup.range[1]) {
                return null;
            }
            return 'export';
        }
    }
    else if (parent.type === 'CallExpression') {
        if (getVueComponentDefinitionType(node) != null &&
            skipTSAsExpression(parent.arguments.slice(-1)[0]) === node) {
            return 'definition';
        }
    }
    else if (parent.type === 'NewExpression') {
        if (isVueInstance(parent) &&
            skipTSAsExpression(parent.arguments[0]) === node) {
            return 'instance';
        }
    }
    else if (parent.type === 'VariableDeclarator') {
        if (parent.init === node &&
            parent.id.type === 'Identifier' &&
            /^[A-Z][a-zA-Z\d]+/u.test(parent.id.name) &&
            parent.id.name.toUpperCase() !== parent.id.name) {
            return 'variable';
        }
    }
    else if (parent.type === 'Property') {
        const componentsCandidate = parent.parent;
        const pp = componentsCandidate.parent;
        if (pp &&
            pp.type === 'Property' &&
            pp.value === componentsCandidate &&
            !pp.computed &&
            (pp.key.type === 'Identifier'
                ? pp.key.name
                : pp.key.type === 'Literal'
                    ? `${pp.key.value}`
                    : '') === 'components') {
            return 'components-option';
        }
    }
    if (getComponentComments(context).some(el => el.loc.end.line === node.loc.start.line - 1)) {
        return 'mark';
    }
    return null;
}
exports.getVueObjectType = getVueObjectType;
function getScriptSetupElement(context) {
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const df = sourceCode.parserServices.getDocumentFragment &&
        sourceCode.parserServices.getDocumentFragment();
    if (!df) {
        return null;
    }
    const scripts = df.children
        .filter(isVElement)
        .filter(e => e.name === 'script');
    if (scripts.length === 2) {
        return scripts.find(e => getAttribute(e, 'setup')) || null;
    }
    else {
        const script = scripts[0];
        if (script && getAttribute(script, 'setup')) {
            return script;
        }
    }
    return null;
}
exports.getScriptSetupElement = getScriptSetupElement;
function isVElement(node) {
    return node.type === 'VElement';
}
exports.isVElement = isVElement;
function isI18nBlock(node) {
    return isVElement(node) && node.name === 'i18n';
}
exports.isI18nBlock = isI18nBlock;
function getStaticAttributes(element) {
    const attrs = {};
    for (const attr of element.startTag.attributes) {
        if (!attr.directive && attr.value) {
            attrs[attr.key.name] = attr.value.value;
        }
    }
    return attrs;
}
exports.getStaticAttributes = getStaticAttributes;
function skipTSAsExpression(node) {
    if (!node) {
        return node;
    }
    if (node.type === 'TSAsExpression') {
        return skipTSAsExpression(node.expression);
    }
    return node;
}
exports.skipTSAsExpression = skipTSAsExpression;
function compositingVisitors(visitor, ...visitors) {
    for (const v of visitors) {
        for (const key in v) {
            if (visitor[key]) {
                const o = visitor[key];
                visitor[key] = (...args) => {
                    o(...args);
                    v[key](...args);
                };
            }
            else {
                visitor[key] = v[key];
            }
        }
    }
    return visitor;
}
exports.compositingVisitors = compositingVisitors;
function getVueComponentDefinitionType(node) {
    const parent = node.parent;
    if (parent && parent.type === 'CallExpression') {
        const callee = parent.callee;
        if (callee.type === 'MemberExpression') {
            const calleeObject = skipTSAsExpression(callee.object);
            if (calleeObject.type === 'Identifier') {
                const propName = !callee.computed &&
                    callee.property.type === 'Identifier' &&
                    callee.property.name;
                if (calleeObject.name === 'Vue') {
                    const maybeFullVueComponentForVue2 = propName && isObjectArgument(parent);
                    return maybeFullVueComponentForVue2 &&
                        (propName === 'component' ||
                            propName === 'mixin' ||
                            propName === 'extend')
                        ? propName
                        : null;
                }
                const maybeFullVueComponent = propName && isObjectArgument(parent);
                return maybeFullVueComponent &&
                    (propName === 'component' || propName === 'mixin')
                    ? propName
                    : null;
            }
        }
        if (callee.type === 'Identifier') {
            if (callee.name === 'component') {
                const isDestructedVueComponent = isObjectArgument(parent);
                return isDestructedVueComponent ? 'component' : null;
            }
            if (callee.name === 'createApp') {
                const isAppVueComponent = isObjectArgument(parent);
                return isAppVueComponent ? 'createApp' : null;
            }
            if (callee.name === 'defineComponent') {
                const isDestructedVueComponent = isObjectArgument(parent);
                return isDestructedVueComponent ? 'defineComponent' : null;
            }
        }
    }
    return null;
    function isObjectArgument(node) {
        return (node.arguments.length > 0 &&
            skipTSAsExpression(node.arguments.slice(-1)[0]).type ===
                'ObjectExpression');
    }
}
function isVueInstance(node) {
    const callee = node.callee;
    return Boolean(node.type === 'NewExpression' &&
        callee.type === 'Identifier' &&
        callee.name === 'Vue' &&
        node.arguments.length &&
        skipTSAsExpression(node.arguments[0]).type === 'ObjectExpression');
}
const componentComments = new WeakMap();
function getComponentComments(context) {
    let tokens = componentComments.get(context);
    if (tokens) {
        return tokens;
    }
    const sourceCode = (0, compat_1.getSourceCode)(context);
    tokens = sourceCode
        .getAllComments()
        .filter(comment => /@vue\/component/g.test(comment.value));
    componentComments.set(context, tokens);
    return tokens;
}
