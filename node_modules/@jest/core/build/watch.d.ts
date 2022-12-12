/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import type { Config } from '@jest/types';
import HasteMap = require('jest-haste-map');
import type { Context } from 'jest-runtime';
import { JestHook } from 'jest-watcher';
import type { Filter } from './types';
export default function watch(initialGlobalConfig: Config.GlobalConfig, contexts: Array<Context>, outputStream: NodeJS.WriteStream, hasteMapInstances: Array<HasteMap>, stdin?: NodeJS.ReadStream, hooks?: JestHook, filter?: Filter): Promise<void>;
