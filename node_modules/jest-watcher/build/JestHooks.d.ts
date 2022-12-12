/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { JestHookEmitter, JestHookSubscriber } from './types';
declare type AvailableHooks = 'onFileChange' | 'onTestRunComplete' | 'shouldRunTestSuite';
declare class JestHooks {
    private _listeners;
    private _subscriber;
    private _emitter;
    constructor();
    isUsed(hook: AvailableHooks): boolean;
    getSubscriber(): Readonly<JestHookSubscriber>;
    getEmitter(): Readonly<JestHookEmitter>;
}
export default JestHooks;
