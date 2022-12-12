/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { V8Coverage } from 'collect-v8-coverage';
import type { CoverageMap, CoverageMapData } from 'istanbul-lib-coverage';
import type { ConsoleBuffer } from '@jest/console';
import type { Config, TestResult, TransformTypes } from '@jest/types';
export interface RuntimeTransformResult extends TransformTypes.TransformResult {
    wrapperLength?: number;
}
export declare type V8CoverageResult = Array<{
    codeTransformResult: RuntimeTransformResult | undefined;
    result: V8Coverage[number];
}>;
export declare type SerializableError = TestResult.SerializableError;
export declare type FailedAssertion = {
    matcherName?: string;
    message?: string;
    actual?: unknown;
    pass?: boolean;
    passed?: boolean;
    expected?: unknown;
    isNot?: boolean;
    stack?: string;
    error?: unknown;
};
export declare type AssertionLocation = {
    fullName: string;
    path: string;
};
export declare type Status = AssertionResult['status'];
export declare type Bytes = number;
export declare type Milliseconds = TestResult.Milliseconds;
export declare type AssertionResult = TestResult.AssertionResult;
export declare type FormattedAssertionResult = Pick<AssertionResult, 'ancestorTitles' | 'fullName' | 'location' | 'status' | 'title'> & {
    failureMessages: AssertionResult['failureMessages'] | null;
};
export declare type AggregatedResultWithoutCoverage = {
    numFailedTests: number;
    numFailedTestSuites: number;
    numPassedTests: number;
    numPassedTestSuites: number;
    numPendingTests: number;
    numTodoTests: number;
    numPendingTestSuites: number;
    numRuntimeErrorTestSuites: number;
    numTotalTests: number;
    numTotalTestSuites: number;
    openHandles: Array<Error>;
    snapshot: SnapshotSummary;
    startTime: number;
    success: boolean;
    testResults: Array<TestResult>;
    wasInterrupted: boolean;
};
export declare type AggregatedResult = AggregatedResultWithoutCoverage & {
    coverageMap?: CoverageMap | null;
};
export declare type Suite = {
    title: string;
    suites: Array<Suite>;
    tests: Array<AssertionResult>;
};
export declare type TestCaseResult = AssertionResult;
export declare type TestResult = {
    console?: ConsoleBuffer;
    coverage?: CoverageMapData;
    displayName?: Config.DisplayName;
    failureMessage?: string | null;
    leaks: boolean;
    memoryUsage?: Bytes;
    numFailingTests: number;
    numPassingTests: number;
    numPendingTests: number;
    numTodoTests: number;
    openHandles: Array<Error>;
    perfStats: {
        end: Milliseconds;
        runtime: Milliseconds;
        slow: boolean;
        start: Milliseconds;
    };
    skipped: boolean;
    snapshot: {
        added: number;
        fileDeleted: boolean;
        matched: number;
        unchecked: number;
        uncheckedKeys: Array<string>;
        unmatched: number;
        updated: number;
    };
    sourceMaps?: {
        [sourcePath: string]: string;
    };
    testExecError?: SerializableError;
    testFilePath: Config.Path;
    testResults: Array<AssertionResult>;
    v8Coverage?: V8CoverageResult;
};
export declare type FormattedTestResult = {
    message: string;
    name: string;
    summary: string;
    status: 'failed' | 'passed';
    startTime: number;
    endTime: number;
    coverage: unknown;
    assertionResults: Array<FormattedAssertionResult>;
};
export declare type FormattedTestResults = {
    coverageMap?: CoverageMap | null | undefined;
    numFailedTests: number;
    numFailedTestSuites: number;
    numPassedTests: number;
    numPassedTestSuites: number;
    numPendingTests: number;
    numPendingTestSuites: number;
    numRuntimeErrorTestSuites: number;
    numTotalTests: number;
    numTotalTestSuites: number;
    snapshot: SnapshotSummary;
    startTime: number;
    success: boolean;
    testResults: Array<FormattedTestResult>;
    wasInterrupted: boolean;
};
export declare type CodeCoverageReporter = unknown;
export declare type CodeCoverageFormatter = (coverage: CoverageMapData | null | undefined, reporter: CodeCoverageReporter) => Record<string, unknown> | null | undefined;
export declare type UncheckedSnapshot = {
    filePath: string;
    keys: Array<string>;
};
export declare type SnapshotSummary = {
    added: number;
    didUpdate: boolean;
    failure: boolean;
    filesAdded: number;
    filesRemoved: number;
    filesRemovedList: Array<string>;
    filesUnmatched: number;
    filesUpdated: number;
    matched: number;
    total: number;
    unchecked: number;
    uncheckedKeysByFile: Array<UncheckedSnapshot>;
    unmatched: number;
    updated: number;
};
