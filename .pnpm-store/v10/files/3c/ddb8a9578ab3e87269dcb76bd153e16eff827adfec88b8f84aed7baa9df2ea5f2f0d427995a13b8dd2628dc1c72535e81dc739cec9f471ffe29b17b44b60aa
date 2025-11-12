import { PostHog } from '../../posthog-core';
import { Properties, RemoteConfig } from '../../types';
import { EventType, type eventWithTime, IncrementalSource } from '@rrweb/types';
import { SAMPLED, SessionRecordingStatus, TriggerType } from './triggerMatching';
type SessionStartReason = 'sampling_overridden' | 'recording_initialized' | 'linked_flag_matched' | 'linked_flag_overridden' | typeof SAMPLED | 'session_id_changed' | 'url_trigger_matched' | 'event_trigger_matched';
export declare const RECORDING_IDLE_THRESHOLD_MS: number;
export declare const RECORDING_MAX_EVENT_SIZE: number;
export declare const RECORDING_BUFFER_TIMEOUT = 2000;
export declare const SESSION_RECORDING_BATCH_KEY = "recordings";
export interface SnapshotBuffer {
    size: number;
    data: any[];
    sessionId: string;
    windowId: string;
}
export type compressedFullSnapshotEvent = {
    type: EventType.FullSnapshot;
    data: string;
};
export type compressedIncrementalSnapshotEvent = {
    type: EventType.IncrementalSnapshot;
    data: {
        source: IncrementalSource;
        texts: string;
        attributes: string;
        removes: string;
        adds: string;
    };
};
export type compressedIncrementalStyleSnapshotEvent = {
    type: EventType.IncrementalSnapshot;
    data: {
        source: IncrementalSource.StyleSheetRule;
        id?: number;
        styleId?: number;
        replace?: string;
        replaceSync?: string;
        adds?: string;
        removes?: string;
    };
};
export type compressedEvent = compressedIncrementalStyleSnapshotEvent | compressedFullSnapshotEvent | compressedIncrementalSnapshotEvent;
export type compressedEventWithTime = compressedEvent & {
    timestamp: number;
    delay?: number;
    cv: '2024-10';
};
export declare class SessionRecording {
    private readonly _instance;
    private _endpoint;
    private _flushBufferTimer?;
    private _statusMatcher;
    private _receivedFlags;
    private _buffer;
    private _queuedRRWebEvents;
    private _mutationThrottler?;
    private _captureStarted;
    private _stopRrweb;
    private _isIdle;
    private _lastActivityTimestamp;
    private _windowId;
    private _sessionId;
    get sessionId(): string;
    private _linkedFlagMatching;
    private _urlTriggerMatching;
    private _eventTriggerMatching;
    private _triggerMatching;
    private _fullSnapshotTimer?;
    private _removePageViewCaptureHook;
    private _onSessionIdListener;
    private _persistFlagsOnSessionListener;
    private _samplingSessionListener;
    private _lastHref?;
    private _removeEventTriggerCaptureHook;
    _forceAllowLocalhostNetworkCapture: boolean;
    private get _sessionIdleThresholdMilliseconds();
    get started(): boolean;
    private get _sessionManager();
    private get _fullSnapshotIntervalMillis();
    private get _isSampled();
    private get _sessionDuration();
    private get _isRecordingEnabled();
    private get _isConsoleLogCaptureEnabled();
    private get _canvasRecording();
    private get _networkPayloadCapture();
    private get _masking();
    private get _sampleRate();
    private get _minimumDuration();
    /**
     * defaults to buffering mode until a flags response is received
     * once a flags response is received status can be disabled, active or sampled
     */
    get status(): SessionRecordingStatus;
    constructor(_instance: PostHog);
    private _onBeforeUnload;
    private _onOffline;
    private _onOnline;
    private _onVisibilityChange;
    startIfEnabledOrStop(startReason?: SessionStartReason): void;
    stopRecording(): void;
    private _resetSampling;
    private _makeSamplingDecision;
    onRemoteConfig(response: RemoteConfig): void;
    /**
     * This might be called more than once so needs to be idempotent
     */
    private _setupSampling;
    private _persistRemoteConfig;
    log(message: string, level?: 'log' | 'warn' | 'error'): void;
    private _startCapture;
    private get _scriptName();
    private _isInteractiveEvent;
    private _updateWindowAndSessionIds;
    private _tryRRWebMethod;
    private _tryAddCustomEvent;
    private _tryTakeFullSnapshot;
    private _onScriptLoaded;
    private _scheduleFullSnapshot;
    private _gatherRRWebPlugins;
    onRRwebEmit(rawEvent: eventWithTime): void;
    private _pageViewFallBack;
    private _processQueuedEvents;
    private _maskUrl;
    private _clearBuffer;
    private _flushBuffer;
    private _captureSnapshotBuffered;
    private _captureSnapshot;
    private _activateTrigger;
    private _pauseRecording;
    private _resumeRecording;
    private _addEventTriggerListener;
    /**
     * this ignores the linked flag config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({linked_flag: true})`
     * */
    overrideLinkedFlag(): void;
    /**
     * this ignores the sampling config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({sampling: true})`
     * */
    overrideSampling(): void;
    /**
     * this ignores the URL/Event trigger config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({trigger: 'url' | 'event'})`
     * */
    overrideTrigger(triggerType: TriggerType): void;
    private _reportStarted;
    get sdkDebugProperties(): Properties;
}
export {};
