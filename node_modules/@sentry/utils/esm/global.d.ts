/**
 * NOTE: In order to avoid circular dependencies, if you add a function to this module and it needs to print something,
 * you must either a) use `console.log` rather than the logger, or b) put your function elsewhere.
 */
import { Integration } from '@sentry/types';
/** Internal */
interface SentryGlobal {
    Sentry?: {
        Integrations?: Integration[];
    };
    SENTRY_ENVIRONMENT?: string;
    SENTRY_DSN?: string;
    SENTRY_RELEASE?: {
        id?: string;
    };
    __SENTRY__: {
        globalEventProcessors: any;
        hub: any;
        logger: any;
    };
}
/**
 * Safely get global scope object
 *
 * @returns Global scope object
 */
export declare function getGlobalObject<T>(): T & SentryGlobal;
/**
 * Returns a global singleton contained in the global `__SENTRY__` object.
 *
 * If the singleton doesn't already exist in `__SENTRY__`, it will be created using the given factory
 * function and added to the `__SENTRY__` object.
 *
 * @param name name of the global singleton on __SENTRY__
 * @param creator creator Factory function to create the singleton if it doesn't already exist on `__SENTRY__`
 * @param obj (Optional) The global object on which to look for `__SENTRY__`, if not `getGlobalObject`'s return value
 * @returns the singleton
 */
export declare function getGlobalSingleton<T>(name: keyof SentryGlobal['__SENTRY__'], creator: () => T, obj?: unknown): T;
export {};
//# sourceMappingURL=global.d.ts.map