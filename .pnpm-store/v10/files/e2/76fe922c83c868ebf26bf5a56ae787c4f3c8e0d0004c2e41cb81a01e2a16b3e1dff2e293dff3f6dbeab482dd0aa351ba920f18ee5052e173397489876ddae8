/**
 * adapted from https://github.com/getsentry/sentry-javascript/blob/72751dacb88c5b970d8bac15052ee8e09b28fd5d/packages/browser-utils/src/getNativeImplementation.ts#L27
 * and https://github.com/PostHog/rrweb/blob/804380afbb1b9bed70b8792cb5a25d827f5c0cb5/packages/utils/src/index.ts#L31
 * after a number of performance reports from Angular users
 */
import { AssignableWindow } from './globals';
interface NativeImplementationsCache {
    MutationObserver: typeof MutationObserver;
}
export declare function getNativeImplementation<T extends keyof NativeImplementationsCache>(name: T, assignableWindow: AssignableWindow): NativeImplementationsCache[T];
export declare function getNativeMutationObserverImplementation(assignableWindow: AssignableWindow): typeof MutationObserver;
export {};
