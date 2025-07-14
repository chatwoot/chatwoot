/**
 * Record audio from the microphone with a real-time waveform preview
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
export type RecordPluginOptions = {
    /** The MIME type to use when recording audio */
    mimeType?: MediaRecorderOptions['mimeType'];
    /** The audio bitrate to use when recording audio, defaults to 128000 to avoid a VBR encoding. */
    audioBitsPerSecond?: MediaRecorderOptions['audioBitsPerSecond'];
    /** Whether to render the recorded audio at the end, true by default */
    renderRecordedAudio?: boolean;
    /** Whether to render the scrolling waveform, false by default */
    scrollingWaveform?: boolean;
    /** The duration of the scrolling waveform window, defaults to 5 seconds */
    scrollingWaveformWindow?: number;
    /** Accumulate and render the waveform data as the audio is being recorded, false by default */
    continuousWaveform?: boolean;
    /** The duration of the continuous waveform, in seconds */
    continuousWaveformDuration?: number;
    /** The timeslice to use for the media recorder */
    mediaRecorderTimeslice?: number;
};
export type RecordPluginDeviceOptions = {
    /** The device ID of the microphone to use */
    deviceId?: string | {
        exact: string;
    };
};
export type RecordPluginEvents = BasePluginEvents & {
    /** Fires when the recording starts */
    'record-start': [];
    /** Fires when the recording is paused */
    'record-pause': [blob: Blob];
    /** Fires when the recording is resumed */
    'record-resume': [];
    'record-end': [blob: Blob];
    /** Fires continuously while recording */
    'record-progress': [duration: number];
    /** On every new recorded chunk */
    'record-data-available': [blob: Blob];
};
type MicStream = {
    onDestroy: () => void;
    onEnd: () => void;
};
declare class RecordPlugin extends BasePlugin<RecordPluginEvents, RecordPluginOptions> {
    private stream;
    private mediaRecorder;
    private dataWindow;
    private isWaveformPaused;
    private originalOptions?;
    private timer;
    private lastStartTime;
    private lastDuration;
    private duration;
    /** Create an instance of the Record plugin */
    constructor(options: RecordPluginOptions);
    /** Create an instance of the Record plugin */
    static create(options?: RecordPluginOptions): RecordPlugin;
    renderMicStream(stream: MediaStream): MicStream;
    /** Request access to the microphone and start monitoring incoming audio */
    startMic(options?: RecordPluginDeviceOptions): Promise<MediaStream>;
    /** Stop monitoring incoming audio */
    stopMic(): void;
    /** Start recording audio from the microphone */
    startRecording(options?: RecordPluginDeviceOptions): Promise<void>;
    /** Get the duration of the recording */
    getDuration(): number;
    /** Check if the audio is being recorded */
    isRecording(): boolean;
    isPaused(): boolean;
    isActive(): boolean;
    /** Stop the recording */
    stopRecording(): void;
    /** Pause the recording */
    pauseRecording(): void;
    /** Resume the recording */
    resumeRecording(): void;
    /** Get a list of available audio devices
     * You can use this to get the device ID of the microphone to use with the startMic and startRecording methods
     * Will return an empty array if the browser doesn't support the MediaDevices API or if the user has not granted access to the microphone
     * You can ask for permission to the microphone by calling startMic
     */
    static getAvailableAudioDevices(): Promise<MediaDeviceInfo[]>;
    /** Destroy the plugin */
    destroy(): void;
    private applyOriginalOptionsIfNeeded;
}
export default RecordPlugin;
