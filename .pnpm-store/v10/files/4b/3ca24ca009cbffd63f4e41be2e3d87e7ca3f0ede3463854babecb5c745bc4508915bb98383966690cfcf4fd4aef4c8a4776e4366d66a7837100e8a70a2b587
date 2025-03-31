import { Analytics, AnalyticsSettings, InitOptions } from '../core/analytics';
import { Plan } from '../core/events';
import { MetricsOptions } from '../core/stats/remote-metrics';
import { RemotePlugin } from '../plugins/remote-loader';
import type { RoutingRule } from '../plugins/routing-middleware';
import { AnalyticsBuffered } from '../core/buffer';
export interface LegacyIntegrationConfiguration {
    type?: string;
    versionSettings?: {
        version?: string;
        override?: string;
        componentTypes?: Array<'browser' | 'android' | 'ios' | 'server'>;
    };
    bundlingStatus?: string;
    retryQueue?: boolean;
    [key: string]: any;
}
export interface LegacySettings {
    integrations: {
        [name: string]: LegacyIntegrationConfiguration;
    };
    middlewareSettings?: {
        routingRules: RoutingRule[];
    };
    enabledMiddleware?: Record<string, boolean>;
    metrics?: MetricsOptions;
    plan?: Plan;
    legacyVideoPluginsEnabled?: boolean;
    remotePlugins?: RemotePlugin[];
}
export interface AnalyticsBrowserSettings extends AnalyticsSettings {
    /**
     * The settings for the Segment Source.
     * If provided, `AnalyticsBrowser` will not fetch remote settings
     * for the source.
     */
    cdnSettings?: LegacySettings & Record<string, unknown>;
    /**
     * If provided, will override the default Segment CDN (https://cdn.june.so) for this application.
     */
    cdnURL?: string;
}
export declare function loadLegacySettings(cdnURL?: string): LegacySettings;
/**
 * The public browser interface for Segment Analytics
 *
 * @example
 * ```ts
 *  export const analytics = new AnalyticsBrowser()
 *  analytics.load({ writeKey: 'foo' })
 * ```
 * @link https://github.com/segmentio/analytics-next/#readme
 */
export declare class AnalyticsBrowser extends AnalyticsBuffered {
    private _resolveLoadStart;
    constructor();
    /**
     * Fully initialize an analytics instance, including:
     *
     * * Fetching settings from the segment CDN (by default).
     * * Fetching all remote destinations configured by the user (if applicable).
     * * Flushing buffered analytics events.
     * * Loading all middleware.
     *
     * Note:️  This method should only be called *once* in your application.
     *
     * @example
     * ```ts
     * export const analytics = new AnalyticsBrowser()
     * analytics.load({ writeKey: 'foo' })
     * ```
     */
    load(settings: AnalyticsBrowserSettings, options?: InitOptions): AnalyticsBrowser;
    /**
     * Instantiates an object exposing Analytics methods.
     *
     * @example
     * ```ts
     * const ajs = AnalyticsBrowser.load({ writeKey: '<YOUR_WRITE_KEY>' })
     *
     * ajs.track("foo")
     * ...
     * ```
     */
    static load(settings: AnalyticsBrowserSettings, options?: InitOptions): AnalyticsBrowser;
    static standalone(writeKey: string, options?: InitOptions): Promise<Analytics>;
}
//# sourceMappingURL=index.d.ts.map