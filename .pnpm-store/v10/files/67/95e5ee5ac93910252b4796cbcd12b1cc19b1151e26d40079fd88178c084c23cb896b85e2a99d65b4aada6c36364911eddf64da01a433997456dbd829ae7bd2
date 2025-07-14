import type { Node as PMNode, NodeType, Fragment } from 'prosemirror-model';
export type NodeWithPos = {
    pos: number;
    node: PMNode;
};
export type ContentNodeWithPos = {
    start: number;
    depth: number;
} & NodeWithPos;
export type DomAtPos = (pos: number) => {
    node: Node;
    offset: number;
};
export type FindPredicate = (node: PMNode) => boolean;
export type Predicate = FindPredicate;
export type FindResult = ContentNodeWithPos | undefined;
export type Attrs = {
    [key: string]: unknown;
};
export type NodeTypeParam = NodeType | Array<NodeType>;
export type Content = PMNode | Fragment;
