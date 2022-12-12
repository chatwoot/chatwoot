/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { V8Coverage } from 'collect-v8-coverage';
import { FileCoverage } from 'istanbul-lib-coverage';
import type { Config } from '@jest/types';
declare type SingleV8Coverage = V8Coverage[number];
export declare type CoverageWorkerResult = {
    kind: 'BabelCoverage';
    coverage: FileCoverage;
} | {
    kind: 'V8Coverage';
    result: SingleV8Coverage;
};
export default function (source: string, filename: Config.Path, globalConfig: Config.GlobalConfig, config: Config.ProjectConfig, changedFiles?: Set<Config.Path>, sourcesRelatedToTestsInChangedFiles?: Set<Config.Path>): CoverageWorkerResult | null;
export {};
