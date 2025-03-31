import { CSSToken, ParseError } from '@csstools/css-tokenizer';
import { LayerName } from '../nodes/layer-name';
export type Options = {
    onParseError?: (error: ParseError) => void;
};
export declare function parseFromTokens(tokens: Array<CSSToken>, options?: Options): LayerName[];
export declare function parse(source: string, options?: Options): LayerName[];
