import { CSSToken, TokenFunction } from '@csstools/css-tokenizer';
import { Context } from '../interfaces/context';
import { ComponentValueType } from '../util/component-value-type';
export type ContainerNode = FunctionNode | SimpleBlockNode;
export type ComponentValue = FunctionNode | SimpleBlockNode | WhitespaceNode | CommentNode | TokenNode;
export declare function consumeComponentValue(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    node: ComponentValue;
};
export declare class FunctionNode {
    type: ComponentValueType;
    name: TokenFunction;
    endToken: CSSToken;
    value: Array<ComponentValue>;
    constructor(name: TokenFunction, endToken: CSSToken, value: Array<ComponentValue>);
    getName(): string;
    /**
     * Normalize the current Function:
     * - if the "endToken" is EOF, replace with a ")-token"
     */
    normalize(): void;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: ComponentValue): number | string;
    at(index: number | string): ComponentValue | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: ComponentValue;
        parent: ContainerNode;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isFunctionNode(): this is FunctionNode;
    static isFunctionNode(x: unknown): x is FunctionNode;
}
export declare function consumeFunction(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    node: FunctionNode;
};
export declare class SimpleBlockNode {
    type: ComponentValueType;
    startToken: CSSToken;
    endToken: CSSToken;
    value: Array<ComponentValue>;
    constructor(startToken: CSSToken, endToken: CSSToken, value: Array<ComponentValue>);
    /**
     * Normalize the current Simple Block:
     * - if the "endToken" is EOF, replace with the mirror token of the "startToken"
     */
    normalize(): void;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: ComponentValue): number | string;
    at(index: number | string): ComponentValue | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: ComponentValue;
        parent: ContainerNode;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isSimpleBlockNode(): this is SimpleBlockNode;
    static isSimpleBlockNode(x: unknown): x is SimpleBlockNode;
}
/** https://www.w3.org/TR/css-syntax-3/#consume-simple-block */
export declare function consumeSimpleBlock(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    node: SimpleBlockNode;
};
export declare class WhitespaceNode {
    type: ComponentValueType;
    value: Array<CSSToken>;
    constructor(value: Array<CSSToken>);
    tokens(): Array<CSSToken>;
    toString(): string;
    toJSON(): {
        type: ComponentValueType;
        tokens: CSSToken[];
    };
    isWhitespaceNode(): this is WhitespaceNode;
    static isWhitespaceNode(x: unknown): x is WhitespaceNode;
}
export declare function consumeWhitespace(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    node: WhitespaceNode;
};
export declare class CommentNode {
    type: ComponentValueType;
    value: CSSToken;
    constructor(value: CSSToken);
    tokens(): Array<CSSToken>;
    toString(): string;
    toJSON(): {
        type: ComponentValueType;
        tokens: CSSToken[];
    };
    isCommentNode(): this is CommentNode;
    static isCommentNode(x: unknown): x is CommentNode;
}
export declare function consumeComment(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    node: CommentNode;
};
export declare function consumeAllCommentsAndWhitespace(ctx: Context, tokens: Array<CSSToken>): {
    advance: number;
    nodes: Array<WhitespaceNode | CommentNode>;
};
export declare class TokenNode {
    type: ComponentValueType;
    value: CSSToken;
    constructor(value: CSSToken);
    tokens(): Array<CSSToken>;
    toString(): string;
    toJSON(): {
        type: ComponentValueType;
        tokens: CSSToken[];
    };
    isTokenNode(): this is TokenNode;
    static isTokenNode(x: unknown): x is TokenNode;
}
