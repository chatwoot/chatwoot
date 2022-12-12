import type * as typescript from 'typescript';
import * as webpack from 'webpack';
import { LoaderOptions, TSInstance, WebpackError } from './interfaces';
/**
 * The loader is executed once for each file seen by webpack. However, we need to keep
 * a persistent instance of TypeScript that contains all of the files in the program
 * along with definition files and options. This function either creates an instance
 * or returns the existing one. Multiple instances are possible by using the
 * `instance` property.
 */
export declare function getTypeScriptInstance(loaderOptions: LoaderOptions, loader: webpack.loader.LoaderContext): {
    instance?: TSInstance;
    error?: WebpackError;
};
export declare function initializeInstance(loader: webpack.loader.LoaderContext, instance: TSInstance): void;
export declare function reportTranspileErrors(instance: TSInstance, loader: webpack.loader.LoaderContext): void;
export declare function buildSolutionReferences(instance: TSInstance, loader: webpack.loader.LoaderContext): void;
export declare function forEachResolvedProjectReference<T>(resolvedProjectReferences: readonly (typescript.ResolvedProjectReference | undefined)[] | undefined, cb: (resolvedProjectReference: typescript.ResolvedProjectReference) => T | undefined): T | undefined;
export declare function getOutputFileNames(instance: TSInstance, configFile: typescript.ParsedCommandLine, inputFileName: string): string[];
export declare function getInputFileNameFromOutput(instance: TSInstance, filePath: string): string | undefined;
export declare function getEmitFromWatchHost(instance: TSInstance, filePath?: string): typescript.OutputFile[] | undefined;
export declare function getEmitOutput(instance: TSInstance, filePath: string): typescript.OutputFile[];
//# sourceMappingURL=instances.d.ts.map