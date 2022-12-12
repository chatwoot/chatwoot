/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import { Context, Script } from 'vm';
import type { JestEnvironment } from '@jest/environment';
import { LegacyFakeTimers, ModernFakeTimers } from '@jest/fake-timers';
import type { Config, Global } from '@jest/types';
import { ModuleMocker } from 'jest-mock';
declare type Timer = {
    id: number;
    ref: () => Timer;
    unref: () => Timer;
};
declare class NodeEnvironment implements JestEnvironment {
    context: Context | null;
    fakeTimers: LegacyFakeTimers<Timer> | null;
    fakeTimersModern: ModernFakeTimers | null;
    global: Global.Global;
    moduleMocker: ModuleMocker | null;
    constructor(config: Config.ProjectConfig);
    setup(): Promise<void>;
    teardown(): Promise<void>;
    runScript<T = unknown>(script: Script): T | null;
    getVmContext(): Context | null;
}
export = NodeEnvironment;
