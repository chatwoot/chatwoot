import { ComponentValue } from '@csstools/css-parser-algorithms';
import { CSSToken } from '@csstools/css-tokenizer';
import { NodeType } from '../util/node-type';
import { MediaCondition, MediaConditionWalkerEntry, MediaConditionWalkerParent } from './media-condition';
export type MediaQuery = MediaQueryWithType | MediaQueryWithoutType | MediaQueryInvalid;
export declare class MediaQueryWithType {
    type: NodeType;
    modifier: Array<CSSToken>;
    mediaType: Array<CSSToken>;
    and: Array<CSSToken> | undefined;
    media: MediaCondition | undefined;
    constructor(modifier: Array<CSSToken>, mediaType: Array<CSSToken>, and?: Array<CSSToken> | undefined, media?: MediaCondition | undefined);
    getModifier(): string;
    negateQuery(): MediaQuery;
    getMediaType(): string;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaCondition): number | string;
    at(index: number | string): MediaCondition | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaQueryWithTypeWalkerEntry;
        parent: MediaQueryWithTypeWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        string: string;
        modifier: CSSToken[];
        mediaType: CSSToken[];
        and: CSSToken[] | undefined;
        media: MediaCondition | undefined;
    };
    isMediaQueryWithType(): this is MediaQueryWithType;
    static isMediaQueryWithType(x: unknown): x is MediaQueryWithType;
}
export type MediaQueryWithTypeWalkerEntry = MediaConditionWalkerEntry | MediaCondition;
export type MediaQueryWithTypeWalkerParent = MediaConditionWalkerParent | MediaQueryWithType;
export declare class MediaQueryWithoutType {
    type: NodeType;
    media: MediaCondition;
    constructor(media: MediaCondition);
    negateQuery(): MediaQuery;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaCondition): number | string;
    at(index: number | string): MediaCondition | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaQueryWithoutTypeWalkerEntry;
        parent: MediaQueryWithoutTypeWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        string: string;
        media: MediaCondition;
    };
    isMediaQueryWithoutType(): this is MediaQueryWithoutType;
    static isMediaQueryWithoutType(x: unknown): x is MediaQueryWithoutType;
}
export type MediaQueryWithoutTypeWalkerEntry = MediaConditionWalkerEntry | MediaCondition;
export type MediaQueryWithoutTypeWalkerParent = MediaConditionWalkerParent | MediaQueryWithoutType;
export declare class MediaQueryInvalid {
    type: NodeType;
    media: Array<ComponentValue>;
    constructor(media: Array<ComponentValue>);
    negateQuery(): MediaQuery;
    tokens(): Array<CSSToken>;
    toString(): string;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaQueryInvalidWalkerEntry;
        parent: MediaQueryInvalidWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        string: string;
        media: ComponentValue[];
    };
    isMediaQueryInvalid(): this is MediaQueryInvalid;
    static isMediaQueryInvalid(x: unknown): x is MediaQueryInvalid;
}
export type MediaQueryInvalidWalkerEntry = ComponentValue;
export type MediaQueryInvalidWalkerParent = ComponentValue | MediaQueryInvalid;
