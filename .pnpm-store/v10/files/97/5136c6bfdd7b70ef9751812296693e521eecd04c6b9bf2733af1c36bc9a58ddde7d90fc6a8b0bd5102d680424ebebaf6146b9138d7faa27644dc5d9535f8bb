import { parseForESLint } from "./parser";
import type * as AST from "./ast";
import { traverseNodes } from "./traverse";
import { getStaticYAMLValue } from "./utils";
import { ParseError } from "./errors";
export * as meta from "./meta";
export { name } from "./meta";
export { AST, ParseError };
export { parseForESLint };
export declare const VisitorKeys: import("eslint").SourceCode.VisitorKeys;
export { traverseNodes, getStaticYAMLValue };
/**
 * Parse YAML source code
 */
export declare function parseYAML(code: string, options?: any): AST.YAMLProgram;
