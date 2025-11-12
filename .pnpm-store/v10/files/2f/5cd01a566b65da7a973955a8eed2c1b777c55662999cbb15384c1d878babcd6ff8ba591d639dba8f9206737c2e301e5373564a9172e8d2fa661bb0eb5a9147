import { SessionIdChangedCallback } from './types';
import { PostHog } from './posthog-core';
export declare const DEFAULT_SESSION_IDLE_TIMEOUT_SECONDS: number;
export declare const MAX_SESSION_IDLE_TIMEOUT_SECONDS: number;
export declare class SessionIdManager {
    private readonly _sessionIdGenerator;
    private readonly _windowIdGenerator;
    private _config;
    private _persistence;
    private _windowId;
    private _sessionId;
    private readonly _window_id_storage_key;
    private readonly _primary_window_exists_storage_key;
    private _sessionStartTimestamp;
    private _sessionActivityTimestamp;
    private _sessionIdChangedHandlers;
    private readonly _sessionTimeoutMs;
    private _enforceIdleTimeout;
    constructor(instance: PostHog, sessionIdGenerator?: () => string, windowIdGenerator?: () => string);
    get sessionTimeoutMs(): number;
    onSessionId(callback: SessionIdChangedCallback): () => void;
    private _canUseSessionStorage;
    private _setWindowId;
    private _getWindowId;
    private _setSessionId;
    private _getSessionId;
    resetSessionId(): void;
    private _listenToReloadWindow;
    private _sessionHasBeenIdleTooLong;
    checkAndGetSessionAndWindowId(readOnly?: boolean, _timestamp?: number | null): {
        sessionId: string;
        windowId: string;
        sessionStartTimestamp: number;
        changeReason: {
            noSessionId: boolean;
            activityTimeout: boolean;
            sessionPastMaximumLength: boolean;
        } | undefined;
        lastActivityTimestamp: number;
    };
    private _resetIdleTimer;
}
