import { CSSToken } from '@csstools/css-tokenizer';
import { MediaInParens, MediaInParensWalkerEntry, MediaInParensWalkerParent } from './media-in-parens';
import { NodeType } from '../util/node-type';
export declare class MediaNot {
    type: NodeType;
    modifier: Array<CSSToken>;
    media: MediaInParens;
    constructor(modifier: Array<CSSToken>, media: MediaInParens);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaInParens): number | string;
    at(index: number | string): MediaInParens | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaNotWalkerEntry;
        parent: MediaNotWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        modifier: CSSToken[];
        media: {
            type: NodeType;
            media: unknown;
            before: CSSToken[];
            after: CSSToken[];
        };
    };
    isMediaNot(): this is MediaNot;
    static isMediaNot(x: unknown): x is MediaNot;
}
export type MediaNotWalkerEntry = MediaInParensWalkerEntry | MediaInParens;
export type MediaNotWalkerParent = MediaInParensWalkerParent | MediaNot;
