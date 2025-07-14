"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convertRoot = void 0;
const tags_1 = require("./tags");
const yaml_1 = require("yaml");
const isPair = yaml_1.isPair;
class PreTokens {
    constructor(array, ctx) {
        this.index = 0;
        this.array = array;
        this.ctx = ctx;
    }
    first() {
        let cst;
        while ((cst = this.array[this.index])) {
            if (processCommentOrSpace(cst, this.ctx)) {
                this.index++;
                continue;
            }
            return cst;
        }
        return null;
    }
    consume() {
        const cst = this.first();
        if (cst) {
            this.index++;
        }
        return cst;
    }
    back() {
        this.index--;
    }
    each(callback) {
        let cst;
        while ((cst = this.consume())) {
            callback(cst);
        }
    }
}
/** Checks whether the give cst node is plain scaler */
function isPlainScalarCST(cst) {
    return cst.type === "scalar";
}
/** Checks whether the give cst node is double-quoted-scalar */
function isDoubleQuotedScalarCST(cst) {
    return cst.type === "double-quoted-scalar";
}
/** Checks whether the give cst node is single-quoted-scalar */
function isSingleQuotedScalarCST(cst) {
    return cst.type === "single-quoted-scalar";
}
/** Checks whether the give cst node is alias scalar */
function isAliasScalarCST(cst) {
    return cst.type === "alias";
}
/** Checks whether the give cst node is anchor */
function isAnchorCST(cst) {
    return cst.type === "anchor";
}
/** Checks whether the give cst node is tag */
function isTagCST(cst) {
    return cst.type === "tag";
}
/** Get node type name */
function getNodeType(node) {
    /* istanbul ignore next */
    return (0, yaml_1.isMap)(node)
        ? "MAP"
        : (0, yaml_1.isSeq)(node)
            ? "SEQ"
            : (0, yaml_1.isScalar)(node)
                ? "SCALAR"
                : (0, yaml_1.isAlias)(node)
                    ? "ALIAS"
                    : isPair(node)
                        ? "PAIR"
                        : (0, yaml_1.isDocument)(node)
                            ? "DOCUMENT"
                            : "unknown";
}
/**
 * Convert yaml root to YAMLProgram
 */
function convertRoot(docs, ctx) {
    var _a;
    const { cstNodes, nodes } = docs;
    const ast = Object.assign({ type: "Program", body: [], comments: ctx.comments, sourceType: "module", tokens: ctx.tokens, parent: null }, ctx.getConvertLocation(0, ctx.code.length));
    let directives = [];
    let bufferDoc = null;
    const cstDocs = [];
    for (const n of cstNodes) {
        if (processCommentOrSpace(n, ctx)) {
            continue;
        }
        if (n.type === "doc-end") {
            /* istanbul ignore if */
            if (!bufferDoc) {
                throw ctx.throwUnexpectedTokenError(n);
            }
            bufferDoc.docEnd = n;
            cstDocs.push(bufferDoc);
            bufferDoc = null;
            (_a = n.end) === null || _a === void 0 ? void 0 : _a.forEach((t) => processAnyToken(t, ctx));
            continue;
        }
        if (bufferDoc) {
            cstDocs.push(bufferDoc);
            bufferDoc = null;
        }
        if (n.type === "directive") {
            directives.push(n);
            continue;
        }
        if (n.type === "document") {
            bufferDoc = {
                doc: n,
                directives,
            };
            directives = [];
            continue;
        }
        /* istanbul ignore next */
        throw ctx.throwUnexpectedTokenError(n);
    }
    if (bufferDoc) {
        cstDocs.push(bufferDoc);
        bufferDoc = null;
    }
    if (cstDocs.length > 0) {
        let startIndex = 0;
        ast.body = cstDocs.map((doc, index) => {
            const result = convertDocument(doc, nodes[index], ctx, ast, startIndex);
            startIndex = result.range[1];
            return result;
        });
    }
    else {
        const index = skipSpaces(ctx.code, 0);
        ast.body.push(Object.assign({ type: "YAMLDocument", directives: [], content: null, parent: ast, anchors: {}, version: docs.streamInfo.directives.yaml.version }, ctx.getConvertLocation(index, index)));
    }
    sort(ctx.comments);
    sort(ctx.tokens);
    const lastBody = ast.body[ast.body.length - 1];
    if (lastBody) {
        adjustEndLoc(lastBody, ctx.comments[ctx.comments.length - 1]);
    }
    return ast;
}
exports.convertRoot = convertRoot;
/**
 * Convert YAML.Document to YAMLDocument
 */
function convertDocument({ directives, doc, docEnd }, node, ctx, parent, startIndex) {
    const loc = ctx.getConvertLocation(skipSpaces(ctx.code, startIndex), node.range[1]);
    const ast = Object.assign({ type: "YAMLDocument", directives: [], content: null, parent, anchors: {}, version: node.directives.yaml.version }, loc);
    ast.directives.push(...convertDocumentHead(node.directives, directives, ctx, ast));
    let last = ast.directives[ast.directives.length - 1];
    const startTokens = new PreTokens(doc.start, ctx);
    let t;
    while ((t = startTokens.consume())) {
        if (t.type === "doc-start") {
            last = ctx.addToken("Marker", toRange(t));
            continue;
        }
        startTokens.back();
        break;
    }
    ast.content = convertDocumentBody(startTokens, doc.value || null, node.contents, ctx, ast);
    last = ast.content || last;
    if (doc.end) {
        doc.end.forEach((token) => processAnyToken(token, ctx));
    }
    // Marker
    if (docEnd) {
        last = ctx.addToken("Marker", toRange(docEnd));
    }
    adjustEndLoc(ast, last);
    return ast;
}
/**
 * Convert YAML.Document.Parsed to YAMLDirective[]
 */
function* convertDocumentHead(node, directives, ctx, parent) {
    for (const n of directives) {
        yield convertDirective(node, n, ctx, parent);
    }
}
/**
 * Convert CSTDirective to YAMLDirective
 */
function convertDirective(node, cst, ctx, parent) {
    const loc = ctx.getConvertLocation(...toRange(cst));
    const value = ctx.code.slice(...loc.range);
    const parts = cst.source.trim().split(/[\t ]+/);
    const name = parts.shift();
    let ast;
    if (name === "%YAML") {
        ast = Object.assign({ type: "YAMLDirective", value, kind: "YAML", version: node.yaml.version, parent }, loc);
    }
    else if (name === "%TAG") {
        const [handle, prefix] = parts;
        ast = Object.assign({ type: "YAMLDirective", value, kind: "TAG", handle,
            prefix,
            parent }, loc);
    }
    else {
        ast = Object.assign({ type: "YAMLDirective", value, kind: null, parent }, loc);
    }
    ctx.addToken("Directive", loc.range);
    return ast;
}
/**
 * Convert Document body to YAMLContent
 */
function convertDocumentBody(preTokens, cst, node, ctx, parent) {
    if (cst) {
        return convertContentNode(preTokens, cst, node, ctx, parent, parent);
    }
    const token = preTokens.first();
    /* istanbul ignore if */
    if (token) {
        throw ctx.throwUnexpectedTokenError(token);
    }
    return null;
}
/* eslint-disable complexity -- X */
/**
 * Convert ContentNode to YAMLContent
 */
function convertContentNode(
/* eslint-enable complexity -- X */
preTokens, cst, node, ctx, parent, doc) {
    var _a;
    /* istanbul ignore if */
    if (!node) {
        throw ctx.throwError(`unknown error: AST is null. Unable to process content CST (${cst.type}).`, cst);
    }
    /* istanbul ignore if */
    if (node.srcToken !== cst) {
        throw ctx.throwError(`unknown error: CST is mismatched. Unable to process content CST (${cst.type}: ${(_a = node.srcToken) === null || _a === void 0 ? void 0 : _a.type}).`, cst);
    }
    if (cst.type === "block-scalar") {
        /* istanbul ignore if */
        if (!(0, yaml_1.isScalar)(node)) {
            throw ctx.throwError(`unknown error: AST is not Scalar (${getNodeType(node)}). Unable to process Scalar CST.`, cst);
        }
        return convertBlockScalar(preTokens, cst, node, ctx, parent, doc);
    }
    if (cst.type === "block-seq") {
        /* istanbul ignore if */
        if (!(0, yaml_1.isSeq)(node)) {
            throw ctx.throwError(`unknown error: AST is not Seq (${getNodeType(node)}). Unable to process Seq CST.`, cst);
        }
        return convertSequence(preTokens, cst, node, ctx, parent, doc);
    }
    if (cst.type === "block-map") {
        /* istanbul ignore if */
        if (!(0, yaml_1.isMap)(node)) {
            throw ctx.throwError(`unknown error: AST is not Map and Pair (${getNodeType(node)}). Unable to process Map CST.`, cst);
        }
        return convertMapping(preTokens, cst, node, ctx, parent, doc);
    }
    if (cst.type === "flow-collection") {
        return convertFlowCollection(preTokens, cst, node, ctx, parent, doc);
    }
    if (isPlainScalarCST(cst)) {
        /* istanbul ignore if */
        if (!(0, yaml_1.isScalar)(node)) {
            throw ctx.throwError(`unknown error: AST is not Scalar (${getNodeType(node)}). Unable to process Scalar CST.`, cst);
        }
        return convertPlain(preTokens, cst, node, ctx, parent, doc);
    }
    if (isDoubleQuotedScalarCST(cst)) {
        /* istanbul ignore if */
        if (!(0, yaml_1.isScalar)(node)) {
            throw ctx.throwError(`unknown error: AST is not Scalar (${getNodeType(node)}). Unable to process Scalar CST.`, cst);
        }
        return convertQuoteDouble(preTokens, cst, node, ctx, parent, doc);
    }
    if (isSingleQuotedScalarCST(cst)) {
        /* istanbul ignore if */
        if (!(0, yaml_1.isScalar)(node)) {
            throw ctx.throwError(`unknown error: AST is not Scalar (${getNodeType(node)}). Unable to process Scalar CST.`, cst);
        }
        return convertQuoteSingle(preTokens, cst, node, ctx, parent, doc);
    }
    if (isAliasScalarCST(cst)) {
        /* istanbul ignore if */
        if (!(0, yaml_1.isAlias)(node)) {
            throw ctx.throwError(`unknown error: AST is not Alias (${getNodeType(node)}). Unable to process Alias CST.`, cst);
        }
        return convertAlias(preTokens, cst, node, ctx, parent, doc);
    }
    /* istanbul ignore next */
    throw new Error(`Unsupported node: ${cst.type}`);
}
/* eslint-disable complexity -- X */
/**
 * Convert Map to YAMLBlockMapping
 */
function convertMapping(
/* eslint-enable complexity -- X */
preTokens, cst, node, ctx, parent, doc) {
    var _a, _b;
    if (isPair(node)) {
        /* istanbul ignore if */
        if (node.srcToken !== cst.items[0]) {
            throw ctx.throwError(`unknown error: CST is mismatched. Unable to process mapping CST (${cst.type}: "CollectionItem").`, cst);
        }
    }
    else {
        /* istanbul ignore if */
        if (node.srcToken !== cst) {
            throw ctx.throwError(`unknown error: CST is mismatched. Unable to process mapping CST (${cst.type}: ${(_a = node.srcToken) === null || _a === void 0 ? void 0 : _a.type}).`, cst);
        }
    }
    const loc = ctx.getConvertLocation(cst.offset, cst.offset);
    const ast = Object.assign({ type: "YAMLMapping", style: "block", pairs: [], parent }, loc);
    const items = getPairs(node);
    let firstKeyInd;
    let lastKeyInd;
    for (const item of cst.items) {
        const startTokens = new PreTokens(item.start, ctx);
        let token;
        let keyInd = null;
        while ((token = startTokens.consume())) {
            if (token.type === "explicit-key-ind") {
                /* istanbul ignore if */
                if (keyInd) {
                    throw ctx.throwUnexpectedTokenError(token);
                }
                lastKeyInd = keyInd = ctx.addToken("Punctuator", toRange(token));
                firstKeyInd !== null && firstKeyInd !== void 0 ? firstKeyInd : (firstKeyInd = keyInd);
                continue;
            }
            startTokens.back();
            break;
        }
        const pair = items.shift();
        if (!pair) {
            const t = startTokens.first() ||
                keyInd ||
                item.key ||
                ((_b = item.sep) === null || _b === void 0 ? void 0 : _b[0]) ||
                item.value;
            if (!t) {
                // trailing spaces
                break;
            }
            /* istanbul ignore next */
            throw ctx.throwUnexpectedTokenError(t);
        }
        ast.pairs.push(convertMappingItem(keyInd, startTokens, item, pair, ctx, ast, doc));
    }
    adjustStartLoc(ast, firstKeyInd);
    adjustStartLoc(ast, ast.pairs[0]);
    adjustEndLoc(ast, ast.pairs[ast.pairs.length - 1] || lastKeyInd);
    if (!(0, yaml_1.isMap)(node)) {
        return ast;
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
}
/**
 * Convert FlowCollection to YAMLFlowMapping
 */
function convertFlowCollection(preTokens, cst, node, ctx, parent, doc) {
    if (cst.start.type === "flow-map-start") {
        const startToken = ctx.addToken("Punctuator", toRange(cst.start));
        /* istanbul ignore if */
        if (!(0, yaml_1.isMap)(node) && !isPair(node)) {
            throw ctx.throwError(`unknown error: AST is not Map and Pair (${getNodeType(node)}). Unable to process flow map CST.`, cst);
        }
        return convertFlowMapping(preTokens, startToken, cst, node, ctx, parent, doc);
    }
    if (cst.start.type === "flow-seq-start") {
        const startToken = ctx.addToken("Punctuator", toRange(cst.start));
        /* istanbul ignore if */
        if (!(0, yaml_1.isSeq)(node) || !node.flow) {
            throw ctx.throwError(`unknown error: AST is not flow Seq (${getNodeType(node)}). Unable to process flow seq CST.`, cst);
        }
        return convertFlowSequence(preTokens, startToken, cst, node, ctx, parent, doc);
    }
    /* istanbul ignore next */
    throw ctx.throwUnexpectedTokenError(cst.start);
}
/* eslint-disable complexity -- X */
/**
 * Convert FlowMap to YAMLFlowMapping
 */
function convertFlowMapping(
/* eslint-enable complexity -- X */
preTokens, startToken, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(startToken.range[0], cst.offset);
    const ast = Object.assign({ type: "YAMLMapping", style: "flow", pairs: [], parent }, loc);
    const items = getPairs(node);
    let lastToken;
    for (const item of cst.items) {
        const startTokens = new PreTokens(item.start, ctx);
        let token;
        let keyInd = null;
        while ((token = startTokens.consume())) {
            if (token.type === "comma") {
                lastToken = ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            if (token.type === "explicit-key-ind") {
                /* istanbul ignore if */
                if (keyInd) {
                    throw ctx.throwUnexpectedTokenError(token);
                }
                lastToken = keyInd = ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            startTokens.back();
            break;
        }
        const pair = items.shift();
        if (!pair) {
            const t = startTokens.first() ||
                keyInd ||
                item.key ||
                ((_a = item.sep) === null || _a === void 0 ? void 0 : _a[0]) ||
                item.value;
            if (!t) {
                // trailing spaces
                break;
            }
            /* istanbul ignore next */
            throw ctx.throwUnexpectedTokenError(t);
        }
        ast.pairs.push(convertMappingItem(keyInd, startTokens, item, pair, ctx, ast, doc));
    }
    let mapEnd;
    for (const token of cst.end) {
        if (processCommentOrSpace(token, ctx)) {
            continue;
        }
        if (token.type === "flow-map-end") {
            mapEnd = ctx.addToken("Punctuator", toRange(token));
            continue;
        }
        /* istanbul ignore next */
        throw ctx.throwUnexpectedTokenError(token);
    }
    adjustEndLoc(ast, mapEnd || ast.pairs[ast.pairs.length - 1] || lastToken);
    if (!(0, yaml_1.isMap)(node)) {
        return ast;
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
}
/* eslint-disable complexity -- X */
/**
 * Convert FlowSeq to YAMLFlowSequence
 */
function convertFlowSequence(
/* eslint-enable complexity -- X */
preTokens, startToken, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(startToken.range[0], cst.offset);
    const ast = Object.assign({ type: "YAMLSequence", style: "flow", entries: [], parent }, loc);
    let lastToken;
    const items = [...node.items];
    for (const item of cst.items) {
        const startTokens = new PreTokens(item.start, ctx);
        let token;
        while ((token = startTokens.consume())) {
            if (token.type === "comma") {
                lastToken = ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            startTokens.back();
            break;
        }
        if (items.length === 0) {
            const t = startTokens.first() || item.key || ((_a = item.sep) === null || _a === void 0 ? void 0 : _a[0]) || item.value;
            if (!t) {
                // trailing spaces or comma
                break;
            }
            /* istanbul ignore next */
            throw ctx.throwUnexpectedTokenError(t);
        }
        const entry = items.shift();
        if (isPair(entry) || ((item.key || item.sep) && (0, yaml_1.isMap)(entry))) {
            ast.entries.push(convertMap(startTokens, item, entry));
        }
        else {
            ast.entries.push(convertFlowSequenceItem(startTokens, item.value || null, entry || null, ctx, ast, doc, (ast.entries[ast.entries.length - 1] || lastToken || startToken)
                .range[1]));
        }
    }
    let seqEnd;
    for (const token of cst.end) {
        if (processCommentOrSpace(token, ctx)) {
            continue;
        }
        if (token.type === "flow-seq-end") {
            seqEnd = ctx.addToken("Punctuator", toRange(token));
            continue;
        }
        /* istanbul ignore next */
        throw ctx.throwUnexpectedTokenError(token);
    }
    adjustEndLoc(ast, seqEnd || ast.entries[ast.entries.length - 1] || lastToken);
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
    /** Convert CollectionItem to YAMLBlockMapping */
    function convertMap(pairPreTokens, pairCst, entry) {
        var _a, _b, _c;
        const startTokens = pairPreTokens;
        let keyInd = null;
        let token;
        while ((token = startTokens.consume())) {
            if (token.type === "comma") {
                ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            if (token.type === "explicit-key-ind") {
                /* istanbul ignore if */
                if (keyInd) {
                    throw ctx.throwUnexpectedTokenError(token);
                }
                keyInd = ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            startTokens.back();
            break;
        }
        const pairStartToken = (_a = pairCst.key) !== null && _a !== void 0 ? _a : pairCst.sep[0];
        const mapAst = Object.assign({ type: "YAMLMapping", style: "block", pairs: [], parent: ast }, ctx.getConvertLocation((_b = keyInd === null || keyInd === void 0 ? void 0 : keyInd.range[0]) !== null && _b !== void 0 ? _b : pairStartToken.offset, (_c = keyInd === null || keyInd === void 0 ? void 0 : keyInd.range[1]) !== null && _c !== void 0 ? _c : pairStartToken.offset));
        const pair = convertMappingItem(keyInd, startTokens, pairCst, getPairs(entry)[0], ctx, mapAst, doc);
        mapAst.pairs.push(pair);
        adjustStartLoc(mapAst, keyInd || pair);
        adjustEndLoc(mapAst, pair || keyInd);
        return mapAst;
    }
}
/**
 * Convert Pair to YAMLPair
 */
function convertMappingItem(keyInd, preTokens, cst, node, ctx, parent, doc) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    const start = (_k = (_h = (_e = (_c = (_a = keyInd === null || keyInd === void 0 ? void 0 : keyInd.range[0]) !== null && _a !== void 0 ? _a : (_b = preTokens.first()) === null || _b === void 0 ? void 0 : _b.offset) !== null && _c !== void 0 ? _c : (_d = cst.key) === null || _d === void 0 ? void 0 : _d.offset) !== null && _e !== void 0 ? _e : (_g = (_f = cst.sep) === null || _f === void 0 ? void 0 : _f[0]) === null || _g === void 0 ? void 0 : _g.offset) !== null && _h !== void 0 ? _h : (_j = cst.value) === null || _j === void 0 ? void 0 : _j.offset) !== null && _k !== void 0 ? _k : -1;
    const loc = ctx.getConvertLocation(start, start);
    const ast = Object.assign({ type: "YAMLPair", key: null, value: null, parent }, loc);
    ast.key = convertMappingKey(preTokens, cst.key || null, node.key, ctx, ast, doc, start);
    const valueStartTokens = new PreTokens(cst.sep || [], ctx);
    let valueInd;
    let token;
    while ((token = valueStartTokens.consume())) {
        if (token.type === "map-value-ind") {
            /* istanbul ignore if */
            if (valueInd) {
                throw ctx.throwUnexpectedTokenError(token);
            }
            valueInd = ctx.addToken("Punctuator", toRange(token));
            continue;
        }
        valueStartTokens.back();
        break;
    }
    ast.value = convertMappingValue(valueStartTokens, cst.value || null, node.value, ctx, ast, doc, start);
    adjustEndLoc(ast, ast.value || valueInd || ast.key || keyInd);
    return ast;
}
/**
 * Convert MapKey to YAMLContent
 */
function convertMappingKey(preTokens, cst, node, ctx, parent, doc, indexForError) {
    var _a;
    if (cst) {
        return convertContentNode(preTokens, cst, node, ctx, parent, doc);
    }
    /* istanbul ignore if */
    if (!isScalarOrNull(node)) {
        throw ctx.throwError(`unknown error: AST is not Scalar and null (${getNodeType(node)}). Unable to process empty map key CST.`, (_a = preTokens.first()) !== null && _a !== void 0 ? _a : indexForError);
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, null, doc, null);
}
/**
 * Convert MapValue to YAMLContent
 */
function convertMappingValue(preTokens, cst, node, ctx, parent, doc, indexForError) {
    var _a;
    if (cst) {
        return convertContentNode(preTokens, cst, node, ctx, parent, doc);
    }
    /* istanbul ignore if */
    if (!isScalarOrNull(node)) {
        throw ctx.throwError(`unknown error: AST is not Scalar and null (${getNodeType(node)}). Unable to process empty map value CST.`, (_a = preTokens.first()) !== null && _a !== void 0 ? _a : indexForError);
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, null, doc, null);
}
/**
 * Convert BlockSeq to YAMLBlockSequence
 */
function convertSequence(preTokens, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(cst.offset, cst.offset);
    const ast = Object.assign({ type: "YAMLSequence", style: "block", entries: [], parent }, loc);
    const items = [...node.items];
    let lastSeqInd;
    for (const item of cst.items) {
        const startTokens = new PreTokens(item.start, ctx);
        let seqInd;
        let token;
        while ((token = startTokens.consume())) {
            if (token.type === "seq-item-ind") {
                /* istanbul ignore if */
                if (seqInd) {
                    throw ctx.throwUnexpectedTokenError(token);
                }
                lastSeqInd = seqInd = ctx.addToken("Punctuator", toRange(token));
                continue;
            }
            startTokens.back();
            break;
        }
        if (items.length === 0) {
            const t = startTokens.first() || item.key || ((_a = item.sep) === null || _a === void 0 ? void 0 : _a[0]) || item.value;
            if (!t) {
                // trailing spaces or comma
                break;
            }
            /* istanbul ignore next */
            throw ctx.throwUnexpectedTokenError(t);
        }
        ast.entries.push(convertSequenceItem(startTokens, item, items.shift() || null, ctx, ast, doc, (ast.entries[ast.entries.length - 1] || ast).range[1]));
    }
    adjustEndLoc(ast, ast.entries[ast.entries.length - 1] || lastSeqInd);
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
}
/**
 * Convert SeqItem to YAMLContent
 */
function convertSequenceItem(preTokens, cst, node, ctx, parent, doc, indexForError) {
    var _a;
    /* istanbul ignore if */
    if (cst.key) {
        throw ctx.throwUnexpectedTokenError(cst.key);
    }
    /* istanbul ignore if */
    if (cst.sep) {
        throw ctx.throwUnexpectedTokenError(cst.sep);
    }
    if (cst.value) {
        if (isPair(node)) {
            if (cst.value.type === "block-map") {
                return convertMapping(preTokens, cst.value, node, ctx, parent, doc);
            }
            if (cst.value.type === "flow-collection") {
                return convertFlowCollection(preTokens, cst.value, node, ctx, parent, doc);
            }
            throw ctx.throwError(`unknown error: CST is not block-map and flow-collection (${cst.value.type}). Unable to process Pair AST.`, cst.value);
        }
        return convertContentNode(preTokens, cst.value, node, ctx, parent, doc);
    }
    /* istanbul ignore if */
    if (!isScalarOrNull(node)) {
        throw ctx.throwError(`unknown error: AST is not Scalar and null (${getNodeType(node)}). Unable to process empty seq item CST.`, (_a = preTokens.first()) !== null && _a !== void 0 ? _a : indexForError);
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, null, doc, null);
}
/**
 * Convert FlowSeqItem to YAMLContent
 */
function convertFlowSequenceItem(preTokens, cst, node, ctx, parent, doc, indexForError) {
    var _a;
    if (cst) {
        return convertContentNode(preTokens, cst, node, ctx, parent, doc);
    }
    /* istanbul ignore if */
    if (!isScalarOrNull(node)) {
        throw ctx.throwError(`unknown error: AST is not Scalar and null (${getNodeType(node)}). Unable to process empty seq item CST.`, (_a = preTokens.first()) !== null && _a !== void 0 ? _a : indexForError);
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, null, doc, null);
}
/**
 * Convert PlainValue to YAMLPlainScalar
 */
function convertPlain(preTokens, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(...toRange(cst));
    let ast;
    if (loc.range[0] < loc.range[1]) {
        const strValue = node.source || cst.source;
        const value = parseValueFromText(strValue, doc.version || "1.2");
        ast = Object.assign({ type: "YAMLScalar", style: "plain", strValue,
            value, raw: ctx.code.slice(...loc.range), parent }, loc);
        const type = typeof value;
        if (type === "boolean") {
            ctx.addToken("Boolean", loc.range);
        }
        else if (type === "number" && isFinite(Number(value))) {
            ctx.addToken("Numeric", loc.range);
        }
        else if (value === null) {
            ctx.addToken("Null", loc.range);
        }
        else {
            ctx.addToken("Identifier", loc.range);
        }
        ast = convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, loc);
    }
    else {
        ast = convertAnchorAndTag(preTokens, node, ctx, parent, null, doc, loc);
    }
    (_a = cst.end) === null || _a === void 0 ? void 0 : _a.forEach((t) => processAnyToken(t, ctx));
    return ast;
    /**
     * Parse value from text
     */
    function parseValueFromText(str, version) {
        for (const tagResolver of tags_1.tagResolvers[version]) {
            if (tagResolver.testString(str)) {
                return tagResolver.resolveString(str);
            }
        }
        return str;
    }
}
/**
 * Convert QuoteDouble to YAMLDoubleQuotedScalar
 */
function convertQuoteDouble(preTokens, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(...toRange(cst));
    const strValue = node.source;
    const ast = Object.assign({ type: "YAMLScalar", style: "double-quoted", strValue, value: strValue, raw: ctx.code.slice(...loc.range), parent }, loc);
    ctx.addToken("String", loc.range);
    (_a = cst.end) === null || _a === void 0 ? void 0 : _a.forEach((t) => processAnyToken(t, ctx));
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
}
/**
 * Convert QuoteSingle to YAMLSingleQuotedScalar
 */
function convertQuoteSingle(preTokens, cst, node, ctx, parent, doc) {
    var _a;
    const loc = ctx.getConvertLocation(...toRange(cst));
    const strValue = node.source;
    const ast = Object.assign({ type: "YAMLScalar", style: "single-quoted", strValue, value: strValue, raw: ctx.code.slice(...loc.range), parent }, loc);
    ctx.addToken("String", loc.range);
    (_a = cst.end) === null || _a === void 0 ? void 0 : _a.forEach((t) => processAnyToken(t, ctx));
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
}
/**
 * Convert BlockLiteral to YAMLBlockLiteral
 */
function convertBlockScalar(preTokens, cst, node, ctx, parent, doc) {
    let headerToken, ast;
    let blockStart = cst.offset;
    for (const token of cst.props) {
        if (processCommentOrSpace(token, ctx)) {
            blockStart = token.offset + token.source.length;
            continue;
        }
        if (token.type === "block-scalar-header") {
            headerToken = ctx.addToken("Punctuator", toRange(token));
            blockStart = headerToken.range[0];
            continue;
        }
        /* istanbul ignore next */
        throw ctx.throwUnexpectedTokenError(token);
    }
    const headerValue = headerToken.value;
    const end = node.source
        ? getBlockEnd(blockStart + cst.source.length, ctx)
        : ctx.lastSkipSpaces(cst.offset, blockStart + cst.source.length);
    const loc = ctx.getConvertLocation(headerToken.range[0], end);
    if (headerValue.startsWith(">")) {
        ast = Object.assign(Object.assign(Object.assign({ type: "YAMLScalar", style: "folded" }, parseHeader(headerValue)), { value: node.source, parent }), loc);
        const text = ctx.code.slice(blockStart, end);
        const offset = /^[^\S\n\r]*/.exec(text)[0].length;
        const tokenRange = [blockStart + offset, end];
        if (tokenRange[0] < tokenRange[1]) {
            ctx.addToken("BlockFolded", tokenRange);
        }
    }
    else {
        ast = Object.assign(Object.assign(Object.assign({ type: "YAMLScalar", style: "literal" }, parseHeader(headerValue)), { value: node.source, parent }), loc);
        const text = ctx.code.slice(blockStart, end);
        const offset = /^[^\S\n\r]*/.exec(text)[0].length;
        const tokenRange = [blockStart + offset, end];
        if (tokenRange[0] < tokenRange[1]) {
            ctx.addToken("BlockLiteral", tokenRange);
        }
    }
    return convertAnchorAndTag(preTokens, node, ctx, parent, ast, doc, ast);
    /** Get chomping kind */
    function parseHeader(header) {
        const parsed = /([+-]?)(\d*)([+-]?)$/u.exec(header);
        let indent = null;
        let chomping = "clip";
        if (parsed) {
            indent = parsed[2] ? Number(parsed[2]) : null;
            const chompingStr = parsed[3] || parsed[1];
            chomping =
                chompingStr === "+" ? "keep" : chompingStr === "-" ? "strip" : "clip";
        }
        return {
            chomping,
            indent,
        };
    }
}
/**
 * Get the end index from give block end
 */
function getBlockEnd(end, ctx) {
    let index = end;
    if (ctx.code[index - 1] === "\n" && index > 1) {
        index--;
        if (ctx.code[index - 1] === "\r" && index > 1) {
            index--;
        }
    }
    return index;
}
/**
 * Convert Alias to YAMLAlias
 */
function convertAlias(preTokens, cst, _node, ctx, parent, _doc) {
    var _a;
    const [start, end] = toRange(cst);
    const loc = ctx.getConvertLocation(start, ctx.lastSkipSpaces(start, end));
    const ast = Object.assign({ type: "YAMLAlias", name: cst.source.slice(1), parent }, loc);
    ctx.addToken("Punctuator", [loc.range[0], loc.range[0] + 1]);
    const tokenRange = [loc.range[0] + 1, loc.range[1]];
    if (tokenRange[0] < tokenRange[1]) {
        ctx.addToken("Identifier", tokenRange);
    }
    const token = preTokens.first();
    /* istanbul ignore if */
    if (token) {
        throw ctx.throwUnexpectedTokenError(token);
    }
    (_a = cst.end) === null || _a === void 0 ? void 0 : _a.forEach((t) => processAnyToken(t, ctx));
    return ast;
}
/**
 * Convert Anchor and Tag
 */
function convertAnchorAndTag(preTokens, node, ctx, parent, value, doc, valueLoc) {
    let meta = null;
    /**
     * Get YAMLWithMeta
     */
    function getMetaAst(cst) {
        if (meta) {
            return meta;
        }
        meta = Object.assign({ type: "YAMLWithMeta", anchor: null, tag: null, value,
            parent }, (valueLoc
            ? {
                range: [...valueLoc.range],
                loc: cloneLoc(valueLoc.loc),
            }
            : ctx.getConvertLocation(...toRange(cst))));
        if (value) {
            value.parent = meta;
        }
        return meta;
    }
    preTokens.each((cst) => {
        var _a;
        if (isAnchorCST(cst)) {
            const ast = getMetaAst(cst);
            const anchor = convertAnchor(cst, ctx, ast, doc);
            ast.anchor = anchor;
            adjustStartLoc(ast, anchor);
            adjustEndLoc(ast, anchor);
        }
        else if (isTagCST(cst)) {
            const ast = getMetaAst(cst);
            const tag = convertTag(cst, (_a = node === null || node === void 0 ? void 0 : node.tag) !== null && _a !== void 0 ? _a : null, ctx, ast);
            ast.tag = tag;
            adjustStartLoc(ast, tag);
            adjustEndLoc(ast, tag);
        }
        else {
            /* istanbul ignore next */
            throw ctx.throwUnexpectedTokenError(cst);
        }
    });
    return meta || value;
}
/**
 * Convert anchor to YAMLAnchor
 */
function convertAnchor(cst, ctx, parent, doc) {
    const name = cst.source.slice(1);
    const loc = ctx.getConvertLocation(...toRange(cst));
    const ast = Object.assign({ type: "YAMLAnchor", name,
        parent }, loc);
    const anchors = doc.anchors[name] || (doc.anchors[name] = []);
    anchors.push(ast);
    const punctuatorRange = [loc.range[0], loc.range[0] + 1];
    ctx.addToken("Punctuator", punctuatorRange);
    const tokenRange = [punctuatorRange[1], loc.range[1]];
    if (tokenRange[0] < tokenRange[1]) {
        ctx.addToken("Identifier", tokenRange);
    }
    return ast;
}
/**
 * Convert tag to YAMLTag
 */
function convertTag(cst, tag, ctx, parent) {
    const offset = cst.source.startsWith("!!") ? 2 : 1;
    let resolvedTag = tag !== null && tag !== void 0 ? tag : cst.source.slice(offset);
    if (resolvedTag === "!") {
        resolvedTag = "tag:yaml.org,2002:str";
    }
    const loc = ctx.getConvertLocation(...toRange(cst));
    const ast = Object.assign({ type: "YAMLTag", tag: resolvedTag, raw: cst.source, parent }, loc);
    const punctuatorRange = [loc.range[0], loc.range[0] + offset];
    ctx.addToken("Punctuator", punctuatorRange);
    const tokenRange = [punctuatorRange[1], loc.range[1]];
    if (tokenRange[0] < tokenRange[1]) {
        ctx.addToken("Identifier", tokenRange);
    }
    return ast;
}
/** Checks whether the give node is scaler or null */
function isScalarOrNull(node) {
    return (0, yaml_1.isScalar)(node) || node == null;
}
/** Get the pairs from the give node */
function getPairs(node) {
    return (0, yaml_1.isMap)(node) ? [...node.items] : [node];
}
/**
 * Process comments or spaces
 */
function processCommentOrSpace(node, ctx) {
    if (node.type === "space" || node.type === "newline") {
        return true;
    }
    /* istanbul ignore if */
    if (node.type === "flow-error-end" || node.type === "error") {
        throw ctx.throwUnexpectedTokenError(node);
    }
    if (node.type === "comment") {
        const comment = Object.assign({ type: "Block", value: node.source.slice(1) }, ctx.getConvertLocation(...toRange(node)));
        ctx.addComment(comment);
        return true;
    }
    return false;
}
/**
 * Process any token
 */
function processAnyToken(node, ctx) {
    /* istanbul ignore if */
    if (!processCommentOrSpace(node, ctx)) {
        throw ctx.throwUnexpectedTokenError(node);
    }
}
/**
 * Sort tokens
 */
function sort(tokens) {
    return tokens.sort((a, b) => {
        if (a.range[0] > b.range[0]) {
            return 1;
        }
        if (a.range[0] < b.range[0]) {
            return -1;
        }
        if (a.range[1] > b.range[1]) {
            return 1;
        }
        if (a.range[1] < b.range[1]) {
            return -1;
        }
        return 0;
    });
}
/**
 * clone the location.
 */
function clonePos(loc) {
    return {
        line: loc.line,
        column: loc.column,
    };
}
/**
 * clone the location.
 */
function cloneLoc(loc) {
    return {
        start: clonePos(loc.start),
        end: clonePos(loc.end),
    };
}
/**
 * Gets the first index with whitespace skipped.
 */
function skipSpaces(str, startIndex) {
    const len = str.length;
    for (let index = startIndex; index < len; index++) {
        if (str[index].trim()) {
            return index;
        }
    }
    return len;
}
/** SourceToken to location range */
function toRange(token) {
    return [token.offset, token.offset + token.source.length];
}
/** Adjust start location */
function adjustStartLoc(ast, first) {
    if (first && first.range[0] < ast.range[0]) {
        // adjust location
        ast.range[0] = first.range[0];
        ast.loc.start = clonePos(first.loc.start);
    }
}
/** Adjust end location */
function adjustEndLoc(ast, last) {
    if (last && ast.range[1] < last.range[1]) {
        // adjust location
        ast.range[1] = last.range[1];
        ast.loc.end = clonePos(last.loc.end);
    }
}
