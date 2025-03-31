import { ComponentValue } from '@csstools/css-parser-algorithms';
import { MediaFeatureName } from './media-feature-name';
import { NodeType } from '../util/node-type';
import { CSSToken } from '@csstools/css-tokenizer';
export declare class MediaFeatureBoolean {
    type: NodeType;
    name: MediaFeatureName;
    constructor(name: MediaFeatureName);
    getName(): string;
    getNameToken(): CSSToken;
    tokens(): Array<CSSToken>;
    toString(): string;
    indexOf(item: MediaFeatureName): number | string;
    at(index: number | string): MediaFeatureName | undefined;
    toJSON(): {
        type: NodeType;
        name: {
            type: NodeType;
            name: string;
            tokens: CSSToken[];
        };
        tokens: CSSToken[];
    };
    isMediaFeatureBoolean(): this is MediaFeatureBoolean;
    static isMediaFeatureBoolean(x: unknown): x is MediaFeatureBoolean;
}
export declare function parseMediaFeatureBoolean(componentValues: Array<ComponentValue>): false | MediaFeatureBoolean;
