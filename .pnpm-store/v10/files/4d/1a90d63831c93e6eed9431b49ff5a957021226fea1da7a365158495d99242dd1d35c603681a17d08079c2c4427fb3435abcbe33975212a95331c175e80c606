"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.throwUnexpectedNodeError = exports.throwInvalidNumberError = exports.throwUnexpectedSpaceError = exports.throwUnexpectedCommentError = exports.throwUnexpectedTokenError = exports.throwUnexpectedError = exports.throwExpectedTokenError = exports.ParseError = void 0;
const utils_1 = require("./utils");
class ParseError extends SyntaxError {
    constructor(message, offset, line, column) {
        super(message);
        this.index = offset;
        this.lineNumber = line;
        this.column = column;
    }
}
exports.ParseError = ParseError;
function throwExpectedTokenError(name, beforeToken) {
    const locs = getLocation(beforeToken);
    const err = new ParseError(`Expected token '${name}'.`, locs.end, locs.loc.end.line, locs.loc.end.column + 1);
    throw err;
}
exports.throwExpectedTokenError = throwExpectedTokenError;
function throwUnexpectedError(name, token) {
    const locs = getLocation(token);
    const err = new ParseError(`Unexpected ${name}.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
    throw err;
}
exports.throwUnexpectedError = throwUnexpectedError;
function throwUnexpectedTokenError(name, token) {
    return throwUnexpectedError(`token '${name}'`, token);
}
exports.throwUnexpectedTokenError = throwUnexpectedTokenError;
function throwUnexpectedCommentError(token) {
    return throwUnexpectedError("comment", token);
}
exports.throwUnexpectedCommentError = throwUnexpectedCommentError;
function throwUnexpectedSpaceError(beforeToken) {
    const locs = getLocation(beforeToken);
    const err = new ParseError("Unexpected whitespace.", locs.end, locs.loc.end.line, locs.loc.end.column + 1);
    throw err;
}
exports.throwUnexpectedSpaceError = throwUnexpectedSpaceError;
function throwInvalidNumberError(text, token) {
    const locs = getLocation(token);
    const err = new ParseError(`Invalid number ${text}.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
    throw err;
}
exports.throwInvalidNumberError = throwInvalidNumberError;
function throwUnexpectedNodeError(node, tokens, offset) {
    if (node.type === "Identifier" || node.type === "JSONIdentifier") {
        const locs = getLocation(node);
        const err = new ParseError(`Unexpected identifier '${node.name}'.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
        throw err;
    }
    if (node.type === "Literal" || node.type === "JSONLiteral") {
        const type = node.bigint
            ? "bigint"
            : (0, utils_1.isRegExpLiteral)(node)
                ? "regex"
                : node.value === null
                    ? "null"
                    : typeof node.value;
        const locs = getLocation(node);
        const err = new ParseError(`Unexpected ${type} literal.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
        throw err;
    }
    if (node.type === "TemplateLiteral" || node.type === "JSONTemplateLiteral") {
        const locs = getLocation(node);
        const err = new ParseError("Unexpected template literal.", locs.start, locs.loc.start.line, locs.loc.start.column + 1);
        throw err;
    }
    if (node.type.endsWith("Expression") && node.type !== "FunctionExpression") {
        const name = node.type
            .replace(/^JSON/u, "")
            .replace(/\B([A-Z])/gu, " $1")
            .toLowerCase();
        const locs = getLocation(node);
        const err = new ParseError(`Unexpected ${name}.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
        throw err;
    }
    const index = node.range[0] + (offset || 0);
    const t = tokens.findTokenByOffset(index);
    const name = (t === null || t === void 0 ? void 0 : t.value) || "unknown";
    const locs = getLocation(t || node);
    const err = new ParseError(`Unexpected token '${name}'.`, locs.start, locs.loc.start.line, locs.loc.start.column + 1);
    throw err;
}
exports.throwUnexpectedNodeError = throwUnexpectedNodeError;
function getLocation(token) {
    var _a, _b, _c, _d;
    const start = (_b = (_a = token.range) === null || _a === void 0 ? void 0 : _a[0]) !== null && _b !== void 0 ? _b : token.start;
    const end = (_d = (_c = token.range) === null || _c === void 0 ? void 0 : _c[1]) !== null && _d !== void 0 ? _d : token.end;
    const loc = token.loc;
    return { start, end, loc };
}
