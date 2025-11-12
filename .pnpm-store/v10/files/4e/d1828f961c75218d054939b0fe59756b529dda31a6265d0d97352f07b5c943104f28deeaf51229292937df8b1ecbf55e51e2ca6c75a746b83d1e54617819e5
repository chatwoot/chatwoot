/**
 * Minimap is a tiny copy of the main waveform serving as a navigation tool.
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
import { type WaveSurferOptions } from '../wavesurfer.js';
export type MinimapPluginOptions = {
    overlayColor?: string;
    insertPosition?: InsertPosition;
} & Partial<WaveSurferOptions>;
declare const defaultOptions: {
    height: number;
    overlayColor: string;
    insertPosition: string;
};
export type MinimapPluginEvents = BasePluginEvents & {
    /** An alias of timeupdate but only when the audio is playing */
    audioprocess: [currentTime: number];
    /** When the user clicks on the waveform */
    click: [relativeX: number, relativeY: number];
    /** When the user double-clicks on the waveform */
    dblclick: [relativeX: number, relativeY: number];
    /** When the audio has been decoded */
    decode: [duration: number];
    /** When the user drags the cursor */
    drag: [relativeX: number];
    /** When the user ends dragging the cursor */
    dragend: [relativeX: number];
    /** When the user starts dragging the cursor */
    dragstart: [relativeX: number];
    /** When the user interacts with the waveform (i.g. clicks or drags on it) */
    interaction: [];
    /** After the minimap is created */
    init: [];
    /** When the audio is both decoded and can play */
    ready: [];
    /** When visible waveform is drawn */
    redraw: [];
    /** When all audio channel chunks of the waveform have drawn */
    redrawcomplete: [];
    /** When the user seeks to a new position */
    seeking: [currentTime: number];
    /** On audio position change, fires continuously during playback */
    timeupdate: [currentTime: number];
};
declare class MinimapPlugin extends BasePlugin<MinimapPluginEvents, MinimapPluginOptions> {
    protected options: MinimapPluginOptions & typeof defaultOptions;
    private minimapWrapper;
    private miniWavesurfer;
    private overlay;
    private container;
    constructor(options: MinimapPluginOptions);
    static create(options: MinimapPluginOptions): MinimapPlugin;
    /** Called by wavesurfer, don't call manually */
    onInit(): void;
    private initMinimapWrapper;
    private initOverlay;
    private initMinimap;
    private getOverlayWidth;
    private onRedraw;
    private onScroll;
    private initWaveSurferEvents;
    /** Unmount */
    destroy(): void;
}
export default MinimapPlugin;
