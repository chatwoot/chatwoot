import EventEmitter from './event-emitter.js';
import type WaveSurfer from './wavesurfer.js';
export type BasePluginEvents = {
    destroy: [];
};
export type GenericPlugin = BasePlugin<BasePluginEvents, unknown>;
/** Base class for wavesurfer plugins */
export declare class BasePlugin<EventTypes extends BasePluginEvents, Options> extends EventEmitter<EventTypes> {
    protected wavesurfer?: WaveSurfer;
    protected subscriptions: (() => void)[];
    protected options: Options;
    /** Create a plugin instance */
    constructor(options: Options);
    /** Called after this.wavesurfer is available */
    protected onInit(): void;
    /** Do not call directly, only called by WavesSurfer internally */
    _init(wavesurfer: WaveSurfer): void;
    /** Destroy the plugin and unsubscribe from all events */
    destroy(): void;
}
export default BasePlugin;
