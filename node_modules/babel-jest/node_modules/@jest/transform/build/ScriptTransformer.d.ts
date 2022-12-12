/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { Options, TransformResult } from './types';
export default class ScriptTransformer {
    private _cache;
    private _config;
    private _transformCache;
    private _transformConfigCache;
    constructor(config: Config.ProjectConfig);
    private _getCacheKey;
    private _getFileCachePath;
    private _getTransformPath;
    private _getTransformer;
    private _instrumentFile;
    private _getRealPath;
    preloadTransformer(filepath: Config.Path): void;
    transformSource(filepath: Config.Path, content: string, instrument: boolean, supportsDynamicImport?: boolean, supportsStaticESM?: boolean): TransformResult;
    private _transformAndBuildScript;
    transform(filename: Config.Path, options: Options, fileSource?: string): TransformResult;
    transformJson(filename: Config.Path, options: Options, fileSource: string): string;
    requireAndTranspileModule<ModuleType = unknown>(moduleName: string, callback?: (module: ModuleType) => void): ModuleType;
    requireAndTranspileModule<ModuleType = unknown>(moduleName: string, callback?: (module: ModuleType) => Promise<void>): Promise<ModuleType>;
    /**
     * @deprecated use `this.shouldTransform` instead
     */
    private _shouldTransform;
    shouldTransform(filename: Config.Path): boolean;
}
export declare function createTranspilingRequire(config: Config.ProjectConfig): <TModuleType = unknown>(resolverPath: string, applyInteropRequireDefault?: boolean) => TModuleType;
