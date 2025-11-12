import { type Node as PMNode, MarkType, NodeType } from 'prosemirror-model';
import type { Attrs } from './types';
type FindChildrenAttrsPredicate = (attrs: Attrs) => boolean;
type FindNodesResult = Array<{
    node: PMNode;
    pos: number;
}>;
type FindChildrenPredicate = (node: PMNode) => boolean;
export declare const flatten: (node: PMNode, descend?: boolean) => FindNodesResult;
export declare const findChildren: (node: PMNode, predicate: FindChildrenPredicate, descend?: boolean) => FindNodesResult;
export declare const findTextNodes: (node: PMNode, descend?: boolean) => FindNodesResult;
export declare const findInlineNodes: (node: PMNode, descend?: boolean) => FindNodesResult;
export declare const findBlockNodes: (node: PMNode, descend?: boolean) => FindNodesResult;
export declare const findChildrenByAttr: (node: PMNode, predicate: FindChildrenAttrsPredicate, descend?: boolean) => FindNodesResult;
export declare const findChildrenByType: (node: PMNode, nodeType: NodeType, descend?: boolean) => FindNodesResult;
export declare const findChildrenByMark: (node: PMNode, markType: MarkType, descend?: boolean) => FindNodesResult;
export declare const contains: (node: PMNode, nodeType: NodeType) => boolean;
export {};
