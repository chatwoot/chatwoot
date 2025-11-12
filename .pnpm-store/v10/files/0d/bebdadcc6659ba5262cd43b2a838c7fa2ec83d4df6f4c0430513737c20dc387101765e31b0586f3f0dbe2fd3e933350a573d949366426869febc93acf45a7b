import { FetchLike } from '../types';
export * from './bucketed-rate-limiter';
export * from './number-utils';
export * from './string-utils';
export * from './type-utils';
export declare const STRING_FORMAT = "utf8";
export declare function assert(truthyValue: any, message: string): void;
export declare function removeTrailingSlash(url: string): string;
export interface RetriableOptions {
    retryCount: number;
    retryDelay: number;
    retryCheck: (err: unknown) => boolean;
}
export declare function retriable<T>(fn: () => Promise<T>, props: RetriableOptions): Promise<T>;
export declare function currentTimestamp(): number;
export declare function currentISOTime(): string;
export declare function safeSetTimeout(fn: () => void, timeout: number): any;
export declare const isPromise: (obj: any) => obj is Promise<any>;
export declare const isError: (x: unknown) => x is Error;
export declare function getFetch(): FetchLike | undefined;
export declare function allSettled<T>(promises: (Promise<T> | null | undefined)[]): Promise<({
    status: 'fulfilled';
    value: T;
} | {
    status: 'rejected';
    reason: any;
})[]>;
//# sourceMappingURL=index.d.ts.map