/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { JestEnvironment } from '@jest/environment';
import type * as JestGlobals from '@jest/globals';
import type { SourceMapRegistry } from '@jest/source-map';
import type { V8CoverageResult } from '@jest/test-result';
import { CallerTransformOptions, ShouldInstrumentOptions, shouldInstrument } from '@jest/transform';
import type { Config, Global } from '@jest/types';
import HasteMap = require('jest-haste-map');
import Resolver = require('jest-resolve');
import { options as cliOptions } from './cli/args';
import type { Context as JestContext } from './types';
interface JestGlobals extends Global.TestFrameworkGlobals {
    expect: typeof JestGlobals.expect;
}
declare type HasteMapOptions = {
    console?: Console;
    maxWorkers: number;
    resetCache: boolean;
    watch?: boolean;
    watchman: boolean;
};
interface InternalModuleOptions extends Required<CallerTransformOptions> {
    isInternalModule: boolean;
}
declare namespace Runtime {
    type Context = JestContext;
    type RuntimeType = Runtime;
}
declare class Runtime {
    private _cacheFS;
    private _config;
    private _coverageOptions;
    private _currentlyExecutingModulePath;
    private _environment;
    private _explicitShouldMock;
    private _fakeTimersImplementation;
    private _internalModuleRegistry;
    private _isCurrentlyExecutingManualMock;
    private _mainModule;
    private _mockFactories;
    private _mockMetaDataCache;
    private _mockRegistry;
    private _isolatedMockRegistry;
    private _moduleMocker;
    private _isolatedModuleRegistry;
    private _moduleRegistry;
    private _esmoduleRegistry;
    private _testPath;
    private _resolver;
    private _shouldAutoMock;
    private _shouldMockModuleCache;
    private _shouldUnmockTransitiveDependenciesCache;
    private _sourceMapRegistry;
    private _scriptTransformer;
    private _fileTransforms;
    private _v8CoverageInstrumenter;
    private _v8CoverageResult;
    private _transitiveShouldMock;
    private _unmockList;
    private _virtualMocks;
    private _moduleImplementation?;
    private jestObjectCaches;
    private jestGlobals?;
    constructor(config: Config.ProjectConfig, environment: JestEnvironment, resolver: Resolver, cacheFS?: Record<string, string>, coverageOptions?: ShouldInstrumentOptions, testPath?: Config.Path);
    static shouldInstrument: typeof shouldInstrument;
    static createContext(config: Config.ProjectConfig, options: {
        console?: Console;
        maxWorkers: number;
        watch?: boolean;
        watchman: boolean;
    }): Promise<JestContext>;
    static createHasteMap(config: Config.ProjectConfig, options?: HasteMapOptions): HasteMap;
    static createResolver(config: Config.ProjectConfig, moduleMap: HasteMap.ModuleMap): Resolver;
    static runCLI(args?: Config.Argv, info?: Array<string>): Promise<void>;
    static getCLIOptions(): typeof cliOptions;
    unstable_shouldLoadAsEsm: typeof import("jest-resolve/build/shouldLoadAsEsm").default;
    private loadEsmModule;
    private linkModules;
    unstable_importModule(from: Config.Path, moduleName?: string): Promise<void>;
    private loadCjsAsEsm;
    requireModule<T = unknown>(from: Config.Path, moduleName?: string, options?: InternalModuleOptions, isRequireActual?: boolean | null): T;
    requireInternalModule<T = unknown>(from: Config.Path, to?: string): T;
    requireActual<T = unknown>(from: Config.Path, moduleName: string): T;
    requireMock<T = unknown>(from: Config.Path, moduleName: string): T;
    private _loadModule;
    private _getFullTransformationOptions;
    requireModuleOrMock<T = unknown>(from: Config.Path, moduleName: string): T;
    isolateModules(fn: () => void): void;
    resetModules(): void;
    collectV8Coverage(): Promise<void>;
    stopCollectingV8Coverage(): Promise<void>;
    getAllCoverageInfoCopy(): JestEnvironment['global']['__coverage__'];
    getAllV8CoverageInfoCopy(): V8CoverageResult;
    getSourceMapInfo(_coveredFiles: Set<string>): Record<string, string>;
    getSourceMaps(): SourceMapRegistry;
    setMock(from: string, moduleName: string, mockFactory: () => unknown, options?: {
        virtual?: boolean;
    }): void;
    restoreAllMocks(): void;
    resetAllMocks(): void;
    clearAllMocks(): void;
    teardown(): void;
    private _resolveModule;
    private _requireResolve;
    private _requireResolvePaths;
    private _execModule;
    private transformFile;
    private createScriptFromCode;
    private _requireCoreModule;
    private _importCoreModule;
    private _getMockedNativeModule;
    private _generateMock;
    private _shouldMock;
    private _createRequireImplementation;
    private _createJestObjectFor;
    private _logFormattedReferenceError;
    private wrapCodeInModuleWrapper;
    private constructModuleWrapperStart;
    private constructInjectedModuleParameters;
    private handleExecutionError;
    private getGlobalsForCjs;
    private getGlobalsForEsm;
    private getGlobalsFromEnvironment;
    private readFile;
    setGlobalsForRuntime(globals: JestGlobals): void;
}
export = Runtime;
