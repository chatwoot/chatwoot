/**
 * @license
 * Copyright 2021 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * Helper to iterate an AsyncIterable in its own closure.
 * @param iterable The iterable to iterate
 * @param callback The callback to call for each value. If the callback returns
 * `false`, the loop will be broken.
 */
export declare const forAwaitOf: <T>(iterable: AsyncIterable<T>, callback: (value: T) => Promise<boolean>) => Promise<void>;
/**
 * Holds a reference to an instance that can be disconnected and reconnected,
 * so that a closure over the ref (e.g. in a then function to a promise) does
 * not strongly hold a ref to the instance. Approximates a WeakRef but must
 * be manually connected & disconnected to the backing instance.
 */
export declare class PseudoWeakRef<T> {
    private _ref?;
    constructor(ref: T);
    /**
     * Disassociates the ref with the backing instance.
     */
    disconnect(): void;
    /**
     * Reassociates the ref with the backing instance.
     */
    reconnect(ref: T): void;
    /**
     * Retrieves the backing instance (will be undefined when disconnected)
     */
    deref(): T | undefined;
}
/**
 * A helper to pause and resume waiting on a condition in an async function
 */
export declare class Pauser {
    private _promise?;
    private _resolve?;
    /**
     * When paused, returns a promise to be awaited; when unpaused, returns
     * undefined. Note that in the microtask between the pauser being resumed
     * an an await of this promise resolving, the pauser could be paused again,
     * hence callers should check the promise in a loop when awaiting.
     * @returns A promise to be awaited when paused or undefined
     */
    get(): Promise<void> | undefined;
    /**
     * Creates a promise to be awaited
     */
    pause(): void;
    /**
     * Resolves the promise which may be awaited
     */
    resume(): void;
}
//# sourceMappingURL=private-async-helpers.d.ts.map