"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Context = void 0;
const lodash_1 = __importDefault(require("lodash"));
const _1 = require(".");
const options_1 = require("./options");
class Context {
    constructor(origCode, parserOptions) {
        this.tokens = [];
        this.comments = [];
        this.locsMap = new Map();
        this.options = (0, options_1.parserOptionsToYAMLOption)(parserOptions);
        const len = origCode.length;
        const lineStartIndices = [0];
        for (let index = 0; index < len;) {
            const c = origCode[index++];
            if (c === "\r") {
                const next = origCode[index];
                if (next === "\n") {
                    index++;
                }
                lineStartIndices.push(index);
            }
            else if (c === "\n") {
                lineStartIndices.push(index);
            }
        }
        this.code = origCode;
        this.locs = new LinesAndColumns(lineStartIndices);
    }
    getLocFromIndex(index) {
        let loc = this.locsMap.get(index);
        if (!loc) {
            loc = this.locs.getLocFromIndex(index);
            this.locsMap.set(index, loc);
        }
        return {
            line: loc.line,
            column: loc.column,
        };
    }
    /**
     * Get the location information of the given range.
     */
    getConvertLocation(start, end) {
        return {
            range: [start, end],
            loc: {
                start: this.getLocFromIndex(start),
                end: this.getLocFromIndex(end),
            },
        };
    }
    addComment(comment) {
        this.comments.push(comment);
    }
    /**
     * Add token to tokens
     */
    addToken(type, range) {
        const token = Object.assign({ type, value: this.code.slice(...range) }, this.getConvertLocation(...range));
        this.tokens.push(token);
        return token;
    }
    /* istanbul ignore next */
    throwUnexpectedTokenError(cst) {
        const token = "source" in cst ? `'${cst.source}'` : cst.type;
        throw this.throwError(`Unexpected token: ${token}`, cst);
    }
    throwError(message, cst) {
        const offset = typeof cst === "number"
            ? cst
            : "offset" in cst
                ? cst.offset
                : cst.range[0];
        const loc = this.getLocFromIndex(offset);
        throw new _1.ParseError(message, offset, loc.line, loc.column);
    }
    /**
     * Gets the last index with whitespace skipped.
     */
    lastSkipSpaces(startIndex, endIndex) {
        const str = this.code;
        for (let index = endIndex - 1; index >= startIndex; index--) {
            if (str[index].trim()) {
                return index + 1;
            }
        }
        return startIndex;
    }
}
exports.Context = Context;
class LinesAndColumns {
    constructor(lineStartIndices) {
        this.lineStartIndices = lineStartIndices;
    }
    getLocFromIndex(index) {
        const lineNumber = lodash_1.default.sortedLastIndex(this.lineStartIndices, index);
        return {
            line: lineNumber,
            column: index - this.lineStartIndices[lineNumber - 1],
        };
    }
}
