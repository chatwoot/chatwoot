"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PromptError = exports.ListrError = void 0;
/** The internal error handling mechanism.. */
class ListrError extends Error {
    constructor(message, errors, context) {
        super(message);
        this.message = message;
        this.errors = errors;
        this.context = context;
        this.name = 'ListrError';
    }
}
exports.ListrError = ListrError;
/** The internal error handling mechanism for prompts only. */
class PromptError extends Error {
    constructor(message) {
        super(message);
        this.name = 'PromptError';
    }
}
exports.PromptError = PromptError;
