import { Analytics } from '../analytics';
import { Context } from '../context';
import { AnalyticsBrowserCore } from '../analytics/interfaces';
/**
 * The names of any AnalyticsBrowser methods that also exist on Analytics
 */
export type PreInitMethodName = 'screen' | 'register' | 'deregister' | 'user' | 'trackSubmit' | 'trackClick' | 'trackLink' | 'trackForm' | 'pageview' | 'identify' | 'reset' | 'group' | 'track' | 'ready' | 'alias' | 'debug' | 'page' | 'once' | 'off' | 'on' | 'addSourceMiddleware' | 'setAnonymousId' | 'addDestinationMiddleware';
export declare const flushAddSourceMiddleware: (analytics: Analytics, buffer: PreInitMethodCallBuffer) => Promise<void>;
export declare const flushOn: (analytics: Analytics, buffer: PreInitMethodCallBuffer) => void;
export declare const flushSetAnonymousID: (analytics: Analytics, buffer: PreInitMethodCallBuffer) => void;
export declare const flushAnalyticsCallsInNewTask: (analytics: Analytics, buffer: PreInitMethodCallBuffer) => void;
/**
 *  Represents a buffered method call that occurred before initialization.
 */
export interface PreInitMethodCall<MethodName extends PreInitMethodName = PreInitMethodName> {
    method: MethodName;
    args: PreInitMethodParams<MethodName>;
    called: boolean;
    resolve: (v: ReturnType<Analytics[MethodName]>) => void;
    reject: (reason: any) => void;
}
export type PreInitMethodParams<MethodName extends PreInitMethodName> = Parameters<Analytics[MethodName]>;
/**
 *  Represents any and all the buffered method calls that occurred before initialization.
 */
export declare class PreInitMethodCallBuffer {
    private _value;
    toArray(): PreInitMethodCall[];
    getCalls<T extends PreInitMethodName>(methodName: T): PreInitMethodCall<T>[];
    push(...calls: PreInitMethodCall[]): PreInitMethodCallBuffer;
    clear(): PreInitMethodCallBuffer;
}
/**
 *  Call method and mark as "called"
 *  This function should never throw an error
 */
export declare function callAnalyticsMethod<T extends PreInitMethodName>(analytics: Analytics, call: PreInitMethodCall<T>): Promise<void>;
export type AnalyticsLoader = (preInitBuffer: PreInitMethodCallBuffer) => Promise<[Analytics, Context]>;
export declare class AnalyticsBuffered implements PromiseLike<[Analytics, Context]>, AnalyticsBrowserCore {
    instance?: Analytics;
    ctx?: Context;
    private _preInitBuffer;
    private _promise;
    constructor(loader: AnalyticsLoader);
    then<T1, T2 = never>(...args: [
        onfulfilled: ((instance: [Analytics, Context]) => T1 | PromiseLike<T1>) | null | undefined,
        onrejected?: (reason: unknown) => T2 | PromiseLike<T2>
    ]): Promise<T1 | T2>;
    catch<TResult = never>(...args: [
        onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null
    ]): Promise<[Analytics, Context] | TResult>;
    finally(...args: [onfinally?: (() => void) | undefined | null]): Promise<[Analytics, Context]>;
    trackSubmit: (forms: HTMLFormElement | HTMLFormElement[] | null, event: string | Function, properties?: Function | import("../events").EventProperties | undefined, options?: import("../events").Options | undefined) => Promise<Analytics>;
    trackClick: (links: Element | Element[] | import("../auto-track").JQueryShim<HTMLElement> | null, event: string | Function, properties?: Function | import("../events").EventProperties | undefined, options?: import("../events").Options | undefined) => Promise<Analytics>;
    trackLink: (links: Element | Element[] | import("../auto-track").JQueryShim<HTMLElement> | null, event: string | Function, properties?: Function | import("../events").EventProperties | undefined, options?: import("../events").Options | undefined) => Promise<Analytics>;
    pageView: (url: string) => Promise<Analytics>;
    identify: (id?: object | import("../user").ID, traits?: import("@segment/analytics-core").UserTraits | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | null | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined) => Promise<Context>;
    reset: () => Promise<void>;
    group: {
        (): Promise<import("../user").Group>;
        (id?: object | import("../user").ID, traits?: import("@segment/analytics-core").GroupTraits | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | null | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined): Promise<Context>;
    };
    track: (eventName: string | import("../events").SegmentEvent, properties?: import("../events").EventProperties | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined) => Promise<Context>;
    ready: (callback?: Function | undefined) => Promise<unknown>;
    alias: (to: string | number, from?: string | number | import("../events").Options | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined) => Promise<Context>;
    debug: (toggle: boolean) => AnalyticsBuffered;
    page: (category?: string | object | undefined, name?: string | object | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, properties?: import("../events").Options | import("../events").EventProperties | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | null | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined) => Promise<Context>;
    once: (event: string, callback: (...args: any[]) => void) => AnalyticsBuffered;
    off: (event: string, callback: (...args: any[]) => void) => AnalyticsBuffered;
    on: (event: string, callback: (...args: any[]) => void) => AnalyticsBuffered;
    addSourceMiddleware: (fn: import("../../plugins/middleware").MiddlewareFunction) => Promise<Analytics>;
    setAnonymousId: (id?: string | undefined) => Promise<import("../user").ID>;
    addDestinationMiddleware: (integrationName: string, ...middlewares: import("../../plugins/middleware").DestinationMiddlewareFunction[]) => Promise<Analytics>;
    screen: (category?: string | object | undefined, name?: string | object | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, properties?: import("../events").Options | import("../events").EventProperties | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | null | undefined, options?: import("../events").Options | import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined, callback?: import("@segment/analytics-core").Callback<import("@segment/analytics-core").CoreContext<import("@segment/analytics-core").CoreSegmentEvent>> | undefined) => Promise<Context>;
    register: (...args: import("../plugin").Plugin[]) => Promise<Context>;
    deregister: (...args: string[]) => Promise<Context>;
    user: () => Promise<import("../user").User>;
    readonly VERSION = "2.0.0";
    private _createMethod;
    /**
     *  These are for methods that where determining when the method gets "flushed" is not important.
     *  These methods will resolve when analytics is fully initialized, and return type (other than Analytics)will not be available.
     */
    private _createChainableMethod;
}
//# sourceMappingURL=index.d.ts.map