interface FlowBaseType {
    name: string;
    type?: string;
    raw?: string;
    required?: boolean;
}
declare type FlowArgType = FlowType;
declare type FlowCombinationType = FlowBaseType & {
    name: 'union' | 'intersection';
    elements: FlowType[];
};
declare type FlowFuncSigType = FlowBaseType & {
    name: 'signature';
    type: 'function';
    signature: {
        arguments: FlowArgType[];
        return: FlowType;
    };
};
declare type FlowObjectSigType = FlowBaseType & {
    name: 'signature';
    type: 'object';
    signature: {
        properties: {
            key: string;
            value: FlowType;
        }[];
    };
};
declare type FlowScalarType = FlowBaseType & {
    name: 'any' | 'boolean' | 'number' | 'void' | 'string' | 'symbol';
};
export declare type FlowLiteralType = FlowBaseType & {
    name: 'literal';
    value: string;
};
declare type FlowArrayType = FlowBaseType & {
    name: 'Array';
    elements: FlowType[];
};
export declare type FlowSigType = FlowObjectSigType | FlowFuncSigType;
export declare type FlowType = FlowScalarType | FlowLiteralType | FlowCombinationType | FlowSigType | FlowArrayType;
export {};
