import type { VisitorKeys } from "eslint-visitor-keys";
import type { YAMLNode } from "./ast";
/**
 * Get the keys of the given node to traverse it.
 * @param node The node to get.
 * @returns The keys to traverse.
 */
export declare function getFallbackKeys(node: any): string[];
/**
 * Get the keys of the given node to traverse it.
 * @param node The node to get.
 * @returns The keys to traverse.
 */
export declare function getKeys(node: any, visitorKeys?: VisitorKeys): string[];
/**
 * Get the nodes of the given node.
 * @param node The node to get.
 */
export declare function getNodes(node: any, key: string): IterableIterator<YAMLNode>;
export interface Visitor<N> {
    visitorKeys?: VisitorKeys;
    enterNode(node: N, parent: N | null): void;
    leaveNode(node: N, parent: N | null): void;
}
export declare function traverseNodes(node: YAMLNode, visitor: Visitor<YAMLNode>): void;
