declare type ArgumentsType<T> = T extends (...args: infer A) => any ? A : never;
declare type ReturnType<T> = T extends (...args: any) => infer R ? R : never;
interface BirpcOptions<Remote> {
    /**
     * Names of remote functions that do not need response.
     */
    eventNames?: (keyof Remote)[];
    /**
     * Function to post raw message
     */
    post: (data: any, ...extras: any[]) => void;
    /**
     * Listener to receive raw message
     */
    on: (fn: (data: any, ...extras: any[]) => void) => void;
    /**
     * Custom function to serialize data
     *
     * by default it passes the data as-is
     */
    serialize?: (data: any) => any;
    /**
     * Custom function to deserialize data
     *
     * by default it passes the data as-is
     */
    deserialize?: (data: any) => any;
}
interface BirpcFn<T> {
    /**
     * Call the remote function and wait for the result.
     */
    (...args: ArgumentsType<T>): Promise<Awaited<ReturnType<T>>>;
    /**
     * Send event without asking for response
     */
    asEvent(...args: ArgumentsType<T>): void;
}
declare type BirpcReturn<RemoteFunctions> = {
    [K in keyof RemoteFunctions]: BirpcFn<RemoteFunctions[K]>;
};
declare function createBirpc<RemoteFunctions = {}, LocalFunctions = {}>(functions: LocalFunctions, options: BirpcOptions<RemoteFunctions>): BirpcReturn<RemoteFunctions>;

export { ArgumentsType, BirpcFn, BirpcOptions, BirpcReturn, ReturnType, createBirpc };
