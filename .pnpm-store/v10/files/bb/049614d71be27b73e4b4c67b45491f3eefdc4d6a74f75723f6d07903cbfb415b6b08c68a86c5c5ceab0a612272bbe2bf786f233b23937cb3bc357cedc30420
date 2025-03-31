export declare enum TokenType {
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#comment-diagram */
    Comment = "comment",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-at-keyword-token */
    AtKeyword = "at-keyword-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-bad-string-token */
    BadString = "bad-string-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-bad-url-token */
    BadURL = "bad-url-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-cdc-token */
    CDC = "CDC-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-cdo-token */
    CDO = "CDO-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-colon-token */
    Colon = "colon-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-comma-token */
    Comma = "comma-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-delim-token */
    Delim = "delim-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-dimension-token */
    Dimension = "dimension-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-eof-token */
    EOF = "EOF-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-function-token */
    Function = "function-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-hash-token */
    Hash = "hash-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-ident-token */
    Ident = "ident-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-percentage-token */
    Number = "number-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-percentage-token */
    Percentage = "percentage-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-semicolon-token */
    Semicolon = "semicolon-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-string-token */
    String = "string-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-url-token */
    URL = "url-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#typedef-whitespace-token */
    Whitespace = "whitespace-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-open-paren */
    OpenParen = "(-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-close-paren */
    CloseParen = ")-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-open-square */
    OpenSquare = "[-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-close-square */
    CloseSquare = "]-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-open-curly */
    OpenCurly = "{-token",
    /** https://www.w3.org/TR/2021/CRD-css-syntax-3-20211224/#tokendef-close-curly */
    CloseCurly = "}-token"
}
export declare enum NumberType {
    Integer = "integer",
    Number = "number"
}
export declare enum HashType {
    Unrestricted = "unrestricted",
    ID = "id"
}
export type TokenAtKeyword = Token<TokenType.AtKeyword, {
    value: string;
}>;
export type TokenBadString = Token<TokenType.BadString, undefined>;
export type TokenBadURL = Token<TokenType.BadURL, undefined>;
export type TokenCDC = Token<TokenType.CDC, undefined>;
export type TokenCDO = Token<TokenType.CDO, undefined>;
export type TokenColon = Token<TokenType.Colon, undefined>;
export type TokenComma = Token<TokenType.Comma, undefined>;
export type TokenComment = Token<TokenType.Comment, undefined>;
export type TokenDelim = Token<TokenType.Delim, {
    value: string;
}>;
export type TokenDimension = Token<TokenType.Dimension, {
    value: number;
    unit: string;
    type: NumberType;
}>;
export type TokenEOF = Token<TokenType.EOF, undefined>;
export type TokenFunction = Token<TokenType.Function, {
    value: string;
}>;
export type TokenHash = Token<TokenType.Hash, {
    value: string;
    type: HashType;
}>;
export type TokenIdent = Token<TokenType.Ident, {
    value: string;
}>;
export type TokenNumber = Token<TokenType.Number, {
    value: number;
    type: NumberType;
}>;
export type TokenPercentage = Token<TokenType.Percentage, {
    value: number;
}>;
export type TokenSemicolon = Token<TokenType.Semicolon, undefined>;
export type TokenString = Token<TokenType.String, {
    value: string;
}>;
export type TokenURL = Token<TokenType.URL, {
    value: string;
}>;
export type TokenWhitespace = Token<TokenType.Whitespace, undefined>;
export type TokenOpenParen = Token<TokenType.OpenParen, undefined>;
export type TokenCloseParen = Token<TokenType.CloseParen, undefined>;
export type TokenOpenSquare = Token<TokenType.OpenSquare, undefined>;
export type TokenCloseSquare = Token<TokenType.CloseSquare, undefined>;
export type TokenOpenCurly = Token<TokenType.OpenCurly, undefined>;
export type TokenCloseCurly = Token<TokenType.CloseCurly, undefined>;
export type CSSToken = TokenAtKeyword | TokenBadString | TokenBadURL | TokenCDC | TokenCDO | TokenColon | TokenComma | TokenComment | TokenDelim | TokenDimension | TokenEOF | TokenFunction | TokenHash | TokenIdent | TokenNumber | TokenPercentage | TokenSemicolon | TokenString | TokenURL | TokenWhitespace | TokenOpenParen | TokenCloseParen | TokenOpenSquare | TokenCloseSquare | TokenOpenCurly | TokenCloseCurly;
export type Token<T extends TokenType, U> = [
    /** The type of token */
    T,
    /** The token representation */
    string,
    /** Start position of representation */
    number,
    /** End position of representation */
    number,
    /** Extra data */
    U
];
export declare function mirrorVariantType(type: TokenType): TokenType | null;
export declare function mirrorVariant(token: CSSToken): CSSToken | null;
export declare function isToken(x: any): x is CSSToken;
