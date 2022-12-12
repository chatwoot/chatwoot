/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { TestResult } from '@jest/test-result';
import type { Config } from '@jest/types';
import HasteMap = require('jest-haste-map');
import type { TestRunnerSerializedContext } from './types';
export declare type SerializableResolver = {
    config: Config.ProjectConfig;
    serializableModuleMap: HasteMap.SerializableModuleMap;
};
declare type WorkerData = {
    config: Config.ProjectConfig;
    globalConfig: Config.GlobalConfig;
    path: Config.Path;
    context?: TestRunnerSerializedContext;
};
export declare function setup(setupData: {
    serializableResolvers: Array<SerializableResolver>;
}): void;
export declare function worker({ config, globalConfig, path, context, }: WorkerData): Promise<TestResult>;
export {};
