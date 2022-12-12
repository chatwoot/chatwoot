import type { SourceFile } from 'typescript';
import { ASTMaps } from './convert';
import type { Extra } from './parser-options';
import type { TSESTree } from './ts-estree';
export declare function astConverter(ast: SourceFile, extra: Extra, shouldPreserveNodeMaps: boolean): {
    estree: TSESTree.Program;
    astMaps: ASTMaps;
};
//# sourceMappingURL=ast-converter.d.ts.map