import type * as typescript from 'typescript';
import * as webpack from 'webpack';
import { FilePathKey, ServiceHostWhichMayBeCacheable, SolutionBuilderWithWatchHost, TSInstance, WatchHost, WebpackError } from './interfaces';
/**
 * Create the TypeScript language service
 */
export declare function makeServicesHost(scriptRegex: RegExp, loader: webpack.loader.LoaderContext, instance: TSInstance, projectReferences?: ReadonlyArray<typescript.ProjectReference>): ServiceHostWhichMayBeCacheable;
export declare function updateFileWithText(instance: TSInstance, key: FilePathKey, filePath: string, text: (nFilePath: string) => string): void;
/**
 * Create the TypeScript Watch host
 */
export declare function makeWatchHost(scriptRegex: RegExp, loader: webpack.loader.LoaderContext, instance: TSInstance, projectReferences?: ReadonlyArray<typescript.ProjectReference>): WatchHost;
/**
 * Create the TypeScript Watch host
 */
export declare function makeSolutionBuilderHost(scriptRegex: RegExp, loader: webpack.loader.LoaderContext, instance: TSInstance): SolutionBuilderWithWatchHost;
export declare function getSolutionErrors(instance: TSInstance, context: string): WebpackError[];
//# sourceMappingURL=servicesHost.d.ts.map