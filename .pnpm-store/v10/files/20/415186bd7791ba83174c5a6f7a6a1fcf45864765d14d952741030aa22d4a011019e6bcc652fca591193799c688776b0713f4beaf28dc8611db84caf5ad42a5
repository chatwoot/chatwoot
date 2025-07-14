"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAnyTokenErrorParser = exports.getParser = void 0;
const validate_1 = require("./validate");
const acorn_1 = require("./modules/acorn");
const errors_1 = require("./errors");
const convert_1 = require("./convert");
let parserCache;
const PRIVATE = Symbol("ExtendParser#private");
const PRIVATE_PROCESS_NODE = Symbol("ExtendParser#processNode");
function getParser() {
    if (parserCache) {
        return parserCache;
    }
    parserCache = class ExtendParser extends (0, acorn_1.getAcorn)().Parser {
        constructor(options, code, pos) {
            super((() => {
                const tokenConvertor = new convert_1.TokenConvertor(options.ctx, code);
                const onToken = options.onToken ||
                    ((token) => {
                        const t = tokenConvertor.convertToken(token);
                        if (t) {
                            this[PRIVATE].tokenStore.add(t);
                        }
                    });
                return {
                    ecmaVersion: options.ecmaVersion,
                    sourceType: options.sourceType,
                    ranges: true,
                    locations: true,
                    allowReserved: true,
                    onToken,
                    onComment: (block, text, start, end, startLoc, endLoc) => {
                        const comment = {
                            type: block ? "Block" : "Line",
                            value: text,
                            range: [start, end],
                            loc: {
                                start: startLoc,
                                end: endLoc,
                            },
                        };
                        if (!this[PRIVATE].ctx.comments) {
                            throw (0, errors_1.throwUnexpectedCommentError)(comment);
                        }
                        this[PRIVATE].comments.push(comment);
                    },
                };
            })(), code, pos);
            this[PRIVATE] = {
                code,
                ctx: options.ctx,
                tokenStore: options.tokenStore,
                comments: options.comments,
                nodes: options.nodes,
            };
        }
        finishNode(...args) {
            const result = super.finishNode(...args);
            return this[PRIVATE_PROCESS_NODE](result);
        }
        finishNodeAt(...args) {
            const result = super.finishNodeAt(...args);
            return this[PRIVATE_PROCESS_NODE](result);
        }
        [PRIVATE_PROCESS_NODE](node) {
            const { tokenStore, ctx, nodes } = this[PRIVATE];
            (0, validate_1.validateNode)(node, tokenStore, ctx);
            nodes.push(node);
            return node;
        }
        raise(pos, message) {
            const loc = (0, acorn_1.getAcorn)().getLineInfo(this[PRIVATE].code, pos);
            const err = new errors_1.ParseError(message, pos, loc.line, loc.column + 1);
            throw err;
        }
        raiseRecoverable(pos, message) {
            this.raise(pos, message);
        }
        unexpected(pos) {
            if (pos != null) {
                this.raise(pos, "Unexpected token.");
                return;
            }
            const start = this.start;
            const end = this.end;
            const token = this[PRIVATE].code.slice(start, end);
            if (token) {
                const message = `Unexpected token '${token}'.`;
                this.raise(start, message);
            }
            else {
                if (!this[PRIVATE].nodes.length) {
                    this.raise(0, "Expected to be an expression, but got empty.");
                }
                if (this[PRIVATE].tokenStore.tokens.length) {
                    const last = this[PRIVATE].tokenStore.tokens[this[PRIVATE].tokenStore.tokens.length - 1];
                    this.raise(last.range[0], `Unexpected token '${last.value}'.`);
                }
                this.raise(start, "Unexpected token.");
            }
        }
    };
    return parserCache;
}
exports.getParser = getParser;
function getAnyTokenErrorParser() {
    const parser = class ExtendParser extends getParser() {
        constructor(options, code, pos) {
            super(Object.assign(Object.assign({}, options), { onToken: (token) => {
                    return (0, errors_1.throwUnexpectedTokenError)(code.slice(...token.range), token);
                } }), code, pos);
        }
    };
    return parser;
}
exports.getAnyTokenErrorParser = getAnyTokenErrorParser;
