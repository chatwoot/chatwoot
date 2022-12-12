/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import BaseReporter from './BaseReporter';
import type { Context, CoverageReporterOptions, Test } from './types';
export default class CoverageReporter extends BaseReporter {
    private _coverageMap;
    private _globalConfig;
    private _sourceMapStore;
    private _options;
    private _v8CoverageResults;
    constructor(globalConfig: Config.GlobalConfig, options?: CoverageReporterOptions);
    onTestResult(_test: Test, testResult: TestResult): void;
    onRunComplete(contexts: Set<Context>, aggregatedResults: AggregatedResult): Promise<void>;
    private _addUntestedFiles;
    private _checkThreshold;
    private _getCoverageResult;
}
