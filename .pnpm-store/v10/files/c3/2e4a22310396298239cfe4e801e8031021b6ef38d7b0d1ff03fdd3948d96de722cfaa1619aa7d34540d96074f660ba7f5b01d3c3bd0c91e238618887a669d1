"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parse = void 0;
const lodash_1 = require("lodash");
const utils_1 = require("./utils");
function parse(code) {
    const errors = [];
    const ast = parseAST(code, errors);
    return {
        ast,
        errors
    };
}
exports.parse = parse;
class CodeContext {
    constructor(code) {
        this.code = code;
        this.buff = code;
        this.offset = 0;
        this.lines = [];
        this.lineStartIndices = [0];
        const lineEndingPattern = /\r\n|[\r\n\u2028\u2029]/gu;
        let match;
        while ((match = lineEndingPattern.exec(this.code))) {
            this.lines.push(this.code.slice(this.lineStartIndices[this.lineStartIndices.length - 1], match.index));
            this.lineStartIndices.push(match.index + match[0].length);
        }
        this.lines.push(this.code.slice(this.lineStartIndices[this.lineStartIndices.length - 1]));
    }
    setOffset(offset) {
        this.offset = offset;
        this.buff = this.code.slice(offset);
    }
    getLocFromIndex(index) {
        if (index === this.code.length) {
            return {
                line: this.lines.length,
                column: this.lines[this.lines.length - 1].length + 1
            };
        }
        const lineNumber = (0, lodash_1.sortedLastIndex)(this.lineStartIndices, index);
        return {
            line: lineNumber,
            column: index - this.lineStartIndices[lineNumber - 1] + 1
        };
    }
    getNodeLoc(start, end) {
        const startLoc = this.getLocFromIndex(start);
        const endLoc = this.getLocFromIndex(end);
        return {
            start,
            end,
            loc: {
                start: Object.assign(Object.assign({}, startLoc), { offset: start }),
                end: Object.assign(Object.assign({}, endLoc), { offset: end })
            }
        };
    }
    setEndLoc(node, end) {
        const endLoc = this.getLocFromIndex(end);
        node.end = end;
        node.loc.end = Object.assign(Object.assign({}, endLoc), { offset: end });
    }
    createCompileError(message, offset) {
        const loc = this.getLocFromIndex(offset);
        const error = new SyntaxError(message);
        error.code = 42;
        error.location = {
            start: Object.assign(Object.assign({}, loc), { offset }),
            end: Object.assign(Object.assign({}, loc), { offset })
        };
        error.domain = 'parser';
        return error;
    }
}
function parseAST(code, errors) {
    const ctx = new CodeContext(code);
    const regexp = /%?\{|@[\.:]|\s*\|\s*/u;
    let re;
    const node = Object.assign({ type: utils_1.NodeTypes.Resource, body: undefined }, ctx.getNodeLoc(0, code.length));
    let messageNode = Object.assign({ type: utils_1.NodeTypes.Message, items: [] }, ctx.getNodeLoc(0, code.length));
    let body = messageNode;
    while ((re = regexp.exec(ctx.buff))) {
        const key = re[0];
        const startOffset = ctx.offset + re.index;
        const endOffset = startOffset + key.length;
        if (ctx.offset < startOffset) {
            const textNode = Object.assign({ type: utils_1.NodeTypes.Text, value: ctx.code.slice(ctx.offset, startOffset) }, ctx.getNodeLoc(ctx.offset, startOffset));
            messageNode.items.push(textNode);
        }
        if (key.trim() === '|') {
            ctx.setEndLoc(messageNode, startOffset);
            if (body.type === utils_1.NodeTypes.Message) {
                const pluralNode = {
                    type: utils_1.NodeTypes.Plural,
                    cases: [body],
                    start: body.start,
                    end: body.end,
                    loc: {
                        start: Object.assign({}, body.loc.start),
                        end: Object.assign({}, body.loc.end)
                    }
                };
                body = pluralNode;
            }
            messageNode = Object.assign({ type: utils_1.NodeTypes.Message, items: [] }, ctx.getNodeLoc(endOffset, endOffset));
            body.cases.push(messageNode);
            ctx.setOffset(endOffset);
            continue;
        }
        if (key === '{' || key === '%{') {
            const endIndex = ctx.code.indexOf('}', endOffset);
            let keyValue;
            if (endIndex > -1) {
                keyValue = ctx.code.slice(endOffset, endIndex);
            }
            else {
                errors.push(ctx.createCompileError('Unterminated closing brace', endOffset));
                keyValue = ctx.code.slice(endOffset);
            }
            const placeholderEndOffset = endOffset + keyValue.length + 1;
            let node = null;
            const trimmedKeyValue = keyValue.trim();
            if (trimmedKeyValue) {
                if (trimmedKeyValue !== keyValue) {
                    errors.push(ctx.createCompileError('Unexpected space before or after the placeholder key', endOffset));
                }
                if (/^-?\d+$/u.test(trimmedKeyValue)) {
                    const num = Number(trimmedKeyValue);
                    const listNode = Object.assign({ type: utils_1.NodeTypes.List, index: num }, ctx.getNodeLoc(endOffset - 1, placeholderEndOffset));
                    if (num < 0) {
                        errors.push(ctx.createCompileError('Unexpected minus placeholder index', endOffset));
                    }
                    node = listNode;
                }
                if (!node) {
                    const namedNode = Object.assign({ type: utils_1.NodeTypes.Named, key: trimmedKeyValue }, ctx.getNodeLoc(endOffset - 1, placeholderEndOffset));
                    if (key === '%{') {
                        namedNode.modulo = true;
                    }
                    if (!/^[a-zA-Z][a-zA-Z0-9_$]*$/.test(namedNode.key)) {
                        errors.push(ctx.createCompileError('Unexpected placeholder key', endOffset));
                    }
                    node = namedNode;
                }
                messageNode.items.push(node);
            }
            else {
                errors.push(ctx.createCompileError('Empty placeholder', placeholderEndOffset - 1));
            }
            ctx.setOffset(placeholderEndOffset);
            continue;
        }
        if (key[0] === '@') {
            ctx.setOffset(endOffset);
            messageNode.items.push(parseLiked(ctx, errors));
            continue;
        }
    }
    if (ctx.buff) {
        const textNode = Object.assign({ type: utils_1.NodeTypes.Text, value: ctx.buff }, ctx.getNodeLoc(ctx.offset, code.length));
        messageNode.items.push(textNode);
    }
    ctx.setEndLoc(messageNode, code.length);
    ctx.setEndLoc(body, code.length);
    node.body = body;
    return node;
}
function parseLiked(ctx, errors) {
    const linked = Object.assign({ type: utils_1.NodeTypes.Linked, key: undefined }, ctx.getNodeLoc(ctx.offset - 2, ctx.offset));
    const mark = ctx.code[ctx.offset - 1];
    if (mark === '.') {
        const modifierValue = /^[a-z]*/u.exec(ctx.buff)[0];
        const modifierEndOffset = ctx.offset + modifierValue.length;
        const modifier = Object.assign({ type: utils_1.NodeTypes.LinkedModifier, value: modifierValue }, ctx.getNodeLoc(ctx.offset - 1, modifierEndOffset));
        if (!modifier.value) {
            errors.push(ctx.createCompileError('Expected linked modifier value', modifier.loc.start.offset));
        }
        ctx.setOffset(modifierEndOffset);
        linked.modifier = modifier;
        if (ctx.code[ctx.offset] !== ':') {
            errors.push(ctx.createCompileError('Expected linked key value', ctx.offset));
            const key = Object.assign({ type: utils_1.NodeTypes.LinkedKey, value: '' }, ctx.getNodeLoc(ctx.offset, ctx.offset));
            linked.key = key;
            ctx.setEndLoc(linked, ctx.offset);
            return linked;
        }
        ctx.setOffset(ctx.offset + 1);
    }
    let paren = false;
    if (ctx.buff[0] === '(') {
        ctx.setOffset(ctx.offset + 1);
        paren = true;
    }
    const keyValue = /^[\w\-_|.]*/u.exec(ctx.buff)[0];
    const keyEndOffset = ctx.offset + keyValue.length;
    const key = Object.assign({ type: utils_1.NodeTypes.LinkedKey, value: keyValue }, ctx.getNodeLoc(ctx.offset, keyEndOffset));
    if (!key.value) {
        errors.push(ctx.createCompileError('Expected linked key value', key.loc.start.offset));
    }
    linked.key = key;
    ctx.setOffset(keyEndOffset);
    if (paren) {
        if (ctx.buff[0] === ')') {
            ctx.setOffset(ctx.offset + 1);
        }
        else {
            errors.push(ctx.createCompileError('Unterminated closing paren', ctx.offset));
        }
    }
    ctx.setEndLoc(linked, ctx.offset);
    return linked;
}
