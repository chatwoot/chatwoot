import type { Node, Identifier } from "estree";
import type { TokenStore } from "./token-store";
import type { JSONIdentifier } from "./ast";
import type { JSONSyntaxContext } from "./syntax-context";
export declare function validateNode(node: Node, tokens: TokenStore, ctx: JSONSyntaxContext): void;
export declare function isStaticValueIdentifier<I extends Identifier | JSONIdentifier>(node: I, ctx: JSONSyntaxContext): node is I & {
    name: "NaN" | "Infinity" | "undefined";
};
