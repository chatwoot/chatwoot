import { Channel, ChannelHandler } from '@storybook/channels';
declare type OnError = (message: Event) => void;
interface WebsocketTransportArgs {
    url: string;
    onError: OnError;
}
interface CreateChannelArgs {
    url: string;
    async?: boolean;
    onError?: OnError;
}
export declare class WebsocketTransport {
    private socket;
    private handler;
    private buffer;
    private isReady;
    constructor({ url, onError }: WebsocketTransportArgs);
    setHandler(handler: ChannelHandler): void;
    send(event: any): void;
    private sendLater;
    private sendNow;
    private flush;
    private connect;
}
export default function createChannel({ url, async, onError, }: CreateChannelArgs): Channel;
export {};
