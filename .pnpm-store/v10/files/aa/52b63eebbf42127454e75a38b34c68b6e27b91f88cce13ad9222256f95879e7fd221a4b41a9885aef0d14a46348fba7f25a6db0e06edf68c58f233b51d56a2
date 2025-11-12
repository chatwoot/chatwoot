import { PostHog } from '../posthog-core';
/**
 * The request router helps simplify the logic to determine which endpoints should be called for which things
 * The basic idea is that for a given region (US or EU), we have a set of endpoints that we should call depending
 * on the type of request (events, replays, flags, etc.) and handle overrides that may come from configs or the flags endpoint
 */
export declare enum RequestRouterRegion {
    US = "us",
    EU = "eu",
    CUSTOM = "custom"
}
export type RequestRouterTarget = 'api' | 'ui' | 'assets';
export declare class RequestRouter {
    instance: PostHog;
    private _regionCache;
    constructor(instance: PostHog);
    get apiHost(): string;
    get uiHost(): string | undefined;
    get region(): RequestRouterRegion;
    endpointFor(target: RequestRouterTarget, path?: string): string;
}
