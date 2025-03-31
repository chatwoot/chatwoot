import { ComponentValue } from '@csstools/css-parser-algorithms';
import { TokenDelim } from '@csstools/css-tokenizer';
export declare enum MediaFeatureLT {
    LT = "<",
    LT_OR_EQ = "<="
}
export declare enum MediaFeatureGT {
    GT = ">",
    GT_OR_EQ = ">="
}
export declare enum MediaFeatureEQ {
    EQ = "="
}
export type MediaFeatureComparison = MediaFeatureLT | MediaFeatureGT | MediaFeatureEQ;
export declare function matchesComparison(componentValues: Array<ComponentValue>): false | [number, number];
export declare function comparisonFromTokens(tokens: [TokenDelim, TokenDelim] | [TokenDelim]): MediaFeatureComparison | false;
export declare function invertComparison(operator: MediaFeatureComparison): MediaFeatureComparison | false;
