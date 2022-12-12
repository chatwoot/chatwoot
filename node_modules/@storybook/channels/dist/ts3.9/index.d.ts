export declare type ChannelHandler = (event: ChannelEvent) => void;
export interface ChannelTransport {
    send(event: ChannelEvent, options?: any): void;
    setHandler(handler: ChannelHandler): void;
}
export interface ChannelEvent {
    type: string;
    from: string;
    args: any[];
}
export interface Listener {
    (...args: any[]): void;
}
interface ChannelArgs {
    transport?: ChannelTransport;
    async?: boolean;
}
export declare class Channel {
    readonly isAsync: boolean;
    private sender;
    private events;
    private data;
    private readonly transport;
    constructor({ transport, async }?: ChannelArgs);
    get hasTransport(): boolean;
    addListener(eventName: string, listener: Listener): void;
    addPeerListener: (eventName: string, listener: Listener) => void;
    emit(eventName: string, ...args: any): void;
    last(eventName: string): any;
    eventNames(): string[];
    listenerCount(eventName: string): number;
    listeners(eventName: string): Listener[] | undefined;
    once(eventName: string, listener: Listener): void;
    removeAllListeners(eventName?: string): void;
    removeListener(eventName: string, listener: Listener): void;
    on(eventName: string, listener: Listener): void;
    off(eventName: string, listener: Listener): void;
    private handleEvent;
    private onceListener;
}
export default Channel;
