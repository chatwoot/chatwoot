import type { JSONNode, JSONExpression, JSONNumberIdentifier, JSONIdentifier, JSONObjectExpression, JSONArrayExpression, JSONUnaryExpression, JSONNumberLiteral, JSONExpressionStatement, JSONProgram, JSONUndefinedIdentifier, JSONTemplateLiteral, JSONTemplateElement, JSONStringLiteral, JSONKeywordLiteral, JSONRegExpLiteral, JSONBigIntLiteral, JSONLiteral, JSONBinaryExpression } from "../parser/ast";
export declare function isExpression<N extends JSONNode>(node: N): node is N & JSONExpression;
export declare function isNumberIdentifier(node: JSONIdentifier): node is JSONNumberIdentifier;
export declare function isUndefinedIdentifier(node: JSONIdentifier): node is JSONUndefinedIdentifier;
export type JSONValue = string | number | boolean | null | undefined | JSONObjectValue | JSONValue[] | RegExp | bigint;
export type JSONObjectValue = {
    [key: string]: JSONValue;
};
export declare function getStaticJSONValue(node: JSONUnaryExpression | JSONNumberIdentifier | JSONNumberLiteral | JSONBinaryExpression): number;
export declare function getStaticJSONValue(node: JSONUndefinedIdentifier): undefined;
export declare function getStaticJSONValue(node: JSONTemplateLiteral | JSONTemplateElement | JSONStringLiteral): string;
export declare function getStaticJSONValue(node: JSONKeywordLiteral): boolean | null;
export declare function getStaticJSONValue(node: JSONRegExpLiteral): RegExp;
export declare function getStaticJSONValue(node: JSONBigIntLiteral): bigint;
export declare function getStaticJSONValue(node: JSONLiteral): string | number | boolean | RegExp | bigint | null;
export declare function getStaticJSONValue(node: Exclude<JSONExpression, JSONObjectExpression | JSONArrayExpression>): Exclude<JSONValue, JSONObjectValue | JSONValue[]>;
export declare function getStaticJSONValue(node: JSONObjectExpression): JSONObjectValue;
export declare function getStaticJSONValue(node: JSONArrayExpression): JSONValue[];
export declare function getStaticJSONValue(node: JSONExpression | JSONExpressionStatement | JSONProgram | JSONNode): JSONValue;
