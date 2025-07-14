"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convertProgramNode = exports.TokenConvertor = void 0;
const validate_1 = require("./validate");
const errors_1 = require("./errors");
const acorn_1 = require("./modules/acorn");
class TokenConvertor {
    constructor(ctx, code) {
        this.templateBuffer = [];
        this.ctx = ctx;
        this.code = code;
        this.tokTypes = (0, acorn_1.getAcorn)().tokTypes;
    }
    convertToken(token) {
        const { tokTypes } = this;
        let type, value;
        const additional = {};
        if (token.type === tokTypes.string) {
            type = "String";
            value = this.code.slice(...token.range);
        }
        else if (token.type === tokTypes.num) {
            type = "Numeric";
            value = this.code.slice(...token.range);
        }
        else if (token.type.keyword) {
            if (token.type.keyword === "true" || token.type.keyword === "false") {
                type = "Boolean";
            }
            else if (token.type.keyword === "null") {
                type = "Null";
            }
            else {
                type = "Keyword";
            }
            value = token.value;
        }
        else if (token.type === tokTypes.braceL ||
            token.type === tokTypes.braceR ||
            token.type === tokTypes.bracketL ||
            token.type === tokTypes.bracketR ||
            token.type === tokTypes.colon ||
            token.type === tokTypes.comma ||
            token.type === tokTypes.plusMin) {
            type = "Punctuator";
            value = this.code.slice(...token.range);
        }
        else if (token.type === tokTypes.name) {
            type = "Identifier";
            value = token.value;
        }
        else if (token.type === tokTypes.backQuote) {
            if (this.templateBuffer.length > 0) {
                const first = this.templateBuffer[0];
                this.templateBuffer.length = 0;
                return {
                    type: "Template",
                    value: this.code.slice(first.start, token.end),
                    range: [first.start, token.end],
                    loc: {
                        start: first.loc.start,
                        end: token.loc.end,
                    },
                };
            }
            this.templateBuffer.push(token);
            return null;
        }
        else if (token.type === tokTypes.template) {
            if (this.templateBuffer.length === 0) {
                return (0, errors_1.throwUnexpectedTokenError)(this.code.slice(...token.range), token);
            }
            this.templateBuffer.push(token);
            return null;
        }
        else if (token.type === tokTypes.regexp) {
            const reValue = token.value;
            type = "RegularExpression";
            additional.regex = {
                flags: reValue.flags,
                pattern: reValue.pattern,
            };
            value = `/${reValue.pattern}/${reValue.flags}`;
        }
        else if (this.ctx.parentheses &&
            (token.type === tokTypes.parenL || token.type === tokTypes.parenR)) {
            type = "Punctuator";
            value = this.code.slice(...token.range);
        }
        else if (this.ctx.staticExpressions &&
            (token.type === tokTypes.star ||
                token.type === tokTypes.slash ||
                token.type === tokTypes.modulo ||
                token.type === tokTypes.starstar)) {
            type = "Punctuator";
            value = this.code.slice(...token.range);
        }
        else {
            return (0, errors_1.throwUnexpectedTokenError)(this.code.slice(...token.range), token);
        }
        token.type = type;
        token.value = value;
        for (const k in additional) {
            token[k] = additional[k];
        }
        return token;
    }
}
exports.TokenConvertor = TokenConvertor;
function convertProgramNode(node, tokens, ctx, code) {
    if (node.type !== "JSONObjectExpression" &&
        node.type !== "JSONArrayExpression" &&
        node.type !== "JSONLiteral" &&
        node.type !== "JSONUnaryExpression" &&
        node.type !== "JSONIdentifier" &&
        node.type !== "JSONTemplateLiteral" &&
        node.type !== "JSONBinaryExpression") {
        return (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (node.type === "JSONIdentifier") {
        if (!(0, validate_1.isStaticValueIdentifier)(node, ctx)) {
            return (0, errors_1.throwUnexpectedNodeError)(node, tokens);
        }
    }
    const body = Object.assign(Object.assign({ type: "JSONExpressionStatement", expression: node }, cloneLocation(node)), { parent: null });
    setParent(node, body);
    const end = code.length;
    const endLoc = (0, acorn_1.getAcorn)().getLineInfo(code, end);
    const nn = {
        type: "Program",
        body: [body],
        comments: [],
        tokens: [],
        range: [0, end],
        loc: {
            start: {
                line: 1,
                column: 0,
            },
            end: {
                line: endLoc.line,
                column: endLoc.column,
            },
        },
        parent: null,
    };
    setParent(body, nn);
    return nn;
}
exports.convertProgramNode = convertProgramNode;
function cloneLocation(node) {
    const range = node.range;
    const loc = node.loc;
    return {
        range: [range[0], range[1]],
        loc: {
            start: {
                line: loc.start.line,
                column: loc.start.column,
            },
            end: {
                line: loc.end.line,
                column: loc.end.column,
            },
        },
    };
}
function setParent(prop, parent) {
    prop.parent = parent;
}
