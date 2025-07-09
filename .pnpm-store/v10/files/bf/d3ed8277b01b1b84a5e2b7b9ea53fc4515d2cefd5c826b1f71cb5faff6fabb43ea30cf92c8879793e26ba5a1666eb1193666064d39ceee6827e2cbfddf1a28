import type { VisitorKeys } from "eslint-visitor-keys";
import type { JSONNode } from "./ast";
export declare function getFallbackKeys(node: JSONNode): string[];
export declare function getKeys(node: JSONNode, visitorKeys?: VisitorKeys): string[];
export declare function getNodes(node: any, key: string): IterableIterator<JSONNode>;
export interface Visitor<N> {
    visitorKeys?: VisitorKeys;
    enterNode(node: N, parent: N | null): void;
    leaveNode(node: N, parent: N | null): void;
}
export declare function traverseNodes(node: JSONNode, visitor: Visitor<JSONNode>): void;
