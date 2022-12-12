import { Event } from 'microevent.ts';
import RpcProviderInterface from './RpcProviderInterface';
declare class RpcProvider implements RpcProviderInterface {
    private _dispatch;
    private _rpcTimeout;
    constructor(_dispatch: RpcProvider.Dispatcher, _rpcTimeout?: number);
    dispatch(payload: any): void;
    rpc<T, U>(id: string, payload?: T, transfer?: any): Promise<U>;
    signal<T>(id: string, payload?: T, transfer?: any): this;
    registerRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this;
    registerSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this;
    deregisterRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this;
    deregisterSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this;
    private _raiseError;
    private _handleSignal;
    private _handeRpc;
    private _handleInternal;
    private _transactionTimeout;
    private _clearTransaction;
    error: Event<Error>;
    private _rpcHandlers;
    private _signalHandlers;
    private _pendingTransactions;
    private _nextTransactionId;
}
declare module RpcProvider {
    enum MessageType {
        signal = 0,
        rpc = 1,
        internal = 2
    }
    interface Dispatcher {
        (message: Message, transfer?: Array<any>): void;
    }
    interface Message {
        type: MessageType;
        transactionId?: number;
        id: string;
        payload?: any;
    }
}
export default RpcProvider;
