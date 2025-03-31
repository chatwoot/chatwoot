import { CSSToken, TokenDimension, TokenNumber, TokenPercentage } from '@csstools/css-tokenizer';
export declare function isNumeric(x: CSSToken): x is TokenDimension | TokenPercentage | TokenNumber;
export declare function isDimensionOrNumber(x: CSSToken): x is TokenDimension | TokenNumber;
export declare function arrayOfSameNumeric<T extends TokenDimension | TokenPercentage | TokenNumber>(x: Array<CSSToken>): x is Array<T>;
export declare function twoOfSameNumeric<T extends TokenDimension | TokenPercentage | TokenNumber>(x: T, y: CSSToken): y is T;
