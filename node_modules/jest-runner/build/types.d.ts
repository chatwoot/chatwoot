/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import type { EventEmitter } from 'events';
import type { JestEnvironment } from '@jest/environment';
import type { AssertionResult, SerializableError, TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import type { FS as HasteFS, ModuleMap } from 'jest-haste-map';
import type { ResolverType } from 'jest-resolve';
import type { RuntimeType } from 'jest-runtime';
export declare type ErrorWithCode = Error & {
    code?: string;
};
export declare type Test = {
    context: Context;
    duration?: number;
    path: Config.Path;
};
export declare type Context = {
    config: Config.ProjectConfig;
    hasteFS: HasteFS;
    moduleMap: ModuleMap;
    resolver: ResolverType;
};
export declare type OnTestStart = (test: Test) => Promise<void>;
export declare type OnTestFailure = (test: Test, serializableError: SerializableError) => Promise<void>;
export declare type OnTestSuccess = (test: Test, testResult: TestResult) => Promise<void>;
export declare type TestEvents = {
    'test-file-start': [Test];
    'test-file-success': [Test, TestResult];
    'test-file-failure': [Test, SerializableError];
    'test-case-result': [Config.Path, AssertionResult];
};
export declare type TestFileEvent<T extends keyof TestEvents = keyof TestEvents> = (eventName: T, args: TestEvents[T]) => unknown;
export declare type TestFramework = (globalConfig: Config.GlobalConfig, config: Config.ProjectConfig, environment: JestEnvironment, runtime: RuntimeType, testPath: string, sendMessageToJest?: TestFileEvent) => Promise<TestResult>;
export declare type TestRunnerOptions = {
    serial: boolean;
};
export declare type TestRunnerContext = {
    changedFiles?: Set<Config.Path>;
    sourcesRelatedToTestsInChangedFiles?: Set<Config.Path>;
};
export declare type TestRunnerSerializedContext = {
    changedFiles?: Array<Config.Path>;
    sourcesRelatedToTestsInChangedFiles?: Array<Config.Path>;
};
export declare type WatcherState = {
    interrupted: boolean;
};
export interface TestWatcher extends EventEmitter {
    state: WatcherState;
    setState(state: WatcherState): void;
    isInterrupted(): boolean;
    isWatchMode(): boolean;
}
