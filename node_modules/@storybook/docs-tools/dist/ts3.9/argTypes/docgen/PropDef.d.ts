export interface JsDocParam {
    name: string;
    description?: string;
}
export interface JsDocReturns {
    description?: string;
}
export interface JsDocTags {
    params?: JsDocParam[];
    returns?: JsDocReturns;
}
export interface PropSummaryValue {
    summary: string;
    detail?: string;
}
export declare type PropType = PropSummaryValue;
export declare type PropDefaultValue = PropSummaryValue;
export interface PropDef {
    name: string;
    type: PropType;
    sbType?: any;
    required: boolean;
    description?: string;
    defaultValue?: PropDefaultValue;
    jsDocTags?: JsDocTags;
}
