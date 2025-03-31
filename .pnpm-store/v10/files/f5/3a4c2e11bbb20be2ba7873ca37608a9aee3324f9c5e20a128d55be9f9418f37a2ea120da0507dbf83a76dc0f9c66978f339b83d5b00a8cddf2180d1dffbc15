import { ComponentValue } from '@csstools/css-parser-algorithms';
import { CSSToken, TokenColon } from '@csstools/css-tokenizer';
import { MediaFeatureName } from './media-feature-name';
import { MediaFeatureValue, MediaFeatureValueWalkerEntry, MediaFeatureValueWalkerParent } from './media-feature-value';
import { NodeType } from '../util/node-type';
export declare class MediaFeaturePlain {
    type: NodeType;
    name: MediaFeatureName;
    colon: TokenColon;
    value: MediaFeatureValue;
    constructor(name: MediaFeatureName, colon: TokenColon, value: MediaFeatureValue);
    getName(): string;
    getNameToken(): CSSToken;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaFeatureName | MediaFeatureValue): number | string;
    at(index: number | string): MediaFeatureName | MediaFeatureValue | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaFeaturePlainWalkerEntry;
        parent: MediaFeaturePlainWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        name: {
            type: NodeType;
            name: string;
            tokens: CSSToken[];
        };
        value: {
            type: NodeType;
            value: unknown;
            tokens: CSSToken[];
        };
        tokens: CSSToken[];
    };
    isMediaFeaturePlain(): this is MediaFeaturePlain;
    static isMediaFeaturePlain(x: unknown): x is MediaFeaturePlain;
}
export type MediaFeaturePlainWalkerEntry = MediaFeatureValueWalkerEntry | MediaFeatureValue;
export type MediaFeaturePlainWalkerParent = MediaFeatureValueWalkerParent | MediaFeaturePlain;
export declare function parseMediaFeaturePlain(componentValues: Array<ComponentValue>): MediaFeaturePlain | false;
