/**
 * Spectrogram plugin
 *
 * Render a spectrogram visualisation of the audio.
 *
 * @author Pavel Denisov (https://github.com/akreal)
 * @see https://github.com/wavesurfer-js/wavesurfer.js/pull/337
 *
 * @example
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     SpectrogramPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
/**
 * Spectrogram plugin for wavesurfer.
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
export type SpectrogramPluginOptions = {
    /** Selector of element or element in which to render */
    container?: string | HTMLElement;
    /** Number of samples to fetch to FFT. Must be a power of 2. */
    fftSamples?: number;
    /** Height of the spectrogram view in CSS pixels */
    height?: number;
    /** Set to true to display frequency labels. */
    labels?: boolean;
    labelsBackground?: string;
    labelsColor?: string;
    labelsHzColor?: string;
    /** Size of the overlapping window. Must be < fftSamples. Auto deduced from canvas size by default. */
    noverlap?: number;
    /** The window function to be used. */
    windowFunc?: 'bartlett' | 'bartlettHann' | 'blackman' | 'cosine' | 'gauss' | 'hamming' | 'hann' | 'lanczoz' | 'rectangular' | 'triangular';
    /** Some window functions have this extra value. (Between 0 and 1) */
    alpha?: number;
    /** Min frequency to scale spectrogram. */
    frequencyMin?: number;
    /** Max frequency to scale spectrogram. Set this to samplerate/2 to draw whole range of spectrogram. */
    frequencyMax?: number;
    /**
     * Based on: https://manual.audacityteam.org/man/spectrogram_settings.html
     * - Linear: Linear The linear vertical scale goes linearly from 0 kHz to 20 kHz frequency by default.
     * - Mel: The name Mel comes from the word melody to indicate that the scale is based on pitch comparisons. This is the default scale.
     */
    scale?: 'linear' | 'mel';
    /**
     * Increases / decreases the brightness of the display.
     * For small signals where the display is mostly "blue" (dark) you can increase this value to see brighter colors and give more detail.
     * If the display has too much "white", decrease this value.
     * The default is 20dB and corresponds to a -20 dB signal at a particular frequency being displayed as "white". */
    gainDB?: number;
    /**
     * Affects the range of signal sizes that will be displayed as colors.
     * The default is 80 dB and means that you will not see anything for signals 80 dB below the value set for "Gain".
     */
    rangeDB?: number;
    /**
     * A 256 long array of 4-element arrays. Each entry should contain a float between 0 and 1 and specify r, g, b, and alpha.
     * Each entry should contain a float between 0 and 1 and specify r, g, b, and alpha.
     * - gray: Gray scale.
     * - igray: Inverted gray scale.
     * - roseus: From https://github.com/dofuuz/roseus/blob/main/roseus/cmap/roseus.py
     */
    colorMap?: number[][] | 'gray' | 'igray' | 'roseus';
    /** Render a spectrogram for each channel independently when true. */
    splitChannels?: boolean;
};
export type SpectrogramPluginEvents = BasePluginEvents & {
    ready: [];
    click: [relativeX: number];
};
declare class SpectrogramPlugin extends BasePlugin<SpectrogramPluginEvents, SpectrogramPluginOptions> {
    static create(options?: SpectrogramPluginOptions): SpectrogramPlugin;
    constructor(options: SpectrogramPluginOptions);
    onInit(): void;
    destroy(): void;
    loadFrequenciesData(url: string | URL): Promise<void>;
    private createWrapper;
    private createCanvas;
    private render;
    private drawSpectrogram;
    private hzToMel;
    private melToHz;
    private createMelFilterBank;
    private applyMelFilterBank;
    private getFrequencies;
    private freqType;
    private unitType;
    private loadLabels;
    private resample;
}
export default SpectrogramPlugin;
