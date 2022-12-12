/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, TestCaseResult, TestResult } from '@jest/test-result';
import type { Context, Reporter, ReporterOnStartOptions, Test } from './types';
export default class BaseReporter implements Reporter {
    private _error?;
    log(message: string): void;
    onRunStart(_results?: AggregatedResult, _options?: ReporterOnStartOptions): void;
    onTestCaseResult(_test: Test, _testCaseResult: TestCaseResult): void;
    onTestResult(_test?: Test, _testResult?: TestResult, _results?: AggregatedResult): void;
    onTestStart(_test?: Test): void;
    onRunComplete(_contexts?: Set<Context>, _aggregatedResults?: AggregatedResult): Promise<void> | void;
    protected _setError(error: Error): void;
    getLastError(): Error | undefined;
}
