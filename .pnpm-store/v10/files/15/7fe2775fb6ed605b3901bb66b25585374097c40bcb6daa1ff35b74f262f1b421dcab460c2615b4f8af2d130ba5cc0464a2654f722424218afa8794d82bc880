/**
 * Regions are visual overlays on the waveform that can be used to mark segments of audio.
 * Regions can be clicked on, dragged and resized.
 * You can set the color and content of each region, as well as their HTML content.
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
import EventEmitter from '../event-emitter.js';
export type RegionsPluginOptions = undefined;
export type RegionsPluginEvents = BasePluginEvents & {
    /** When a region is created */
    'region-created': [region: Region];
    /** When a region is being updated */
    'region-update': [region: Region, side?: 'start' | 'end'];
    /** When a region is done updating */
    'region-updated': [region: Region];
    /** When a region is removed */
    'region-removed': [region: Region];
    /** When a region is clicked */
    'region-clicked': [region: Region, e: MouseEvent];
    /** When a region is double-clicked */
    'region-double-clicked': [region: Region, e: MouseEvent];
    /** When playback enters a region */
    'region-in': [region: Region];
    /** When playback leaves a region */
    'region-out': [region: Region];
};
export type RegionEvents = {
    /** Before the region is removed */
    remove: [];
    /** When the region's parameters are being updated */
    update: [side?: 'start' | 'end'];
    /** When dragging or resizing is finished */
    'update-end': [];
    /** On play */
    play: [];
    /** On mouse click */
    click: [event: MouseEvent];
    /** Double click */
    dblclick: [event: MouseEvent];
    /** Mouse over */
    over: [event: MouseEvent];
    /** Mouse leave */
    leave: [event: MouseEvent];
};
export type RegionParams = {
    /** The id of the region, any string */
    id?: string;
    /** The start position of the region (in seconds) */
    start: number;
    /** The end position of the region (in seconds) */
    end?: number;
    /** Allow/dissallow dragging the region */
    drag?: boolean;
    /** Allow/dissallow resizing the region */
    resize?: boolean;
    /** The color of the region (CSS color) */
    color?: string;
    /** Content string or HTML element */
    content?: string | HTMLElement;
    /** Min length when resizing (in seconds) */
    minLength?: number;
    /** Max length when resizing (in seconds) */
    maxLength?: number;
    /** The index of the channel */
    channelIdx?: number;
    /** Allow/Disallow contenteditable property for content */
    contentEditable?: boolean;
};
declare class SingleRegion extends EventEmitter<RegionEvents> implements Region {
    private totalDuration;
    private numberOfChannels;
    element: HTMLElement;
    id: string;
    start: number;
    end: number;
    drag: boolean;
    resize: boolean;
    color: string;
    content?: HTMLElement;
    minLength: number;
    maxLength: number;
    channelIdx: number;
    contentEditable: boolean;
    subscriptions: (() => void)[];
    constructor(params: RegionParams, totalDuration: number, numberOfChannels?: number);
    private clampPosition;
    private setPart;
    private addResizeHandles;
    private removeResizeHandles;
    private initElement;
    private renderPosition;
    private toggleCursor;
    private initMouseEvents;
    _onUpdate(dx: number, side?: 'start' | 'end'): void;
    private onMove;
    private onResize;
    private onEndResizing;
    private onContentClick;
    onContentBlur(): void;
    _setTotalDuration(totalDuration: number): void;
    /** Play the region from the start */
    play(): void;
    /** Set the HTML content of the region */
    setContent(content: RegionParams['content']): void;
    /** Update the region's options */
    setOptions(options: Omit<RegionParams, 'minLength' | 'maxLength'>): void;
    /** Remove the region */
    remove(): void;
}
declare class RegionsPlugin extends BasePlugin<RegionsPluginEvents, RegionsPluginOptions> {
    private regions;
    private regionsContainer;
    /** Create an instance of RegionsPlugin */
    constructor(options?: RegionsPluginOptions);
    /** Create an instance of RegionsPlugin */
    static create(options?: RegionsPluginOptions): RegionsPlugin;
    /** Called by wavesurfer, don't call manually */
    onInit(): void;
    private initRegionsContainer;
    /** Get all created regions */
    getRegions(): Region[];
    private avoidOverlapping;
    private adjustScroll;
    private virtualAppend;
    private saveRegion;
    /** Create a region with given parameters */
    addRegion(options: RegionParams): Region;
    /**
     * Enable creation of regions by dragging on an empty space on the waveform.
     * Returns a function to disable the drag selection.
     */
    enableDragSelection(options: Omit<RegionParams, 'start' | 'end'>, threshold?: number): () => void;
    /** Remove all regions */
    clearRegions(): void;
    /** Destroy the plugin and clean up */
    destroy(): void;
}
export default RegionsPlugin;
export type Region = SingleRegion;
