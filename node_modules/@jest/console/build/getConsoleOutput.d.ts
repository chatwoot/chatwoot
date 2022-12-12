/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import { StackTraceConfig } from 'jest-message-util';
import type { ConsoleBuffer } from './types';
declare const _default: (root: string, verbose: boolean, buffer: ConsoleBuffer, config?: StackTraceConfig, globalConfig?: Config.GlobalConfig | undefined) => string;
export default _default;
