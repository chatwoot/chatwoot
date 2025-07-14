import { CSSToken } from './interfaces/token';
import { ParseError } from './interfaces/error';
interface Stringer {
    valueOf(): string;
}
export declare function tokenize(input: {
    css: Stringer;
}, options?: {
    onParseError?: (error: ParseError) => void;
}): Array<CSSToken>;
export declare function tokenizer(input: {
    css: Stringer;
}, options?: {
    onParseError?: (error: ParseError) => void;
}): {
    nextToken: () => CSSToken | undefined;
    endOfFile: () => boolean;
};
export {};
