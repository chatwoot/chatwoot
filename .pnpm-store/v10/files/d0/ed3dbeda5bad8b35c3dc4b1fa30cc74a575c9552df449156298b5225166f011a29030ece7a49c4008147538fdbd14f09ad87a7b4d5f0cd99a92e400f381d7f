export interface PromiseBuffer<T> {
    $: Array<PromiseLike<T>>;
    add(taskProducer: () => PromiseLike<T>): PromiseLike<T>;
    drain(timeout?: number): PromiseLike<boolean>;
}
/**
 * Creates an new PromiseBuffer object with the specified limit
 * @param limit max number of promises that can be stored in the buffer
 */
export declare function makePromiseBuffer<T>(limit?: number): PromiseBuffer<T>;
//# sourceMappingURL=promisebuffer.d.ts.map