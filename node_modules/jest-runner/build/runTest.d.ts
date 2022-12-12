/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import type { ResolverType } from 'jest-resolve';
import type { TestFileEvent, TestRunnerContext } from './types';
export default function runTest(path: Config.Path, globalConfig: Config.GlobalConfig, config: Config.ProjectConfig, resolver: ResolverType, context?: TestRunnerContext, sendMessageToJest?: TestFileEvent): Promise<TestResult>;
