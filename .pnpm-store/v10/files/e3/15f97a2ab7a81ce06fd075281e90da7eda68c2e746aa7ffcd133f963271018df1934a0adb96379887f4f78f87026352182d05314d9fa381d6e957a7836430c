/**
 * The Timeline plugin adds timestamps and notches under the waveform.
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
export type TimelinePluginOptions = {
    /** The height of the timeline in pixels, defaults to 20 */
    height?: number;
    /** HTML element or selector for a timeline container, defaults to wavesufer's container */
    container?: HTMLElement | string;
    /** Pass 'beforebegin' to insert the timeline on top of the waveform */
    insertPosition?: InsertPosition;
    /** The duration of the timeline in seconds, defaults to wavesurfer's duration */
    duration?: number;
    /** Interval between ticks in seconds */
    timeInterval?: number;
    /** Interval between numeric labels in seconds */
    primaryLabelInterval?: number;
    /** Interval between secondary numeric labels in seconds */
    secondaryLabelInterval?: number;
    /** Interval between numeric labels in timeIntervals (i.e notch count) */
    primaryLabelSpacing?: number;
    /** Interval between secondary numeric labels  in timeIntervals (i.e notch count) */
    secondaryLabelSpacing?: number;
    /** Custom inline style to apply to the container */
    style?: Partial<CSSStyleDeclaration> | string;
    /** Turn the time into a suitable label for the time. */
    formatTimeCallback?: (seconds: number) => string;
    /** Opacity of the secondary labels, defaults to 0.25 */
    secondaryLabelOpacity?: number;
};
declare const defaultOptions: {
    height: number;
    formatTimeCallback: (seconds: number) => string;
};
export type TimelinePluginEvents = BasePluginEvents & {
    ready: [];
};
declare class TimelinePlugin extends BasePlugin<TimelinePluginEvents, TimelinePluginOptions> {
    private timelineWrapper;
    protected options: TimelinePluginOptions & typeof defaultOptions;
    constructor(options?: TimelinePluginOptions);
    static create(options?: TimelinePluginOptions): TimelinePlugin;
    /** Called by wavesurfer, don't call manually */
    onInit(): void;
    /** Unmount */
    destroy(): void;
    private initTimelineWrapper;
    private defaultTimeInterval;
    private defaultPrimaryLabelInterval;
    private defaultSecondaryLabelInterval;
    private virtualAppend;
    private initTimeline;
}
export default TimelinePlugin;
