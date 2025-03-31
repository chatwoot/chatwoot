"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parse = void 0;
const message_compiler_1 = require("@intlify/message-compiler");
function parse(code) {
    const errors = [];
    const parser = (0, message_compiler_1.createParser)({
        onError(error) {
            errors.push(error);
        }
    });
    const ast = parser.parse(code);
    return {
        ast,
        errors
    };
}
exports.parse = parse;
