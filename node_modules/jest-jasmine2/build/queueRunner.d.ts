/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
declare type Global = NodeJS.Global;
export declare type Options = {
    clearTimeout: Global['clearTimeout'];
    fail: (error: Error) => void;
    onException: (error: Error) => void;
    queueableFns: Array<QueueableFn>;
    setTimeout: Global['setTimeout'];
    userContext: unknown;
};
export interface DoneFn {
    (error?: any): void;
    fail: (error: Error) => void;
}
export declare type QueueableFn = {
    fn: (done: DoneFn) => void;
    timeout?: () => number;
    initError?: Error;
};
declare type PromiseCallback = (() => void | PromiseLike<void>) | undefined | null;
export default function queueRunner(options: Options): PromiseLike<void> & {
    cancel: () => void;
    catch: (onRejected?: PromiseCallback) => Promise<void>;
};
export {};
