/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import { ChangedFilesPromise } from 'jest-changed-files';
declare const _default: (globalConfig: Config.GlobalConfig, configs: Array<Config.ProjectConfig>) => ChangedFilesPromise | undefined;
export default _default;
