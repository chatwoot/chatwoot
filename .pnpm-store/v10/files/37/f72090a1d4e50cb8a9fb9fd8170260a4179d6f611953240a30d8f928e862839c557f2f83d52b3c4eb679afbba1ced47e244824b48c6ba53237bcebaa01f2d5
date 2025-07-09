import type { Comment, Node } from "estree";
import type { TokenStore, MaybeNodeOrToken } from "./token-store";
import type { JSONNode } from "./ast";
export declare class ParseError extends SyntaxError {
    index: number;
    lineNumber: number;
    column: number;
    constructor(message: string, offset: number, line: number, column: number);
}
export declare function throwExpectedTokenError(name: string, beforeToken: MaybeNodeOrToken): never;
export declare function throwUnexpectedError(name: string, token: MaybeNodeOrToken): never;
export declare function throwUnexpectedTokenError(name: string, token: MaybeNodeOrToken): never;
export declare function throwUnexpectedCommentError(token: Comment): never;
export declare function throwUnexpectedSpaceError(beforeToken: MaybeNodeOrToken): never;
export declare function throwInvalidNumberError(text: string, token: MaybeNodeOrToken): never;
export declare function throwUnexpectedNodeError(node: Node | JSONNode, tokens: TokenStore, offset?: number): never;
