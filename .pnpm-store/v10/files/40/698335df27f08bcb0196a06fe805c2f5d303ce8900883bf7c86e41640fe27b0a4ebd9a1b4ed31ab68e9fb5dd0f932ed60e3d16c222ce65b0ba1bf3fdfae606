import { PostHog } from '../posthog-core';
import { LazyLoadedDeadClicksAutocaptureInterface } from '../utils/globals';
import { DeadClicksAutoCaptureConfig, RemoteConfig } from '../types';
export declare const isDeadClicksEnabledForHeatmaps: () => boolean;
export declare const isDeadClicksEnabledForAutocapture: (instance: DeadClicksAutocapture) => boolean;
export declare class DeadClicksAutocapture {
    readonly instance: PostHog;
    readonly isEnabled: (dca: DeadClicksAutocapture) => boolean;
    readonly onCapture?: DeadClicksAutoCaptureConfig['__onCapture'];
    get lazyLoadedDeadClicksAutocapture(): LazyLoadedDeadClicksAutocaptureInterface | undefined;
    private _lazyLoadedDeadClicksAutocapture;
    constructor(instance: PostHog, isEnabled: (dca: DeadClicksAutocapture) => boolean, onCapture?: DeadClicksAutoCaptureConfig['__onCapture']);
    onRemoteConfig(response: RemoteConfig): void;
    startIfEnabled(): void;
    private _loadScript;
    private _start;
    stop(): void;
}
