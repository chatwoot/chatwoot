import { PostHog } from '../../posthog-core';
import { RemoteConfig } from '../../types';
import { ErrorProperties } from './error-conversion';
export declare class ExceptionObserver {
    private _instance;
    private _rateLimiter;
    private _remoteEnabled;
    private _config;
    private _unwrapOnError;
    private _unwrapUnhandledRejection;
    private _unwrapConsoleError;
    constructor(instance: PostHog);
    private _requiredConfig;
    get isEnabled(): boolean;
    startIfEnabled(): void;
    private _loadScript;
    private _startCapturing;
    private _stopCapturing;
    onRemoteConfig(response: RemoteConfig): void;
    captureException(errorProperties: ErrorProperties): void;
}
