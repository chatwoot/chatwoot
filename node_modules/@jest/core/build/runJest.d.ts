/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import { AggregatedResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import type { ChangedFilesPromise } from 'jest-changed-files';
import type { Context } from 'jest-runtime';
import { JestHookEmitter } from 'jest-watcher';
import type FailedTestsCache from './FailedTestsCache';
import type TestWatcher from './TestWatcher';
import type { Filter } from './types';
export default function runJest({ contexts, globalConfig, outputStream, testWatcher, jestHooks, startRun, changedFilesPromise, onComplete, failedTestsCache, filter, }: {
    globalConfig: Config.GlobalConfig;
    contexts: Array<Context>;
    outputStream: NodeJS.WriteStream;
    testWatcher: TestWatcher;
    jestHooks?: JestHookEmitter;
    startRun: (globalConfig: Config.GlobalConfig) => void;
    changedFilesPromise?: ChangedFilesPromise;
    onComplete: (testResults: AggregatedResult) => void;
    failedTestsCache?: FailedTestsCache;
    filter?: Filter;
}): Promise<void>;
