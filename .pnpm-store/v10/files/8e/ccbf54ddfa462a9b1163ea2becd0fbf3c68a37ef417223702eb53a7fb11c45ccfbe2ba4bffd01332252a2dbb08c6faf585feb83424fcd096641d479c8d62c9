import type { Comment, Locations, Range, Token } from "./ast";
import type { CST, DocumentOptions } from "yaml";
import { ParseError } from ".";
export declare class Context {
    readonly code: string;
    readonly options: DocumentOptions;
    readonly tokens: Token[];
    readonly comments: Comment[];
    private readonly locs;
    private readonly locsMap;
    constructor(origCode: string, parserOptions: any);
    getLocFromIndex(index: number): {
        line: number;
        column: number;
    };
    /**
     * Get the location information of the given range.
     */
    getConvertLocation(start: number, end: number): Locations;
    addComment(comment: Comment): void;
    /**
     * Add token to tokens
     */
    addToken(type: Token["type"], range: Readonly<Range>): Token;
    throwUnexpectedTokenError(cst: CST.Token | Token): ParseError;
    throwError(message: string, cst: CST.Token | Token | number): ParseError;
    /**
     * Gets the last index with whitespace skipped.
     */
    lastSkipSpaces(startIndex: number, endIndex: number): number;
}
