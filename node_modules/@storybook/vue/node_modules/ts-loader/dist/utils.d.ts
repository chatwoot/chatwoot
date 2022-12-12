import { Chalk } from 'chalk';
import type * as typescript from 'typescript';
import { FileLocation, FilePathKey, LoaderOptions, ResolvedModule, ReverseDependencyGraph, TSInstance, WebpackError, WebpackModule } from './interfaces';
/**
 * Take TypeScript errors, parse them and format to webpack errors
 * Optionally adds a file name
 */
export declare function formatErrors(diagnostics: ReadonlyArray<typescript.Diagnostic> | undefined, loaderOptions: LoaderOptions, colors: Chalk, compiler: typeof typescript, merge: {
    file?: string;
    module?: WebpackModule;
}, context: string): WebpackError[];
export declare function fsReadFile(fileName: string, encoding?: string | undefined): string | undefined;
export declare function makeError(loaderOptions: LoaderOptions, message: string, file: string | undefined, location?: FileLocation, endLocation?: FileLocation): WebpackError;
export declare function tsLoaderSource(loaderOptions: LoaderOptions): string;
export declare function appendSuffixIfMatch(patterns: (RegExp | string)[], filePath: string, suffix: string): string;
export declare function appendSuffixesIfMatch(suffixDict: {
    [suffix: string]: (RegExp | string)[];
}, filePath: string): string;
export declare function unorderedRemoveItem<T>(array: T[], item: T): boolean;
export declare function populateDependencyGraph(resolvedModules: ResolvedModule[], instance: TSInstance, containingFile: string): void;
export declare function populateReverseDependencyGraph(instance: TSInstance): ReverseDependencyGraph;
/**
 * Recursively collect all possible dependants of passed file
 */
export declare function collectAllDependants(reverseDependencyGraph: ReverseDependencyGraph, fileName: FilePathKey, result?: Map<FilePathKey, true>): Map<FilePathKey, true>;
export declare function arrify<T>(val: T | T[]): T[];
export declare function ensureProgram(instance: TSInstance): typescript.Program | undefined;
export declare function supportsSolutionBuild(instance: TSInstance): boolean;
export declare function isReferencedFile(instance: TSInstance, filePath: string): boolean;
export declare function useCaseSensitiveFileNames(compiler: typeof typescript, loaderOptions: LoaderOptions): boolean;
//# sourceMappingURL=utils.d.ts.map