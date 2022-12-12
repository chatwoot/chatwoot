interface TSBaseType {
    name: string;
    type?: string;
    raw?: string;
    required?: boolean;
}
declare type TSArgType = TSType;
declare type TSCombinationType = TSBaseType & {
    name: 'union' | 'intersection';
    elements: TSType[];
};
declare type TSFuncSigType = TSBaseType & {
    name: 'signature';
    type: 'function';
    signature: {
        arguments: TSArgType[];
        return: TSType;
    };
};
declare type TSObjectSigType = TSBaseType & {
    name: 'signature';
    type: 'object';
    signature: {
        properties: {
            key: string;
            value: TSType;
        }[];
    };
};
declare type TSScalarType = TSBaseType & {
    name: 'any' | 'boolean' | 'number' | 'void' | 'string' | 'symbol';
};
declare type TSArrayType = TSBaseType & {
    name: 'Array';
    elements: TSType[];
};
export declare type TSSigType = TSObjectSigType | TSFuncSigType;
export declare type TSType = TSScalarType | TSCombinationType | TSSigType | TSArrayType;
export {};
