/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
export declare function run(maybeArgv?: Array<string>, project?: Config.Path): Promise<void>;
export declare const buildArgv: (maybeArgv?: string[] | undefined) => Config.Argv;
