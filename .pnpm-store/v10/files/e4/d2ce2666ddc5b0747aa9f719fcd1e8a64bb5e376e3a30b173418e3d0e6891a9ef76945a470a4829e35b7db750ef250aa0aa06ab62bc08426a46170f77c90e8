import { ErrorProperties } from '../extensions/exception-autocapture/error-conversion';
import type { PostHog } from '../posthog-core';
import { SessionIdManager } from '../sessionid';
import { DeadClicksAutoCaptureConfig, ExternalIntegrationKind, RemoteConfig, SiteAppLoader } from '../types';
declare const win: (Window & typeof globalThis) | undefined;
export type AssignableWindow = Window & typeof globalThis & {
    posthog: any;
    __PosthogExtensions__?: PostHogExtensions;
    /**
     * When loading remote config, we assign it to this global configuration
     * for ease of sharing it with the rest of the SDK
     */
    _POSTHOG_REMOTE_CONFIG?: Record<string, {
        config: RemoteConfig;
        siteApps: SiteAppLoader[];
    }>;
    /**
     * If this is set on the window, our logger will log to the console
     * for ease of debugging. Used for testing purposes only.
     *
     * @see {Config.DEBUG} from config.ts
     */
    POSTHOG_DEBUG: any;
    doNotTrack: any;
    posthogCustomizations: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/exception-autocapture.ts
     *
     * @deprecated use `__PosthogExtensions__.errorWrappingFunctions` instead
     */
    posthogErrorWrappingFunctions: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/posthog-recorder.ts
     *
     * @deprecated use `__PosthogExtensions__.rrweb` instead
     */
    rrweb: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/posthog-recorder.ts
     *
     * @deprecated use `__PosthogExtensions__.rrwebConsoleRecord` instead
     */
    rrwebConsoleRecord: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/posthog-recorder.ts
     *
     * @deprecated use `__PosthogExtensions__.getRecordNetworkPlugin` instead
     */
    getRecordNetworkPlugin: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/web-vitals.ts
     *
     * @deprecated use `__PosthogExtensions__.postHogWebVitalsCallbacks` instead
     */
    postHogWebVitalsCallbacks: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/tracing-headers.ts
     *
     * @deprecated use `__PosthogExtensions__.postHogTracingHeadersPatchFns` instead
     */
    postHogTracingHeadersPatchFns: any;
    /**
     * This is a legacy way to expose these functions, but we still need to support it for backwards compatibility
     * Can be removed once we drop support for 1.161.1
     *
     * See entrypoints/surveys.ts
     *
     * @deprecated use `__PosthogExtensions__.generateSurveys` instead
     */
    extendPostHogWithSurveys: any;
    ph_load_toolbar: any;
    ph_load_editor: any;
    ph_toolbar_state: any;
} & Record<`__$$ph_site_app_${string}`, any>;
/**
 * This is our contract between (potentially) lazily loaded extensions and the SDK
 * changes to this interface can be breaking changes for users of the SDK
 */
export type ExternalExtensionKind = 'intercom-integration' | 'crisp-chat-integration';
export type PostHogExtensionKind = 'toolbar' | 'exception-autocapture' | 'web-vitals' | 'recorder' | 'tracing-headers' | 'surveys' | 'dead-clicks-autocapture' | 'remote-config' | ExternalExtensionKind;
export interface LazyLoadedDeadClicksAutocaptureInterface {
    start: (observerTarget: Node) => void;
    stop: () => void;
}
interface PostHogExtensions {
    loadExternalDependency?: (posthog: PostHog, kind: PostHogExtensionKind, callback: (error?: string | Event, event?: Event) => void) => void;
    loadSiteApp?: (posthog: PostHog, appUrl: string, callback: (error?: string | Event, event?: Event) => void) => void;
    errorWrappingFunctions?: {
        wrapOnError: (captureFn: (props: ErrorProperties) => void) => () => void;
        wrapUnhandledRejection: (captureFn: (props: ErrorProperties) => void) => () => void;
        wrapConsoleError: (captureFn: (props: ErrorProperties) => void) => () => void;
    };
    rrweb?: {
        record: any;
        version: string;
    };
    rrwebPlugins?: {
        getRecordConsolePlugin: any;
        getRecordNetworkPlugin?: any;
    };
    generateSurveys?: (posthog: PostHog, isSurveysEnabled: boolean) => any | undefined;
    postHogWebVitalsCallbacks?: {
        onLCP: (metric: any) => void;
        onCLS: (metric: any) => void;
        onFCP: (metric: any) => void;
        onINP: (metric: any) => void;
    };
    tracingHeadersPatchFns?: {
        _patchFetch: (hostnames: string[], distinctId: string, sessionManager?: SessionIdManager) => () => void;
        _patchXHR: (hostnames: string[], distinctId: string, sessionManager?: SessionIdManager) => () => void;
    };
    initDeadClicksAutocapture?: (ph: PostHog, config: DeadClicksAutoCaptureConfig) => LazyLoadedDeadClicksAutocaptureInterface;
    integrations?: {
        [K in ExternalIntegrationKind]?: {
            start: (posthog: PostHog) => void;
            stop: () => void;
        };
    };
}
export declare const ArrayProto: any[];
export declare const nativeForEach: (callbackfn: (value: any, index: number, array: any[]) => void, thisArg?: any) => void;
export declare const nativeIndexOf: (searchElement: any, fromIndex?: number) => number;
export declare const navigator: Navigator | undefined;
export declare const document: Document | undefined;
export declare const location: Location | undefined;
export declare const fetch: typeof globalThis.fetch | undefined;
export declare const XMLHttpRequest: {
    new (): XMLHttpRequest;
    prototype: XMLHttpRequest;
    readonly UNSENT: 0;
    readonly OPENED: 1;
    readonly HEADERS_RECEIVED: 2;
    readonly LOADING: 3;
    readonly DONE: 4;
} | undefined;
export declare const AbortController: {
    new (): AbortController;
    prototype: AbortController;
} | undefined;
export declare const userAgent: string | undefined;
export declare const assignableWindow: AssignableWindow;
export { win as window };
