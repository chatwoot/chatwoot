/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, AssertionResult, Suite, TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import DefaultReporter from './DefaultReporter';
import type { Test } from './types';
export default class VerboseReporter extends DefaultReporter {
    protected _globalConfig: Config.GlobalConfig;
    constructor(globalConfig: Config.GlobalConfig);
    static filterTestResults(testResults: Array<AssertionResult>): Array<AssertionResult>;
    static groupTestsBySuites(testResults: Array<AssertionResult>): Suite;
    onTestResult(test: Test, result: TestResult, aggregatedResults: AggregatedResult): void;
    private _logTestResults;
    private _logSuite;
    private _getIcon;
    private _logTest;
    private _logTests;
    private _logTodoOrPendingTest;
    private _logLine;
}
