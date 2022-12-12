/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { RawSourceMap } from 'source-map';
import type { Config, TransformTypes } from '@jest/types';
export declare type ShouldInstrumentOptions = Pick<Config.GlobalConfig, 'collectCoverage' | 'collectCoverageFrom' | 'collectCoverageOnlyFrom' | 'coverageProvider'> & {
    changedFiles?: Set<Config.Path>;
    sourcesRelatedToTestsInChangedFiles?: Set<Config.Path>;
};
export declare type Options = ShouldInstrumentOptions & Partial<{
    isCoreModule: boolean;
    isInternalModule: boolean;
}> & CallerTransformOptions;
interface FixedRawSourceMap extends Omit<RawSourceMap, 'version'> {
    version: number;
}
export declare type TransformedSource = {
    code: string;
    map?: FixedRawSourceMap | string | null;
} | string;
export declare type TransformResult = TransformTypes.TransformResult;
export interface CallerTransformOptions {
    supportsDynamicImport?: boolean;
    supportsExportNamespaceFrom?: boolean;
    supportsStaticESM?: boolean;
    supportsTopLevelAwait?: boolean;
}
export interface TransformOptions extends CallerTransformOptions {
    instrument: boolean;
}
export interface CacheKeyOptions extends TransformOptions {
    config: Config.ProjectConfig;
    rootDir: string;
}
export interface Transformer {
    canInstrument?: boolean;
    createTransformer?: (options?: any) => Transformer;
    getCacheKey?: (fileData: string, filePath: Config.Path, configStr: string, options: CacheKeyOptions) => string;
    process: (sourceText: string, sourcePath: Config.Path, config: Config.ProjectConfig, options?: TransformOptions) => TransformedSource;
}
export {};
