/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, TestCaseResult, TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import type { ReporterOnStartOptions, Test } from './types';
declare type Cache = {
    content: string;
    clear: string;
};
/**
 * A class that generates the CLI status of currently running tests
 * and also provides an ANSI escape sequence to remove status lines
 * from the terminal.
 */
export default class Status {
    private _cache;
    private _callback?;
    private _currentTests;
    private _currentTestCases;
    private _done;
    private _emitScheduled;
    private _estimatedTime;
    private _interval?;
    private _aggregatedResults?;
    private _showStatus;
    constructor();
    onChange(callback: () => void): void;
    runStarted(aggregatedResults: AggregatedResult, options: ReporterOnStartOptions): void;
    runFinished(): void;
    addTestCaseResult(test: Test, testCaseResult: TestCaseResult): void;
    testStarted(testPath: Config.Path, config: Config.ProjectConfig): void;
    testFinished(_config: Config.ProjectConfig, testResult: TestResult, aggregatedResults: AggregatedResult): void;
    get(): Cache;
    private _emit;
    private _debouncedEmit;
    private _tick;
}
export {};
