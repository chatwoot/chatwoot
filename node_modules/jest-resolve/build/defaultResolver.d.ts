/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Opts as ResolveOpts } from 'resolve';
import type { Config } from '@jest/types';
declare type ResolverOptions = {
    allowPnp?: boolean;
    basedir: Config.Path;
    browser?: boolean;
    defaultResolver: typeof defaultResolver;
    extensions?: Array<string>;
    moduleDirectory?: Array<string>;
    paths?: Array<Config.Path>;
    rootDir?: Config.Path;
    packageFilter?: ResolveOpts['packageFilter'];
};
declare global {
    namespace NodeJS {
        interface ProcessVersions {
            pnp?: unknown;
        }
    }
}
export default function defaultResolver(path: Config.Path, options: ResolverOptions): Config.Path;
export declare function clearDefaultResolverCache(): void;
export {};
