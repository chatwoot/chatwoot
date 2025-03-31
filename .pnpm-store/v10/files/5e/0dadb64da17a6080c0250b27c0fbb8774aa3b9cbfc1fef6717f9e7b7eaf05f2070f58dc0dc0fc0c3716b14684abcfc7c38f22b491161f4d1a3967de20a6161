"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.usedKeysCache = exports.collectKeysFromAST = void 0;
const vue_eslint_parser_1 = require("vue-eslint-parser");
const path_1 = require("path");
const glob_utils_1 = require("./glob-utils");
const resource_loader_1 = require("./resource-loader");
const cache_loader_1 = require("./cache-loader");
const cache_function_1 = require("./cache-function");
const debug_1 = __importDefault(require("debug"));
const get_cwd_1 = require("./get-cwd");
const index_1 = require("./index");
const parser_config_resolver_1 = require("./parser-config-resolver");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:collect-keys');
function getKeyFromCallExpression(node) {
    const funcName = (node.callee.type === 'MemberExpression' &&
        node.callee.property.type === 'Identifier' &&
        node.callee.property.name) ||
        (node.callee.type === 'Identifier' && node.callee.name) ||
        '';
    if (!/^(\$t|t|\$tc|tc)$/.test(funcName) ||
        !node.arguments ||
        !node.arguments.length) {
        return null;
    }
    const [keyNode] = node.arguments;
    if (!(0, index_1.isStaticLiteral)(keyNode)) {
        return null;
    }
    return (0, index_1.getStaticLiteralValue)(keyNode);
}
function getKeyFromVDirective(node) {
    if (node.value &&
        node.value.type === 'VExpressionContainer' &&
        (0, index_1.isStaticLiteral)(node.value.expression)) {
        return (0, index_1.getStaticLiteralValue)(node.value.expression);
    }
    else {
        return null;
    }
}
function getKeyFromI18nComponent(node) {
    if (node.value && node.value.type === 'VLiteral') {
        return node.value.value;
    }
    else {
        return null;
    }
}
function collectKeysFromText(filename, parser) {
    const effectiveFilename = filename || '<text>';
    debug(`collectKeysFromFile ${effectiveFilename}`);
    try {
        const parseResult = parser(filename);
        if (!parseResult) {
            return [];
        }
        return collectKeysFromAST(parseResult.ast, parseResult.visitorKeys);
    }
    catch (_e) {
        return [];
    }
}
function collectKeyResourcesFromFiles(fileNames, cwd) {
    debug('collectKeysFromFiles', fileNames);
    const parser = (0, parser_config_resolver_1.buildParserFromConfig)(cwd);
    const results = [];
    for (const filename of fileNames) {
        debug(`Processing file ... ${filename}`);
        results.push(new resource_loader_1.ResourceLoader((0, path_1.resolve)(filename), () => {
            return collectKeysFromText(filename, parser);
        }));
    }
    return results;
}
function collectKeysFromAST(node, visitorKeys) {
    debug('collectKeysFromAST');
    const results = new Set();
    function enterNode(node) {
        if (node.type === 'VAttribute') {
            if (node.directive) {
                if (node.key.name.name === 't' ||
                    node.key.name === 't') {
                    debug("call VAttribute[directive=true][key.name.name='t'] handling ...");
                    const key = getKeyFromVDirective(node);
                    if (key) {
                        results.add(String(key));
                    }
                }
            }
            else {
                if ((node.key.name === 'path' &&
                    (node.parent.parent.name === 'i18n' ||
                        node.parent.parent.name === 'i18n-t' ||
                        node.parent.parent.rawName === 'I18nT')) ||
                    (node.key.name === 'keypath' &&
                        (node.parent.parent.name === 'i18n-t' ||
                            node.parent.parent.rawName === 'I18nT'))) {
                    debug("call VElement:matches([name=i18n], [name=i18n-t], [name=I18nT]) > VStartTag > VAttribute[key.name='path'] handling ...");
                    const key = getKeyFromI18nComponent(node);
                    if (key) {
                        results.add(key);
                    }
                }
            }
        }
        else if (node.type === 'CallExpression') {
            debug('CallExpression handling ...');
            const key = getKeyFromCallExpression(node);
            if (key) {
                results.add(String(key));
            }
        }
    }
    if (node.templateBody) {
        vue_eslint_parser_1.AST.traverseNodes(node.templateBody, {
            enterNode,
            leaveNode() {
            }
        });
    }
    vue_eslint_parser_1.AST.traverseNodes(node, {
        visitorKeys,
        enterNode,
        leaveNode() {
        }
    });
    return [...results];
}
exports.collectKeysFromAST = collectKeysFromAST;
class UsedKeysCache {
    constructor() {
        this._targetFilesLoader = new cache_loader_1.CacheLoader((cwd, files, extensions) => {
            return (0, glob_utils_1.listFilesToProcess)(files, { cwd, extensions })
                .filter(f => !f.ignored && extensions.includes((0, path_1.extname)(f.filename)))
                .map(f => f.filename);
        });
        this._collectKeyResourcesFromFiles = (0, cache_function_1.defineCacheFunction)((fileNames, cwd) => {
            return collectKeyResourcesFromFiles(fileNames, cwd);
        });
    }
    collectKeysFromFiles(files, extensions, context) {
        const result = new Set();
        for (const resource of this._getKeyResources(context, files, extensions)) {
            for (const key of resource.getResource()) {
                result.add(key);
            }
        }
        return [...result];
    }
    _getKeyResources(context, files, extensions) {
        const cwd = (0, get_cwd_1.getCwd)(context);
        const fileNames = this._targetFilesLoader.get(cwd, files, extensions, cwd);
        return this._collectKeyResourcesFromFiles(fileNames, cwd);
    }
}
exports.usedKeysCache = new UsedKeysCache();
