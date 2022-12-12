/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { AllowedConfigOptions } from 'jest-watcher';
declare type ExtraConfigOptions = Partial<Pick<Config.GlobalConfig, 'noSCM' | 'passWithNoTests'>>;
declare const _default: (globalConfig: Config.GlobalConfig, options?: AllowedConfigOptions & ExtraConfigOptions) => Config.GlobalConfig;
export default _default;
