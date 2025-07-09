/**
 * The Hover plugin follows the mouse and shows a timestamp
 */
import BasePlugin, { type BasePluginEvents } from '../base-plugin.js';
export type HoverPluginOptions = {
    lineColor?: string;
    lineWidth?: string | number;
    labelColor?: string;
    labelSize?: string | number;
    labelBackground?: string;
    formatTimeCallback?: (seconds: number) => string;
};
declare const defaultOptions: {
    lineWidth: number;
    labelSize: number;
    formatTimeCallback(seconds: number): string;
};
export type HoverPluginEvents = BasePluginEvents & {
    hover: [relX: number];
};
declare class HoverPlugin extends BasePlugin<HoverPluginEvents, HoverPluginOptions> {
    protected options: HoverPluginOptions & typeof defaultOptions;
    private wrapper;
    private label;
    private unsubscribe;
    constructor(options?: HoverPluginOptions);
    static create(options?: HoverPluginOptions): HoverPlugin;
    private addUnits;
    /** Called by wavesurfer, don't call manually */
    onInit(): void;
    private onPointerMove;
    private onPointerLeave;
    /** Unmount */
    destroy(): void;
}
export default HoverPlugin;
