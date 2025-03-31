import { ComponentValue, ContainerNode } from '@csstools/css-parser-algorithms';
import { CSSToken } from '@csstools/css-tokenizer';
import { GeneralEnclosed } from './general-enclosed';
import { MediaAnd } from './media-and';
import { MediaCondition } from './media-condition';
import { MediaConditionList } from './media-condition-list';
import { MediaFeature } from './media-feature';
import { MediaFeatureBoolean } from './media-feature-boolean';
import { MediaFeatureName } from './media-feature-name';
import { MediaFeaturePlain } from './media-feature-plain';
import { MediaFeatureRange } from './media-feature-range';
import { MediaFeatureValue } from './media-feature-value';
import { NodeType } from '../util/node-type';
import { MediaNot } from './media-not';
import { MediaOr } from './media-or';
export declare class MediaInParens {
    type: NodeType;
    media: MediaCondition | MediaFeature | GeneralEnclosed;
    before: Array<CSSToken>;
    after: Array<CSSToken>;
    constructor(media: MediaCondition | MediaFeature | GeneralEnclosed, before?: Array<CSSToken>, after?: Array<CSSToken>);
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaCondition | MediaFeature | GeneralEnclosed): number | string;
    at(index: number | string): MediaCondition | MediaFeature | GeneralEnclosed | undefined;
    walk<T extends Record<string, unknown>>(cb: (entry: {
        node: MediaInParensWalkerEntry;
        parent: MediaInParensWalkerParent;
        state?: T;
    }, index: number | string) => boolean | void, state?: T): false | undefined;
    toJSON(): {
        type: NodeType;
        media: unknown;
        before: CSSToken[];
        after: CSSToken[];
    };
    isMediaInParens(): this is MediaInParens;
    static isMediaInParens(x: unknown): x is MediaInParens;
}
export type MediaInParensWalkerEntry = ComponentValue | GeneralEnclosed | MediaAnd | MediaNot | MediaOr | MediaConditionList | MediaCondition | MediaFeatureBoolean | MediaFeatureName | MediaFeaturePlain | MediaFeatureRange | MediaFeatureValue | MediaFeature | GeneralEnclosed | MediaInParens;
export type MediaInParensWalkerParent = ContainerNode | GeneralEnclosed | MediaAnd | MediaNot | MediaOr | MediaConditionList | MediaCondition | MediaFeatureBoolean | MediaFeatureName | MediaFeaturePlain | MediaFeatureRange | MediaFeatureValue | MediaFeature | GeneralEnclosed | MediaInParens;
