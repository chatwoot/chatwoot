/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Config } from '@jest/types';
import type { ChangedFilesPromise, Options, Repos } from './types';
export type { ChangedFiles, ChangedFilesPromise } from './types';
export declare const getChangedFilesForRoots: (roots: Array<Config.Path>, options: Options) => ChangedFilesPromise;
export declare const findRepos: (roots: Array<Config.Path>) => Promise<Repos>;
