export declare function resolvedSyncPromise(): PromiseLike<void>;
export declare function resolvedSyncPromise<T>(value: T | PromiseLike<T>): PromiseLike<T>;
/**
 * Creates a rejected sync promise.
 *
 * @param value the value to reject the promise with
 * @returns the rejected sync promise
 */
export declare function rejectedSyncPromise<T = never>(reason?: any): PromiseLike<T>;
/**
 * Thenable class that behaves like a Promise and follows it's interface
 * but is not async internally
 */
declare class SyncPromise<T> implements PromiseLike<T> {
    private _state;
    private _handlers;
    private _value;
    constructor(executor: (resolve: (value?: T | PromiseLike<T> | null) => void, reject: (reason?: any) => void) => void);
    /** JSDoc */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | null): PromiseLike<TResult1 | TResult2>;
    /** JSDoc */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | null): PromiseLike<T | TResult>;
    /** JSDoc */
    finally<TResult>(onfinally?: (() => void) | null): PromiseLike<TResult>;
    /** JSDoc */
    private readonly _resolve;
    /** JSDoc */
    private readonly _reject;
    /** JSDoc */
    private readonly _setResult;
    /** JSDoc */
    private readonly _executeHandlers;
}
export { SyncPromise };
//# sourceMappingURL=syncpromise.d.ts.map