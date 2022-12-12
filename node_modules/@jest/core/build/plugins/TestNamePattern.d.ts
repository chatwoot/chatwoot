/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import type { Config } from '@jest/types';
import { BaseWatchPlugin, Prompt, UpdateConfigCallback, UsageData } from 'jest-watcher';
declare class TestNamePatternPlugin extends BaseWatchPlugin {
    _prompt: Prompt;
    isInternal: true;
    constructor(options: {
        stdin: NodeJS.ReadStream;
        stdout: NodeJS.WriteStream;
    });
    getUsageInfo(): UsageData;
    onKey(key: string): void;
    run(globalConfig: Config.GlobalConfig, updateConfigAndRun: UpdateConfigCallback): Promise<void>;
}
export default TestNamePatternPlugin;
