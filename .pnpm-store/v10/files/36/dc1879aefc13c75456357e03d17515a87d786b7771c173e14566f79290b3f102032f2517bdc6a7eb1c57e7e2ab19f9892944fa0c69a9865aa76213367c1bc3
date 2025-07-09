import { SimpleBlockNode } from '@csstools/css-parser-algorithms';
import { CSSToken } from '@csstools/css-tokenizer';
import { MediaFeatureBoolean } from './media-feature-boolean';
import { MediaFeaturePlain, MediaFeaturePlainWalkerEntry, MediaFeaturePlainWalkerParent } from './media-feature-plain';
import { MediaFeatureRange, MediaFeatureRangeWalkerEntry, MediaFeatureRangeWalkerParent } from './media-feature-range';
import { NodeType } from '../util/node-type';
export declare class MediaFeature {
    type: NodeType;
    feature: MediaFeaturePlain | MediaFeatureBoolean | MediaFeatureRange;
    before: Array<CSSToken>;
    after: Array<CSSToken>;
    constructor(feature: MediaFeaturePlain | MediaFeatureBoolean | MediaFeatureRange, before?: Array<CSSToken>, after?: Array<CSSToken>);
    getName(): string;
    getNameToken(): CSSToken;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaFeaturePlain | MediaFeatureBoolean | MediaFeatureRange): number | string;
    at(index: number | string): MediaFeatureBoolean | MediaFeaturePlain | MediaFeatureRange | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaFeatureWalkerEntry;
        parent: MediaFeatureWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        feature: {
            type: NodeType;
            name: {
                type: NodeType;
                name: string;
                tokens: CSSToken[];
            };
            tokens: CSSToken[];
        };
        before: CSSToken[];
        after: CSSToken[];
    };
    isMediaFeature(): this is MediaFeature;
    static isMediaFeature(x: unknown): x is MediaFeature;
}
export type MediaFeatureWalkerEntry = MediaFeaturePlainWalkerEntry | MediaFeatureRangeWalkerEntry | MediaFeaturePlain | MediaFeatureBoolean | MediaFeatureRange;
export type MediaFeatureWalkerParent = MediaFeaturePlainWalkerParent | MediaFeatureRangeWalkerParent | MediaFeature;
export declare function parseMediaFeature(simpleBlock: SimpleBlockNode, before?: Array<CSSToken>, after?: Array<CSSToken>): false | MediaFeature;
export declare function newMediaFeatureBoolean(name: string): MediaFeature;
export declare function newMediaFeaturePlain(name: string, ...value: Array<CSSToken>): MediaFeature;
