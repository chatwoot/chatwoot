/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { UsageData, WatchPlugin } from 'jest-watcher';
export declare const filterInteractivePlugins: (watchPlugins: Array<WatchPlugin>, globalConfig: Config.GlobalConfig) => Array<WatchPlugin>;
export declare const getSortedUsageRows: (watchPlugins: Array<WatchPlugin>, globalConfig: Config.GlobalConfig) => Array<UsageData>;
