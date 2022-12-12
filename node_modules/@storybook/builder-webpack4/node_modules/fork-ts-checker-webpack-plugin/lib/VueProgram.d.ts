import * as ts from 'typescript';
import { FilesRegister } from './FilesRegister';
import { ResolveModuleName, ResolveTypeReferenceDirective } from './resolution';
import { VueOptions } from './types/vue-options';
interface ResolvedScript {
    scriptKind: ts.ScriptKind;
    content: string;
}
export declare class VueProgram {
    static loadProgramConfig(typescript: typeof ts, configFile: string, compilerOptions: object): ts.ParsedCommandLine;
    /**
     * Search for default wildcard or wildcard from options, we only search for that in tsconfig CompilerOptions.paths.
     * The path is resolved with thie given substitution and includes the CompilerOptions.baseUrl (if given).
     * If no paths given in tsconfig, then the default substitution is '[tsconfig directory]/src'.
     * (This is a fast, simplified inspiration of what's described here: https://github.com/Microsoft/TypeScript/issues/5039)
     */
    static resolveNonTsModuleName(moduleName: string, containingFile: string, basedir: string, options: ts.CompilerOptions): string;
    static isVue(filePath: string): boolean;
    static createProgram(typescript: typeof ts, programConfig: ts.ParsedCommandLine, basedir: string, files: FilesRegister, oldProgram: ts.Program | undefined, userResolveModuleName: ResolveModuleName | undefined, userResolveTypeReferenceDirective: ResolveTypeReferenceDirective | undefined, vueOptions: VueOptions): ts.Program;
    private static getScriptKindByLang;
    static resolveScriptBlock(typescript: typeof ts, content: string, compiler: string): ResolvedScript;
}
export {};
