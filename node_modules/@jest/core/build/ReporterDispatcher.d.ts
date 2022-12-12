/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Reporter, ReporterOnStartOptions } from '@jest/reporters';
import type { AggregatedResult, TestCaseResult, TestResult } from '@jest/test-result';
import type { Test } from 'jest-runner';
import type { Context } from 'jest-runtime';
export default class ReporterDispatcher {
    private _reporters;
    constructor();
    register(reporter: Reporter): void;
    unregister(ReporterClass: Function): void;
    onTestFileResult(test: Test, testResult: TestResult, results: AggregatedResult): Promise<void>;
    onTestFileStart(test: Test): Promise<void>;
    onRunStart(results: AggregatedResult, options: ReporterOnStartOptions): Promise<void>;
    onTestCaseResult(test: Test, testCaseResult: TestCaseResult): Promise<void>;
    onRunComplete(contexts: Set<Context>, results: AggregatedResult): Promise<void>;
    getErrors(): Array<Error>;
    hasErrors(): boolean;
}
