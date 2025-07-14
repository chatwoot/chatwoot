import type { Hub } from '@sentry/types';
/**
 * This is for legacy reasons, and returns a proxy object instead of a hub to be used.
 *
 * @deprecated Use the methods directly from the top level Sentry API (e.g. `Sentry.withScope`)
 * For more information see our migration guide for
 * [replacing `getCurrentHub` and `Hub`](https://github.com/getsentry/sentry-javascript/blob/develop/MIGRATION.md#deprecate-hub)
 * usage
 */
export declare function getCurrentHubShim(): Hub;
/**
 * Returns the default hub instance.
 *
 * If a hub is already registered in the global carrier but this module
 * contains a more recent version, it replaces the registered version.
 * Otherwise, the currently registered hub will be returned.
 *
 * @deprecated Use the respective replacement method directly instead.
 */
export declare const getCurrentHub: typeof getCurrentHubShim;
//# sourceMappingURL=getCurrentHubShim.d.ts.map