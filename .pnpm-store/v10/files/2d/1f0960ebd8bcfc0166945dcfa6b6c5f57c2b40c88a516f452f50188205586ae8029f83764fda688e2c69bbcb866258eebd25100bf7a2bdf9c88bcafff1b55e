import type { AST as ESLintAST } from "eslint";
import type { Comment } from "estree";
export interface Locations {
    loc: SourceLocation;
    range: [number, number];
}
interface BaseJSONNode extends Locations {
    type: string;
}
export interface SourceLocation {
    start: Position;
    end: Position;
}
export interface Position {
    line: number;
    column: number;
}
export type JSONNode = JSONProgram | JSONExpressionStatement | JSONExpression | JSONProperty | JSONIdentifier | JSONTemplateLiteral | JSONTemplateElement;
export interface JSONProgram extends BaseJSONNode {
    type: "Program";
    body: [JSONExpressionStatement];
    comments: Comment[];
    tokens: ESLintAST.Token[];
    parent: null;
}
export interface JSONExpressionStatement extends BaseJSONNode {
    type: "JSONExpressionStatement";
    expression: JSONExpression;
    parent: JSONProgram;
}
export type JSONExpression = JSONArrayExpression | JSONObjectExpression | JSONLiteral | JSONUnaryExpression | JSONNumberIdentifier | JSONUndefinedIdentifier | JSONTemplateLiteral | JSONBinaryExpression;
export interface JSONArrayExpression extends BaseJSONNode {
    type: "JSONArrayExpression";
    elements: (JSONExpression | null)[];
    parent: JSONArrayExpression | JSONProperty | JSONExpressionStatement;
}
export interface JSONObjectExpression extends BaseJSONNode {
    type: "JSONObjectExpression";
    properties: JSONProperty[];
    parent: JSONArrayExpression | JSONProperty | JSONExpressionStatement;
}
export interface JSONProperty extends BaseJSONNode {
    type: "JSONProperty";
    key: JSONIdentifier | JSONStringLiteral | JSONNumberLiteral;
    value: JSONExpression;
    kind: "init";
    method: false;
    shorthand: false;
    computed: false;
    parent: JSONObjectExpression;
}
export interface JSONIdentifier extends BaseJSONNode {
    type: "JSONIdentifier";
    name: string;
    parent?: JSONArrayExpression | JSONProperty | JSONExpressionStatement | JSONUnaryExpression;
}
export interface JSONNumberIdentifier extends JSONIdentifier {
    name: "Infinity" | "NaN";
}
export interface JSONUndefinedIdentifier extends JSONIdentifier {
    name: "undefined";
}
interface JSONLiteralBase extends BaseJSONNode {
    type: "JSONLiteral";
    raw: string;
    parent?: JSONArrayExpression | JSONProperty | JSONExpressionStatement | JSONUnaryExpression | JSONBinaryExpression;
}
export interface JSONStringLiteral extends JSONLiteralBase {
    value: string;
    regex: null;
    bigint: null;
}
export interface JSONNumberLiteral extends JSONLiteralBase {
    value: number;
    regex: null;
    bigint: null;
}
export interface JSONKeywordLiteral extends JSONLiteralBase {
    value: boolean | null;
    regex: null;
    bigint: null;
}
export interface JSONRegExpLiteral extends JSONLiteralBase {
    value: null;
    regex: {
        pattern: string;
        flags: string;
    };
    bigint: null;
}
export interface JSONBigIntLiteral extends JSONLiteralBase {
    value: null;
    regex: null;
    bigint: string;
}
export type JSONLiteral = JSONStringLiteral | JSONNumberLiteral | JSONKeywordLiteral | JSONRegExpLiteral | JSONBigIntLiteral;
export interface JSONUnaryExpression extends BaseJSONNode {
    type: "JSONUnaryExpression";
    operator: "-" | "+";
    prefix: true;
    argument: JSONNumberLiteral | JSONNumberIdentifier;
    parent: JSONArrayExpression | JSONProperty | JSONExpressionStatement;
}
export interface JSONTemplateLiteral extends BaseJSONNode {
    type: "JSONTemplateLiteral";
    quasis: [JSONTemplateElement];
    expressions: [];
    parent: JSONArrayExpression | JSONProperty | JSONExpressionStatement;
}
export interface JSONTemplateElement extends BaseJSONNode {
    type: "JSONTemplateElement";
    tail: boolean;
    value: {
        cooked: string;
        raw: string;
    };
    parent: JSONTemplateLiteral;
}
export interface JSONBinaryExpression extends BaseJSONNode {
    type: "JSONBinaryExpression";
    operator: "-" | "+" | "*" | "/" | "%" | "**";
    left: JSONNumberLiteral | JSONUnaryExpression | JSONBinaryExpression;
    right: JSONNumberLiteral | JSONUnaryExpression | JSONBinaryExpression;
    parent: JSONArrayExpression | JSONProperty | JSONExpressionStatement | JSONUnaryExpression | JSONBinaryExpression;
}
export {};
