import { PostHog } from '../../posthog-core';
import { FlagVariant, RemoteConfig, SessionRecordingUrlTrigger } from '../../types';
export declare const DISABLED = "disabled";
export declare const SAMPLED = "sampled";
export declare const ACTIVE = "active";
export declare const BUFFERING = "buffering";
export declare const PAUSED = "paused";
export declare const TRIGGER_ACTIVATED: string;
export declare const TRIGGER_PENDING: string;
export declare const TRIGGER_DISABLED: string;
export interface RecordingTriggersStatus {
    get receivedFlags(): boolean;
    get isRecordingEnabled(): false | true | undefined;
    get isSampled(): false | true | null;
    get urlTriggerMatching(): URLTriggerMatching;
    get eventTriggerMatching(): EventTriggerMatching;
    get linkedFlagMatching(): LinkedFlagMatching;
    get sessionId(): string;
}
export type TriggerType = 'url' | 'event';
declare const triggerStatuses: readonly [string, string, string];
export type TriggerStatus = (typeof triggerStatuses)[number];
/**
 * Session recording starts in buffering mode while waiting for "flags response".
 * Once the response is received, it might be disabled, active or sampled.
 * When "sampled" that means a sample rate is set, and the last time the session ID rotated
 * the sample rate determined this session should be sent to the server.
 */
declare const sessionRecordingStatuses: readonly ["disabled", "sampled", "active", "buffering", "paused"];
export type SessionRecordingStatus = (typeof sessionRecordingStatuses)[number];
export interface TriggerStatusMatching {
    triggerStatus(sessionId: string): TriggerStatus;
    stop(): void;
}
export declare class OrTriggerMatching implements TriggerStatusMatching {
    private readonly _matchers;
    constructor(_matchers: TriggerStatusMatching[]);
    triggerStatus(sessionId: string): TriggerStatus;
    stop(): void;
}
export declare class AndTriggerMatching implements TriggerStatusMatching {
    private readonly _matchers;
    constructor(_matchers: TriggerStatusMatching[]);
    triggerStatus(sessionId: string): TriggerStatus;
    stop(): void;
}
export declare class PendingTriggerMatching implements TriggerStatusMatching {
    triggerStatus(): TriggerStatus;
    stop(): void;
}
export declare class URLTriggerMatching implements TriggerStatusMatching {
    private readonly _instance;
    _urlTriggers: SessionRecordingUrlTrigger[];
    _urlBlocklist: SessionRecordingUrlTrigger[];
    urlBlocked: boolean;
    constructor(_instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    private _urlTriggerStatus;
    triggerStatus(sessionId: string): TriggerStatus;
    checkUrlTriggerConditions(onPause: () => void, onResume: () => void, onActivate: (triggerType: TriggerType) => void): void;
    stop(): void;
}
export declare class LinkedFlagMatching implements TriggerStatusMatching {
    private readonly _instance;
    linkedFlag: string | FlagVariant | null;
    linkedFlagSeen: boolean;
    private _flaglistenerCleanup;
    constructor(_instance: PostHog);
    triggerStatus(): TriggerStatus;
    onRemoteConfig(response: RemoteConfig, onStarted: (flag: string, variant: string | null) => void): void;
    stop(): void;
}
export declare class EventTriggerMatching implements TriggerStatusMatching {
    private readonly _instance;
    _eventTriggers: string[];
    constructor(_instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    private _eventTriggerStatus;
    triggerStatus(sessionId: string): TriggerStatus;
    stop(): void;
}
export declare function nullMatchSessionRecordingStatus(triggersStatus: RecordingTriggersStatus): SessionRecordingStatus;
export declare function anyMatchSessionRecordingStatus(triggersStatus: RecordingTriggersStatus): SessionRecordingStatus;
export declare function allMatchSessionRecordingStatus(triggersStatus: RecordingTriggersStatus): SessionRecordingStatus;
export {};
