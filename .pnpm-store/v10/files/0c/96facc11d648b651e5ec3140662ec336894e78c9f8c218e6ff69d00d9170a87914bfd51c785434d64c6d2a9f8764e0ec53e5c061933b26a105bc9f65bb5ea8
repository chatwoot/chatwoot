import { Client, Integration, MetricsAggregator, Scope } from '@sentry/types';
import { AsyncContextStack } from './asyncContext/stackStrategy';
import { AsyncContextStrategy } from './asyncContext/types';
/**
 * An object that contains globally accessible properties and maintains a scope stack.
 * @hidden
 */
export interface Carrier {
    __SENTRY__?: VersionedCarrier;
}
type VersionedCarrier = {
    version?: string;
} & Record<Exclude<string, 'version'>, SentryCarrier>;
interface SentryCarrier {
    acs?: AsyncContextStrategy;
    stack?: AsyncContextStack;
    globalScope?: Scope;
    defaultIsolationScope?: Scope;
    defaultCurrentScope?: Scope;
    globalMetricsAggregators?: WeakMap<Client, MetricsAggregator> | undefined;
    integrations?: Integration[];
    extensions?: {
        [key: string]: Function;
    };
}
/**
 * Returns the global shim registry.
 *
 * FIXME: This function is problematic, because despite always returning a valid Carrier,
 * it has an optional `__SENTRY__` property, which then in turn requires us to always perform an unnecessary check
 * at the call-site. We always access the carrier through this function, so we can guarantee that `__SENTRY__` is there.
 **/
export declare function getMainCarrier(): Carrier;
/** Will either get the existing sentry carrier, or create a new one. */
export declare function getSentryCarrier(carrier: Carrier): SentryCarrier;
export {};
//# sourceMappingURL=carrier.d.ts.map
