import { PostHog } from './posthog-core';
import { CaptureResult, Properties, RemoteConfig } from './types';
export declare class PostHogExceptions {
    private readonly _instance;
    private _suppressionRules;
    constructor(instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    private get _captureExtensionExceptions();
    sendExceptionEvent(properties: Properties): CaptureResult | undefined;
    private _matchesSuppressionRule;
    private _isExtensionException;
}
