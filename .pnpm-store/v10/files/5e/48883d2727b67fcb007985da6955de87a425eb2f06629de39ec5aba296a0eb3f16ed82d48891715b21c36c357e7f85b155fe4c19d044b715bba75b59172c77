import { CSSToken } from '@csstools/css-tokenizer';
export declare class LayerName {
    parts: Array<CSSToken>;
    constructor(parts: Array<CSSToken>);
    tokens(): Array<CSSToken>;
    slice(start: number, end: number): LayerName;
    concat(other: LayerName): LayerName;
    segments(): Array<string>;
    name(): string;
    equal(other: LayerName): boolean;
    toString(): string;
    toJSON(): {
        parts: CSSToken[];
        segments: string[];
        name: string;
    };
}
