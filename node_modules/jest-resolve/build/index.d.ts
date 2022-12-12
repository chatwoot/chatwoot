/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { ModuleMap } from 'jest-haste-map';
import ModuleNotFoundError from './ModuleNotFoundError';
import shouldLoadAsEsm from './shouldLoadAsEsm';
import type { ResolverConfig } from './types';
declare type FindNodeModuleConfig = {
    basedir: Config.Path;
    browser?: boolean;
    extensions?: Array<string>;
    moduleDirectory?: Array<string>;
    paths?: Array<Config.Path>;
    resolver?: Config.Path | null;
    rootDir?: Config.Path;
    throwIfNotFound?: boolean;
};
declare type BooleanObject = Record<string, boolean>;
declare namespace Resolver {
    type ResolveModuleConfig = {
        skipNodeResolution?: boolean;
        paths?: Array<Config.Path>;
    };
    type ResolverType = Resolver;
}
declare class Resolver {
    private readonly _options;
    private readonly _moduleMap;
    private readonly _moduleIDCache;
    private readonly _moduleNameCache;
    private readonly _modulePathCache;
    private readonly _supportsNativePlatform;
    constructor(moduleMap: ModuleMap, options: ResolverConfig);
    static ModuleNotFoundError: typeof ModuleNotFoundError;
    static tryCastModuleNotFoundError(error: unknown): ModuleNotFoundError | null;
    static clearDefaultResolverCache(): void;
    static findNodeModule(path: Config.Path, options: FindNodeModuleConfig): Config.Path | null;
    static unstable_shouldLoadAsEsm: typeof shouldLoadAsEsm;
    resolveModuleFromDirIfExists(dirname: Config.Path, moduleName: string, options?: Resolver.ResolveModuleConfig): Config.Path | null;
    resolveModule(from: Config.Path, moduleName: string, options?: Resolver.ResolveModuleConfig): Config.Path;
    private _isAliasModule;
    isCoreModule(moduleName: string): boolean;
    getModule(name: string): Config.Path | null;
    getModulePath(from: Config.Path, moduleName: string): Config.Path;
    getPackage(name: string): Config.Path | null;
    getMockModule(from: Config.Path, name: string): Config.Path | null;
    getModulePaths(from: Config.Path): Array<Config.Path>;
    getModuleID(virtualMocks: BooleanObject, from: Config.Path, _moduleName?: string): string;
    private _getModuleType;
    private _getAbsolutePath;
    private _getMockPath;
    private _getVirtualMockPath;
    private _isModuleResolved;
    resolveStubModuleName(from: Config.Path, moduleName: string): Config.Path | null;
}
export = Resolver;
