import { CSSToken } from '@csstools/css-tokenizer';
import { MediaConditionListWithAnd, MediaConditionListWithAndWalkerEntry, MediaConditionListWithAndWalkerParent, MediaConditionListWithOr, MediaConditionListWithOrWalkerEntry, MediaConditionListWithOrWalkerParent } from './media-condition-list';
import { MediaInParens } from './media-in-parens';
import { MediaNot, MediaNotWalkerEntry, MediaNotWalkerParent } from './media-not';
import { NodeType } from '../util/node-type';
export declare class MediaCondition {
    type: NodeType;
    media: MediaNot | MediaInParens | MediaConditionListWithAnd | MediaConditionListWithOr;
    constructor(media: MediaNot | MediaInParens | MediaConditionListWithAnd | MediaConditionListWithOr);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaNot | MediaInParens | MediaConditionListWithAnd | MediaConditionListWithOr): number | string;
    at(index: number | string): MediaNot | MediaInParens | MediaConditionListWithAnd | MediaConditionListWithOr | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaConditionWalkerEntry;
        parent: MediaConditionWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): unknown;
    isMediaCondition(): this is MediaCondition;
    static isMediaCondition(x: unknown): x is MediaCondition;
}
export type MediaConditionWalkerEntry = MediaNotWalkerEntry | MediaConditionListWithAndWalkerEntry | MediaConditionListWithOrWalkerEntry | MediaNot | MediaConditionListWithAnd | MediaConditionListWithOr;
export type MediaConditionWalkerParent = MediaNotWalkerParent | MediaConditionListWithAndWalkerParent | MediaConditionListWithOrWalkerParent | MediaCondition;
