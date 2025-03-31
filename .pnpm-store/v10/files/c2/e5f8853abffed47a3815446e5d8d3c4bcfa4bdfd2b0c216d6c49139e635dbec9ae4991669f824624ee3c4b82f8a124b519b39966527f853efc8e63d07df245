import { CSSToken } from '@csstools/css-tokenizer';
import { MediaAnd, MediaAndWalkerEntry, MediaAndWalkerParent } from './media-and';
import { MediaInParens } from './media-in-parens';
import { MediaOr, MediaOrWalkerEntry, MediaOrWalkerParent } from './media-or';
import { NodeType } from '../util/node-type';
export type MediaConditionList = MediaConditionListWithAnd | MediaConditionListWithOr;
export declare class MediaConditionListWithAnd {
    type: NodeType;
    leading: MediaInParens;
    list: Array<MediaAnd>;
    before: Array<CSSToken>;
    after: Array<CSSToken>;
    constructor(leading: MediaInParens, list: Array<MediaAnd>, before?: Array<CSSToken>, after?: Array<CSSToken>);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaInParens | MediaAnd): number | string;
    at(index: number | string): MediaInParens | MediaAnd | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaConditionListWithAndWalkerEntry;
        parent: MediaConditionListWithAndWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isMediaConditionListWithAnd(): this is MediaConditionListWithAnd;
    static isMediaConditionListWithAnd(x: unknown): x is MediaConditionListWithAnd;
}
export type MediaConditionListWithAndWalkerEntry = MediaAndWalkerEntry | MediaAnd;
export type MediaConditionListWithAndWalkerParent = MediaAndWalkerParent | MediaConditionListWithAnd;
export declare class MediaConditionListWithOr {
    type: NodeType;
    leading: MediaInParens;
    list: Array<MediaOr>;
    before: Array<CSSToken>;
    after: Array<CSSToken>;
    constructor(leading: MediaInParens, list: Array<MediaOr>, before?: Array<CSSToken>, after?: Array<CSSToken>);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaInParens | MediaOr): number | string;
    at(index: number | string): MediaInParens | MediaOr | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaConditionListWithOrWalkerEntry;
        parent: MediaConditionListWithOrWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isMediaConditionListWithOr(): this is MediaConditionListWithOr;
    static isMediaConditionListWithOr(x: unknown): x is MediaConditionListWithOr;
}
export type MediaConditionListWithOrWalkerEntry = MediaOrWalkerEntry | MediaOr;
export type MediaConditionListWithOrWalkerParent = MediaOrWalkerParent | MediaConditionListWithOr;
