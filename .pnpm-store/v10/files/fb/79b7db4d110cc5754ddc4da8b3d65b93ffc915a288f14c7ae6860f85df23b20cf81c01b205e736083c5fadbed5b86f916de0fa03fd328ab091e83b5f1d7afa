"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isComma = exports.TokenStore = void 0;
class TokenStore {
    constructor(tokens) {
        this.tokens = tokens;
    }
    add(token) {
        this.tokens.push(token);
    }
    findIndexByOffset(offset) {
        return this.tokens.findIndex((token) => token.range[0] <= offset && offset < token.range[1]);
    }
    findTokenByOffset(offset) {
        return this.tokens[this.findIndexByOffset(offset)];
    }
    getFirstToken(nodeOrToken) {
        return this.findTokenByOffset(nodeOrToken.range[0]);
    }
    getLastToken(nodeOrToken) {
        return this.findTokenByOffset(nodeOrToken.range[1] - 1);
    }
    getTokenBefore(nodeOrToken, filter) {
        const tokenIndex = this.findIndexByOffset(nodeOrToken.range[0]);
        for (let index = tokenIndex - 1; index >= 0; index--) {
            const token = this.tokens[index];
            if (!filter || filter(token)) {
                return token;
            }
        }
        return null;
    }
    getTokenAfter(nodeOrToken, filter) {
        const tokenIndex = this.findIndexByOffset(nodeOrToken.range[0]);
        for (let index = tokenIndex + 1; index < this.tokens.length; index++) {
            const token = this.tokens[index];
            if (!filter || filter(token)) {
                return token;
            }
        }
        return null;
    }
}
exports.TokenStore = TokenStore;
function isComma(token) {
    return token.type === "Punctuator" && token.value === ",";
}
exports.isComma = isComma;
