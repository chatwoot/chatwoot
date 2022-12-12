/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, TestCaseResult, TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import BaseReporter from './BaseReporter';
import type { ReporterOnStartOptions, Test } from './types';
export default class DefaultReporter extends BaseReporter {
    private _clear;
    private _err;
    protected _globalConfig: Config.GlobalConfig;
    private _out;
    private _status;
    private _bufferedOutput;
    constructor(globalConfig: Config.GlobalConfig);
    private _wrapStdio;
    forceFlushBufferedOutput(): void;
    private _clearStatus;
    private _printStatus;
    onRunStart(aggregatedResults: AggregatedResult, options: ReporterOnStartOptions): void;
    onTestStart(test: Test): void;
    onTestCaseResult(test: Test, testCaseResult: TestCaseResult): void;
    onRunComplete(): void;
    onTestResult(test: Test, testResult: TestResult, aggregatedResults: AggregatedResult): void;
    testFinished(config: Config.ProjectConfig, testResult: TestResult, aggregatedResults: AggregatedResult): void;
    printTestFileHeader(_testPath: Config.Path, config: Config.ProjectConfig, result: TestResult): void;
    printTestFileFailureMessage(_testPath: Config.Path, _config: Config.ProjectConfig, result: TestResult): void;
}
