import type { Node } from "estree";
import type { AST } from "eslint";
import type { JSONNode, JSONProgram } from "./ast";
import type { TokenStore } from "./token-store";
import type { Token as AcornToken } from "acorn";
import type { JSONSyntaxContext } from "./syntax-context";
export declare class TokenConvertor {
    private readonly ctx;
    private readonly code;
    private readonly templateBuffer;
    private readonly tokTypes;
    constructor(ctx: JSONSyntaxContext, code: string);
    convertToken(token: AcornToken): AST.Token | null;
}
export declare function convertProgramNode(node: Node | JSONNode, tokens: TokenStore, ctx: JSONSyntaxContext, code: string): JSONProgram;
