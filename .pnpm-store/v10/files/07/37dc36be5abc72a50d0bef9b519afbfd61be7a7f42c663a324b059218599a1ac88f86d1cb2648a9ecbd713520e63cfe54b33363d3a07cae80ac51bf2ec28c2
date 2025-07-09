import type { AST } from "jsonc-eslint-parser";
export type JSONSyntax = "JSON" | "JSONC" | "JSON5" | null;
export interface JSONParserOptions {
    jsonSyntax?: JSONSyntax;
}
export type RuleFunction<Node extends AST.JSONNode = never> = (node: Node) => void;
export type BuiltInRuleListeners = {
    [Node in AST.JSONNode as Node["type"]]?: RuleFunction<Node>;
};
export type BuiltInRuleListenerExits = {
    [Node in AST.JSONNode as `${Node["type"]}:exit`]?: RuleFunction<Node>;
};
export interface RuleListener extends BuiltInRuleListeners, BuiltInRuleListenerExits {
    [key: string]: RuleFunction | undefined;
}
