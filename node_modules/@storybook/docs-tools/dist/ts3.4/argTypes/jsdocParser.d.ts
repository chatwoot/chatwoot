export interface ExtractedJsDocParam {
    name: string;
    type?: any;
    description?: string;
    getPrettyName: () => string;
    getTypeName: () => string;
}
export interface ExtractedJsDocReturns {
    type?: any;
    description?: string;
    getTypeName: () => string;
}
export interface ExtractedJsDoc {
    params?: ExtractedJsDocParam[];
    returns?: ExtractedJsDocReturns;
    ignore: boolean;
}
export interface JsDocParsingOptions {
    tags?: string[];
}
export interface JsDocParsingResult {
    includesJsDoc: boolean;
    ignore: boolean;
    description?: string;
    extractedTags?: ExtractedJsDoc;
}
export declare type ParseJsDoc = (value?: string, options?: JsDocParsingOptions) => JsDocParsingResult;
export declare const parseJsDoc: ParseJsDoc;
