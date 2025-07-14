import EventEmitter, { type GeneralEventTypes } from './event-emitter.js';
type PlayerOptions = {
    media?: HTMLMediaElement;
    mediaControls?: boolean;
    autoplay?: boolean;
    playbackRate?: number;
};
declare class Player<T extends GeneralEventTypes> extends EventEmitter<T> {
    protected media: HTMLMediaElement;
    private isExternalMedia;
    constructor(options: PlayerOptions);
    protected onMediaEvent<K extends keyof HTMLElementEventMap>(event: K, callback: (ev: HTMLElementEventMap[K]) => void, options?: boolean | AddEventListenerOptions): () => void;
    protected getSrc(): string;
    private revokeSrc;
    private canPlayType;
    protected setSrc(url: string, blob?: Blob): void;
    protected destroy(): void;
    protected setMediaElement(element: HTMLMediaElement): void;
    /** Start playing the audio */
    play(): Promise<void>;
    /** Pause the audio */
    pause(): void;
    /** Check if the audio is playing */
    isPlaying(): boolean;
    /** Jump to a specific time in the audio (in seconds) */
    setTime(time: number): void;
    /** Get the duration of the audio in seconds */
    getDuration(): number;
    /** Get the current audio position in seconds */
    getCurrentTime(): number;
    /** Get the audio volume */
    getVolume(): number;
    /** Set the audio volume */
    setVolume(volume: number): void;
    /** Get the audio muted state */
    getMuted(): boolean;
    /** Mute or unmute the audio */
    setMuted(muted: boolean): void;
    /** Get the playback speed */
    getPlaybackRate(): number;
    /** Check if the audio is seeking */
    isSeeking(): boolean;
    /** Set the playback speed, pass an optional false to NOT preserve the pitch */
    setPlaybackRate(rate: number, preservePitch?: boolean): void;
    /** Get the HTML media element */
    getMediaElement(): HTMLMediaElement;
    /** Set a sink id to change the audio output device */
    setSinkId(sinkId: string): Promise<void>;
}
export default Player;
