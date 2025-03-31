import { AliasParams, DispatchedEvent, EventParams, GroupParams, PageParams, IdentifyParams } from '../arguments-resolver';
import type { FormArgs, LinkArgs } from '../auto-track';
import { Context } from '../context';
import { Emitter } from '@segment/analytics-core';
import { Integrations, Plan, SegmentEvent } from '../events';
import type { Plugin } from '../plugin';
import { EventQueue } from '../queue/event-queue';
import { CookieOptions, Group, ID, UniversalStorage, User, UserOptions } from '../user';
import type { LegacyIntegration, ClassicIntegrationSource } from '../../plugins/ajs-destination/types';
import type { DestinationMiddlewareFunction, MiddlewareFunction } from '../../plugins/middleware';
import { AnalyticsClassic, AnalyticsCore } from './interfaces';
export interface AnalyticsSettings {
    writeKey: string;
    timeout?: number;
    plugins?: Plugin[];
    classicIntegrations?: ClassicIntegrationSource[];
}
export interface InitOptions {
    /**
     * Disables storing any data on the client-side via cookies or localstorage.
     * Defaults to `false`.
     *
     */
    disableClientPersistence?: boolean;
    /**
     * Disables automatically converting ISO string event properties into Dates.
     * ISO string to Date conversions occur right before sending events to a classic device mode integration,
     * after any destination middleware have been ran.
     * Defaults to `false`.
     */
    disableAutoISOConversion?: boolean;
    initialPageview?: boolean;
    cookie?: CookieOptions;
    user?: UserOptions;
    group?: UserOptions;
    integrations?: Integrations;
    plan?: Plan;
    retryQueue?: boolean;
    obfuscate?: boolean;
    /**
     * Disables or sets constraints on processing of query string parameters
     */
    useQueryString?: boolean | {
        aid?: RegExp;
        uid?: RegExp;
    };
}
declare function _stub(this: never): void;
export declare class Analytics extends Emitter implements AnalyticsCore, AnalyticsClassic {
    protected settings: AnalyticsSettings;
    private _user;
    private _group;
    private eventFactory;
    private _debug;
    private _universalStorage;
    initialized: boolean;
    integrations: Integrations;
    options: InitOptions;
    queue: EventQueue;
    constructor(settings: AnalyticsSettings, options?: InitOptions, queue?: EventQueue, user?: User, group?: Group);
    user: () => User;
    get storage(): UniversalStorage;
    track(...args: EventParams): Promise<DispatchedEvent>;
    page(...args: PageParams): Promise<DispatchedEvent>;
    identify(...args: IdentifyParams): Promise<DispatchedEvent>;
    group(): Group;
    group(...args: GroupParams): Promise<DispatchedEvent>;
    alias(...args: AliasParams): Promise<DispatchedEvent>;
    screen(...args: PageParams): Promise<DispatchedEvent>;
    trackClick(...args: LinkArgs): Promise<Analytics>;
    trackLink(...args: LinkArgs): Promise<Analytics>;
    trackSubmit(...args: FormArgs): Promise<Analytics>;
    trackForm(...args: FormArgs): Promise<Analytics>;
    register(...plugins: Plugin[]): Promise<Context>;
    deregister(...plugins: string[]): Promise<Context>;
    debug(toggle: boolean): Analytics;
    reset(): void;
    timeout(timeout: number): void;
    private _dispatch;
    addSourceMiddleware(fn: MiddlewareFunction): Promise<Analytics>;
    addDestinationMiddleware(integrationName: string, ...middlewares: DestinationMiddlewareFunction[]): Promise<Analytics>;
    setAnonymousId(id?: string): ID;
    queryString(query: string): Promise<Context[]>;
    /**
     * @deprecated This function does not register a destination plugin.
     *
     * Instantiates a legacy Analytics.js destination.
     *
     * This function does not register the destination as an Analytics.JS plugin,
     * all the it does it to invoke the factory function back.
     */
    use(legacyPluginFactory: (analytics: Analytics) => void): Analytics;
    ready(callback?: Function): Promise<unknown>;
    noConflict(): Analytics;
    normalize(msg: SegmentEvent): SegmentEvent;
    get failedInitializations(): string[];
    get VERSION(): string;
    initialize(_settings?: AnalyticsSettings, _options?: InitOptions): Promise<Analytics>;
    init: (_settings?: AnalyticsSettings, _options?: InitOptions) => Promise<Analytics>;
    pageview(url: string): Promise<Analytics>;
    get plugins(): any;
    get Integrations(): Record<string, LegacyIntegration>;
    log: typeof _stub;
    addIntegrationMiddleware: typeof _stub;
    listeners: typeof _stub;
    addEventListener: typeof _stub;
    removeAllListeners: typeof _stub;
    removeListener: typeof _stub;
    removeEventListener: typeof _stub;
    hasListeners: typeof _stub;
    add: typeof _stub;
    addIntegration: typeof _stub;
    push(args: any[]): void;
}
export {};
//# sourceMappingURL=index.d.ts.map