import EventEmitter from './event-emitter.js';
type WebAudioPlayerEvents = {
    loadedmetadata: [];
    canplay: [];
    play: [];
    pause: [];
    seeking: [];
    timeupdate: [];
    volumechange: [];
    emptied: [];
    ended: [];
};
/**
 * A Web Audio buffer player emulating the behavior of an HTML5 Audio element.
 */
declare class WebAudioPlayer extends EventEmitter<WebAudioPlayerEvents> {
    private audioContext;
    private gainNode;
    private bufferNode;
    private playStartTime;
    private playedDuration;
    private _muted;
    private _playbackRate;
    private _duration;
    private buffer;
    currentSrc: string;
    paused: boolean;
    crossOrigin: string | null;
    seeking: boolean;
    autoplay: boolean;
    constructor(audioContext?: AudioContext);
    /** Subscribe to an event. Returns an unsubscribe function. */
    addEventListener: <EventName extends keyof WebAudioPlayerEvents>(event: EventName, listener: (...args: WebAudioPlayerEvents[EventName]) => void, options?: {
        once?: boolean;
    }) => () => void;
    /** Unsubscribe from an event */
    removeEventListener: <EventName extends keyof WebAudioPlayerEvents>(event: EventName, listener: (...args: WebAudioPlayerEvents[EventName]) => void) => void;
    load(): Promise<void>;
    get src(): string;
    set src(value: string);
    private _play;
    private _pause;
    play(): Promise<void>;
    pause(): void;
    stopAt(timeSeconds: number): void;
    setSinkId(deviceId: string): Promise<void>;
    get playbackRate(): number;
    set playbackRate(value: number);
    get currentTime(): number;
    set currentTime(value: number);
    get duration(): number;
    set duration(value: number);
    get volume(): number;
    set volume(value: number);
    get muted(): boolean;
    set muted(value: boolean);
    canPlayType(mimeType: string): boolean;
    /** Get the GainNode used to play the audio. Can be used to attach filters. */
    getGainNode(): GainNode;
    /** Get decoded audio */
    getChannelData(): Float32Array[];
}
export default WebAudioPlayer;
