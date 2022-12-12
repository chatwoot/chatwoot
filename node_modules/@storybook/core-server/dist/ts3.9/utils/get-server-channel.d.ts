import { WebSocketServer } from 'ws';
declare type Server = ConstructorParameters<typeof WebSocketServer>[0]['server'];
export declare class ServerChannel {
    webSocketServer: WebSocketServer;
    constructor(server: Server);
    emit(type: string, args?: any[]): void;
}
export declare function getServerChannel(server: Server): ServerChannel;
export {};
