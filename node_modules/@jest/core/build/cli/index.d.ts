/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult } from '@jest/test-result';
import type { Config } from '@jest/types';
export declare function runCLI(argv: Config.Argv, projects: Array<Config.Path>): Promise<{
    results: AggregatedResult;
    globalConfig: Config.GlobalConfig;
}>;
