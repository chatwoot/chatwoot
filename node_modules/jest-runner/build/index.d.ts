/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import Emittery = require('emittery');
import type { Config } from '@jest/types';
import type { OnTestFailure as JestOnTestFailure, OnTestStart as JestOnTestStart, OnTestSuccess as JestOnTestSuccess, Test as JestTest, TestEvents as JestTestEvents, TestFileEvent as JestTestFileEvent, TestRunnerContext as JestTestRunnerContext, TestRunnerOptions as JestTestRunnerOptions, TestWatcher as JestTestWatcher } from './types';
declare namespace TestRunner {
    type Test = JestTest;
    type OnTestFailure = JestOnTestFailure;
    type OnTestStart = JestOnTestStart;
    type OnTestSuccess = JestOnTestSuccess;
    type TestWatcher = JestTestWatcher;
    type TestRunnerContext = JestTestRunnerContext;
    type TestRunnerOptions = JestTestRunnerOptions;
    type TestFileEvent = JestTestFileEvent;
}
declare class TestRunner {
    private readonly _globalConfig;
    private readonly _context;
    private readonly eventEmitter;
    readonly __PRIVATE_UNSTABLE_API_supportsEventEmitters__: boolean;
    readonly isSerial?: boolean;
    constructor(globalConfig: Config.GlobalConfig, context?: JestTestRunnerContext);
    runTests(tests: Array<JestTest>, watcher: JestTestWatcher, onStart: JestOnTestStart | undefined, onResult: JestOnTestSuccess | undefined, onFailure: JestOnTestFailure | undefined, options: JestTestRunnerOptions): Promise<void>;
    private _createInBandTestRun;
    private _createParallelTestRun;
    on: {
        <Name extends "test-file-start" | "test-file-success" | "test-file-failure" | "test-case-result">(eventName: Name, listener: (eventData: JestTestEvents[Name]) => void): Emittery.UnsubscribeFn;
        <Name_1 extends never>(eventName: Name_1, listener: () => void): Emittery.UnsubscribeFn;
    };
}
export = TestRunner;
