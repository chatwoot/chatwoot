import RageClick from './extensions/rageclick';
import { Properties, RemoteConfig } from './types';
import { PostHog } from './posthog-core';
type HeatmapEventBuffer = {
    [key: string]: Properties[];
} | undefined;
export declare class Heatmaps {
    instance: PostHog;
    rageclicks: RageClick;
    _enabledServerSide: boolean;
    _initialized: boolean;
    _mouseMoveTimeout: ReturnType<typeof setTimeout> | undefined;
    private _buffer;
    private _flushInterval;
    private _deadClicksCapture;
    constructor(instance: PostHog);
    get flushIntervalMilliseconds(): number;
    get isEnabled(): boolean;
    startIfEnabled(): void;
    onRemoteConfig(response: RemoteConfig): void;
    getAndClearBuffer(): HeatmapEventBuffer;
    private _onDeadClick;
    private _setupListeners;
    private _getProperties;
    private _onClick;
    private _onMouseMove;
    private _capture;
    private _flush;
}
export {};
