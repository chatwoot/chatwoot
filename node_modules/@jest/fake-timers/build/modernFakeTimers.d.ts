/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import { StackTraceConfig } from 'jest-message-util';
export default class FakeTimers {
    private _clock;
    private _config;
    private _fakingTime;
    private _global;
    private _fakeTimers;
    private _maxLoops;
    constructor({ global, config, maxLoops, }: {
        global: NodeJS.Global;
        config: StackTraceConfig;
        maxLoops?: number;
    });
    clearAllTimers(): void;
    dispose(): void;
    runAllTimers(): void;
    runOnlyPendingTimers(): void;
    advanceTimersToNextTimer(steps?: number): void;
    advanceTimersByTime(msToRun: number): void;
    runAllTicks(): void;
    useRealTimers(): void;
    useFakeTimers(): void;
    reset(): void;
    setSystemTime(now?: number | Date): void;
    getRealSystemTime(): number;
    getTimerCount(): number;
    private _checkFakeTimers;
}
