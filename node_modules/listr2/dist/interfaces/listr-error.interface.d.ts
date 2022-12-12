/** The internal error handling mechanism.. */
export declare class ListrError extends Error {
    message: string;
    errors?: Error[];
    context?: any;
    constructor(message: string, errors?: Error[], context?: any);
}
/** The internal error handling mechanism for prompts only. */
export declare class PromptError extends Error {
    constructor(message: string);
}
