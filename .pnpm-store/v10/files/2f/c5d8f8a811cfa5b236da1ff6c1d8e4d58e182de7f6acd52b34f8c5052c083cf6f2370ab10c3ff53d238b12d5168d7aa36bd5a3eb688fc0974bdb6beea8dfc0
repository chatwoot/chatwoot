import { CSSToken } from '@csstools/css-tokenizer';
import { MediaInParens, MediaInParensWalkerEntry, MediaInParensWalkerParent } from './media-in-parens';
import { NodeType } from '../util/node-type';
export declare class MediaAnd {
    type: NodeType;
    modifier: Array<CSSToken>;
    media: MediaInParens;
    constructor(modifier: Array<CSSToken>, media: MediaInParens);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaInParens): number | string;
    at(index: number | string): MediaInParens | null;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaAndWalkerEntry;
        parent: MediaAndWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isMediaAnd(): this is MediaAnd;
    static isMediaAnd(x: unknown): x is MediaAnd;
}
export type MediaAndWalkerEntry = MediaInParensWalkerEntry | MediaInParens;
export type MediaAndWalkerParent = MediaInParensWalkerParent | MediaAnd;
