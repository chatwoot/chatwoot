/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { Test } from 'jest-runner';
declare const _default: ({ allTests, globalConfig, moduleName, }: {
    allTests: Array<Test>;
    globalConfig: Config.GlobalConfig;
    moduleName: 'globalSetup' | 'globalTeardown';
}) => Promise<void>;
export default _default;
