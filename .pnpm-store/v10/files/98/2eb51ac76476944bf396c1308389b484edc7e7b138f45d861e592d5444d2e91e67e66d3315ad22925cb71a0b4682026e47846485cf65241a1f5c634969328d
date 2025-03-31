interface SentryTrpcMiddlewareOptions {
    /** Whether to include procedure inputs in reported events. Defaults to `false`. */
    attachRpcInput?: boolean;
}
export interface SentryTrpcMiddlewareArguments<T> {
    path?: unknown;
    type?: unknown;
    next: () => T;
    rawInput?: unknown;
}
/**
 * Sentry tRPC middleware that captures errors and creates spans for tRPC procedures.
 */
export declare function trpcMiddleware(options?: SentryTrpcMiddlewareOptions): <T>(opts: SentryTrpcMiddlewareArguments<T>) => T;
export {};
//# sourceMappingURL=trpc.d.ts.map
