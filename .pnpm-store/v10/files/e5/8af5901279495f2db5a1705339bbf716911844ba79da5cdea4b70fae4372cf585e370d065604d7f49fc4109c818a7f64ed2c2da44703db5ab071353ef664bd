import type { YAMLVersion } from "./utils";
export type Range = [number, number];
export interface Locations {
    loc: SourceLocation;
    range: Range;
}
interface BaseYAMLNode extends Locations {
    type: string;
}
export interface SourceLocation {
    start: Position;
    end: Position;
}
export interface Token extends BaseYAMLNode {
    type: "Directive" | "Marker" | "Punctuator" | "Identifier" | "String" | "Boolean" | "Numeric" | "Null" | "BlockLiteral" | "BlockFolded";
    value: string;
}
export interface Comment extends BaseYAMLNode {
    type: "Line" | "Block";
    value: string;
}
export interface Position {
    /** >= 1 */
    line: number;
    /** >= 0 */
    column: number;
}
export type YAMLNode = YAMLProgram | YAMLDocument | YAMLDirective | YAMLContent | YAMLPair | YAMLWithMeta | YAMLAnchor | YAMLTag;
export interface YAMLProgram extends BaseYAMLNode {
    type: "Program";
    body: YAMLDocument[];
    sourceType: "module";
    comments: Comment[];
    tokens: Token[];
    parent: null;
}
export interface YAMLDocument extends BaseYAMLNode {
    type: "YAMLDocument";
    directives: YAMLDirective[];
    content: YAMLContent | YAMLWithMeta | null;
    parent: YAMLProgram;
    anchors: {
        [key: string]: YAMLAnchor[];
    };
    version: YAMLVersion;
}
interface BaseYAMLDirective extends BaseYAMLNode {
    type: "YAMLDirective";
    value: string;
    kind: "YAML" | "TAG" | null;
    parent: YAMLDocument;
}
export interface YAMLDirectiveForYAML extends BaseYAMLDirective {
    kind: "YAML";
    version: string;
}
export interface YAMLDirectiveForTAG extends BaseYAMLDirective {
    kind: "TAG";
    handle: string;
    prefix: string;
}
export interface YAMLDirectiveForUnknown extends BaseYAMLDirective {
    kind: null;
}
export type YAMLDirective = YAMLDirectiveForYAML | YAMLDirectiveForTAG | YAMLDirectiveForUnknown;
export interface YAMLWithMeta extends BaseYAMLNode {
    type: "YAMLWithMeta";
    anchor: YAMLAnchor | null;
    tag: YAMLTag | null;
    value: Exclude<YAMLContent, YAMLAlias> | null;
    parent: YAMLDocument | YAMLPair | YAMLSequence;
}
export interface YAMLAnchor extends BaseYAMLNode {
    type: "YAMLAnchor";
    name: string;
    parent: YAMLWithMeta;
}
export interface YAMLTag extends BaseYAMLNode {
    type: "YAMLTag";
    tag: string;
    raw: string;
    parent: YAMLWithMeta;
}
interface BaseYAMLContentNode extends BaseYAMLNode {
    parent: YAMLDocument | YAMLPair | YAMLSequence | YAMLWithMeta;
}
export type YAMLContent = YAMLMapping | YAMLSequence | YAMLScalar | YAMLAlias;
export type YAMLMapping = YAMLBlockMapping | YAMLFlowMapping;
export interface YAMLBlockMapping extends BaseYAMLContentNode {
    type: "YAMLMapping";
    style: "block";
    pairs: YAMLPair[];
}
export interface YAMLFlowMapping extends BaseYAMLContentNode {
    type: "YAMLMapping";
    style: "flow";
    pairs: YAMLPair[];
}
export interface YAMLPair extends BaseYAMLNode {
    type: "YAMLPair";
    key: YAMLContent | YAMLWithMeta | null;
    value: YAMLContent | YAMLWithMeta | null;
    parent: YAMLMapping;
}
export type YAMLSequence = YAMLBlockSequence | YAMLFlowSequence;
export interface YAMLBlockSequence extends BaseYAMLContentNode {
    type: "YAMLSequence";
    style: "block";
    entries: (YAMLContent | YAMLWithMeta | null)[];
}
export interface YAMLFlowSequence extends BaseYAMLContentNode {
    type: "YAMLSequence";
    style: "flow";
    entries: (YAMLContent | YAMLWithMeta)[];
}
export type YAMLScalar = YAMLPlainScalar | YAMLDoubleQuotedScalar | YAMLSingleQuotedScalar | YAMLBlockLiteralScalar | YAMLBlockFoldedScalar;
export interface YAMLPlainScalar extends BaseYAMLContentNode {
    type: "YAMLScalar";
    style: "plain";
    strValue: string;
    value: string | number | boolean | null;
    raw: string;
}
export interface YAMLDoubleQuotedScalar extends BaseYAMLContentNode {
    type: "YAMLScalar";
    style: "double-quoted";
    strValue: string;
    value: string;
    raw: string;
}
export interface YAMLSingleQuotedScalar extends BaseYAMLContentNode {
    type: "YAMLScalar";
    style: "single-quoted";
    strValue: string;
    value: string;
    raw: string;
}
export interface YAMLBlockLiteralScalar extends BaseYAMLContentNode {
    type: "YAMLScalar";
    style: "literal";
    chomping: "clip" | "keep" | "strip";
    indent: null | number;
    value: string;
}
export interface YAMLBlockFoldedScalar extends BaseYAMLContentNode {
    type: "YAMLScalar";
    style: "folded";
    chomping: "clip" | "keep" | "strip";
    indent: null | number;
    value: string;
}
export interface YAMLAlias extends BaseYAMLContentNode {
    type: "YAMLAlias";
    name: string;
}
export {};
