import Channel, { ChannelEvent, ChannelHandler } from '@storybook/channels';
interface Config {
    page: 'manager' | 'preview';
}
export declare const KEY = "storybook-channel";
export declare class PostmsgTransport {
    private readonly config;
    private buffer;
    private handler;
    private connected;
    constructor(config: Config);
    setHandler(handler: ChannelHandler): void;
    /**
     * Sends `event` to the associated window. If the window does not yet exist
     * the event will be stored in a buffer and sent when the window exists.
     * @param event
     */
    send(event: ChannelEvent, options?: any): Promise<any>;
    private flush;
    private getFrames;
    private getCurrentFrames;
    private getLocalFrame;
    private handleEvent;
}
/**
 * Creates a channel which communicates with an iframe or child window.
 */
export default function createChannel({ page }: Config): Channel;
export {};
