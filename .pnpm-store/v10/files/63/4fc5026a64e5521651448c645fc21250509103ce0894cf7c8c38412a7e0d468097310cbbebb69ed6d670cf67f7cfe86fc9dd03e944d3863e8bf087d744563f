"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseForESLint = void 0;
const espree_1 = require("./modules/espree");
const visitor_keys_1 = require("./visitor-keys");
const convert_1 = require("./convert");
const token_store_1 = require("./token-store");
const semver_1 = require("semver");
const extend_parser_1 = require("./extend-parser");
const DEFAULT_ECMA_VERSION = "latest";
function parseForESLint(code, options) {
    var _a, _b, _c, _d;
    const parserOptions = Object.assign({ filePath: "<input>", ecmaVersion: DEFAULT_ECMA_VERSION }, options || {}, {
        loc: true,
        range: true,
        raw: true,
        tokens: true,
        comment: true,
        eslintVisitorKeys: true,
        eslintScopeManager: true,
    });
    parserOptions.ecmaVersion = normalizeEcmaVersion(parserOptions.ecmaVersion);
    const ctx = getJSONSyntaxContext(parserOptions.jsonSyntax);
    const tokens = [];
    const comments = [];
    const tokenStore = new token_store_1.TokenStore(tokens);
    const nodes = [];
    parserOptions.ctx = ctx;
    parserOptions.tokenStore = tokenStore;
    parserOptions.comments = comments;
    parserOptions.nodes = nodes;
    const baseAst = (0, extend_parser_1.getParser)().parseExpressionAt(code, 0, parserOptions);
    for (const node of nodes) {
        node.type = `JSON${node.type}`;
    }
    const ast = (0, convert_1.convertProgramNode)(baseAst, tokenStore, ctx, code);
    let lastIndex = Math.max(baseAst.range[1], (_b = (_a = tokens[tokens.length - 1]) === null || _a === void 0 ? void 0 : _a.range[1]) !== null && _b !== void 0 ? _b : 0, (_d = (_c = comments[comments.length - 1]) === null || _c === void 0 ? void 0 : _c.range[1]) !== null && _d !== void 0 ? _d : 0);
    let lastChar = code[lastIndex];
    while (lastChar === "\n" ||
        lastChar === "\r" ||
        lastChar === " " ||
        lastChar === "\t") {
        lastIndex++;
        lastChar = code[lastIndex];
    }
    if (lastIndex < code.length) {
        (0, extend_parser_1.getAnyTokenErrorParser)().parseExpressionAt(code, lastIndex, parserOptions);
    }
    ast.tokens = tokens;
    ast.comments = comments;
    return {
        ast,
        visitorKeys: (0, visitor_keys_1.getVisitorKeys)(),
        services: {
            isJSON: true,
        },
    };
}
exports.parseForESLint = parseForESLint;
function getJSONSyntaxContext(str) {
    const upperCase = str === null || str === void 0 ? void 0 : str.toUpperCase();
    if (upperCase === "JSON") {
        return {
            trailingCommas: false,
            comments: false,
            plusSigns: false,
            spacedSigns: false,
            leadingOrTrailingDecimalPoints: false,
            infinities: false,
            nans: false,
            numericSeparators: false,
            binaryNumericLiterals: false,
            octalNumericLiterals: false,
            legacyOctalNumericLiterals: false,
            invalidJsonNumbers: false,
            multilineStrings: false,
            unquoteProperties: false,
            singleQuotes: false,
            numberProperties: false,
            undefinedKeywords: false,
            sparseArrays: false,
            regExpLiterals: false,
            templateLiterals: false,
            bigintLiterals: false,
            unicodeCodepointEscapes: false,
            escapeSequenceInIdentifier: false,
            parentheses: false,
            staticExpressions: false,
        };
    }
    if (upperCase === "JSONC") {
        return {
            trailingCommas: true,
            comments: true,
            plusSigns: false,
            spacedSigns: false,
            leadingOrTrailingDecimalPoints: false,
            infinities: false,
            nans: false,
            numericSeparators: false,
            binaryNumericLiterals: false,
            octalNumericLiterals: false,
            legacyOctalNumericLiterals: false,
            invalidJsonNumbers: false,
            multilineStrings: false,
            unquoteProperties: false,
            singleQuotes: false,
            numberProperties: false,
            undefinedKeywords: false,
            sparseArrays: false,
            regExpLiterals: false,
            templateLiterals: false,
            bigintLiterals: false,
            unicodeCodepointEscapes: false,
            escapeSequenceInIdentifier: false,
            parentheses: false,
            staticExpressions: false,
        };
    }
    if (upperCase === "JSON5") {
        return {
            trailingCommas: true,
            comments: true,
            plusSigns: true,
            spacedSigns: true,
            leadingOrTrailingDecimalPoints: true,
            infinities: true,
            nans: true,
            numericSeparators: false,
            binaryNumericLiterals: false,
            octalNumericLiterals: false,
            legacyOctalNumericLiterals: false,
            invalidJsonNumbers: true,
            multilineStrings: true,
            unquoteProperties: true,
            singleQuotes: true,
            numberProperties: false,
            undefinedKeywords: false,
            sparseArrays: false,
            regExpLiterals: false,
            templateLiterals: false,
            bigintLiterals: false,
            unicodeCodepointEscapes: false,
            escapeSequenceInIdentifier: false,
            parentheses: false,
            staticExpressions: false,
        };
    }
    return {
        trailingCommas: true,
        comments: true,
        plusSigns: true,
        spacedSigns: true,
        leadingOrTrailingDecimalPoints: true,
        infinities: true,
        nans: true,
        numericSeparators: true,
        binaryNumericLiterals: true,
        octalNumericLiterals: true,
        legacyOctalNumericLiterals: true,
        invalidJsonNumbers: true,
        multilineStrings: true,
        unquoteProperties: true,
        singleQuotes: true,
        numberProperties: true,
        undefinedKeywords: true,
        sparseArrays: true,
        regExpLiterals: true,
        templateLiterals: true,
        bigintLiterals: true,
        unicodeCodepointEscapes: true,
        escapeSequenceInIdentifier: true,
        parentheses: true,
        staticExpressions: true,
    };
}
function normalizeEcmaVersion(version) {
    const espree = (0, espree_1.getEspree)();
    const latestEcmaVersion = getLatestEcmaVersion(espree);
    if (version == null || version === "latest") {
        return latestEcmaVersion;
    }
    return Math.min(getEcmaVersionYear(version), latestEcmaVersion);
}
function getLatestEcmaVersion(espree) {
    if (espree.latestEcmaVersion == null) {
        for (const { v, latest } of [
            { v: "6.1.0", latest: 2020 },
            { v: "4.0.0", latest: 2019 },
        ]) {
            if ((0, semver_1.lte)(v, espree.version)) {
                return latest;
            }
        }
        return 2018;
    }
    return getEcmaVersionYear(espree.latestEcmaVersion);
}
function getEcmaVersionYear(version) {
    return version > 5 && version < 2015 ? version + 2009 : version;
}
