interface SBBaseType {
    required?: boolean;
    raw?: string;
}
export declare type SBScalarType = SBBaseType & {
    name: 'boolean' | 'string' | 'number' | 'function' | 'symbol';
};
export declare type SBArrayType = SBBaseType & {
    name: 'array';
    value: SBType;
};
export declare type SBObjectType = SBBaseType & {
    name: 'object';
    value: Record<string, SBType>;
};
export declare type SBEnumType = SBBaseType & {
    name: 'enum';
    value: (string | number)[];
};
export declare type SBIntersectionType = SBBaseType & {
    name: 'intersection';
    value: SBType[];
};
export declare type SBUnionType = SBBaseType & {
    name: 'union';
    value: SBType[];
};
export declare type SBOtherType = SBBaseType & {
    name: 'other';
    value: string;
};
export declare type SBType = SBScalarType | SBEnumType | SBArrayType | SBObjectType | SBIntersectionType | SBUnionType | SBOtherType;
export {};
