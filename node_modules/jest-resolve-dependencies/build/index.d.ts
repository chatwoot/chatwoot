/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { FS as HasteFS } from 'jest-haste-map';
import type { ResolveModuleConfig, ResolverType } from 'jest-resolve';
import { SnapshotResolver } from 'jest-snapshot';
declare namespace DependencyResolver {
    type ResolvedModule = {
        file: Config.Path;
        dependencies: Array<Config.Path>;
    };
}
/**
 * DependencyResolver is used to resolve the direct dependencies of a module or
 * to retrieve a list of all transitive inverse dependencies.
 */
declare class DependencyResolver {
    private _hasteFS;
    private _resolver;
    private _snapshotResolver;
    constructor(resolver: ResolverType, hasteFS: HasteFS, snapshotResolver: SnapshotResolver);
    resolve(file: Config.Path, options?: ResolveModuleConfig): Array<Config.Path>;
    resolveInverseModuleMap(paths: Set<Config.Path>, filter: (file: Config.Path) => boolean, options?: ResolveModuleConfig): Array<DependencyResolver.ResolvedModule>;
    resolveInverse(paths: Set<Config.Path>, filter: (file: Config.Path) => boolean, options?: ResolveModuleConfig): Array<Config.Path>;
}
export = DependencyResolver;
