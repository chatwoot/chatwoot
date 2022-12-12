/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import type { TestResult } from '@jest/test-result';
import { PatternPrompt, Prompt, ScrollOptions } from 'jest-watcher';
export default class TestNamePatternPrompt extends PatternPrompt {
    _cachedTestResults: Array<TestResult>;
    constructor(pipe: NodeJS.WritableStream, prompt: Prompt);
    _onChange(pattern: string, options: ScrollOptions): void;
    _printPrompt(pattern: string): void;
    _getMatchedTests(pattern: string): Array<string>;
    updateCachedTestResults(testResults?: Array<TestResult>): void;
}
