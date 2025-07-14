import { CSSToken, ParseError } from '@csstools/css-tokenizer';
import { CustomMedia } from '../nodes/custom-media';
export type Options = {
    preserveInvalidMediaQueries?: boolean;
    onParseError?: (error: ParseError) => void;
};
export declare function parseCustomMediaFromTokens(tokens: Array<CSSToken>, options?: Options): CustomMedia | false;
export declare function parseCustomMedia(source: string, options?: Options): CustomMedia | false;
