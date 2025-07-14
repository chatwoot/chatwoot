"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ParseError = void 0;
/**
 * YAML parse errors.
 */
class ParseError extends SyntaxError {
    /**
     * Initialize this ParseError instance.
     * @param message The error message.
     * @param offset The offset number of this error.
     * @param line The line number of this error.
     * @param column The column number of this error.
     */
    constructor(message, offset, line, column) {
        super(message);
        this.index = offset;
        this.lineNumber = line;
        this.column = column;
    }
}
exports.ParseError = ParseError;
