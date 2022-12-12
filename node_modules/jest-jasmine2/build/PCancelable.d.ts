/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
export default class PCancelable<T> extends Promise<T> {
    private _pending;
    private _canceled;
    private _promise;
    private _cancel?;
    private _reject;
    constructor(executor: (onCancel: (cancelHandler: () => void) => void, resolve: (value?: T | PromiseLike<T>) => void, reject: (reason?: unknown) => void) => void);
    then<TResult1 = T, TResult2 = never>(onFulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onRejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | undefined | null): Promise<TResult1 | TResult2>;
    catch<TResult>(onRejected?: ((reason: unknown) => TResult | PromiseLike<TResult>) | undefined | null): Promise<T | TResult>;
    cancel(): void;
}
