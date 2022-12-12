import {EventInterface} from 'microevent.ts';

interface RpcProviderInterface {

    dispatch(message: any): void;

    rpc<T, U>(id: string, payload?: T, transfer?: Array<any>): Promise<U>;

    signal<T>(id: string, payload?: T, transfer?: Array<any>): this;

    registerRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this;

    registerSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this;

    deregisterRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this;

    deregisterSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this;

    error: EventInterface<Error>;

}

module RpcProviderInterface {

    export interface RpcHandler<T, U> {
        (payload?: T): Promise<U>|U;
    }

    export interface SignalHandler<T> {
        (payload?: T): void;
    }

}

export default RpcProviderInterface;
