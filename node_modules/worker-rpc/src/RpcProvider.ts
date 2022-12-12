import {Event} from 'microevent.ts';

import RpcProviderInterface from './RpcProviderInterface';

const MSG_RESOLVE_TRANSACTION = "resolve_transaction",
    MSG_REJECT_TRANSACTION = "reject_transaction",
    MSG_ERROR = "error";

interface Transaction {
    id: number;
    timeoutHandle?: any;
    resolve(result: any): void;
    reject(error: string): void;
}

class RpcProvider implements RpcProviderInterface {

    constructor(
        private _dispatch: RpcProvider.Dispatcher,
        private _rpcTimeout = 0
    ) {}

    dispatch(payload: any): void {
        const message = payload as RpcProvider.Message;

        switch (message.type) {
            case RpcProvider.MessageType.signal:
                return this._handleSignal(message);

            case RpcProvider.MessageType.rpc:
                return this._handeRpc(message);

            case RpcProvider.MessageType.internal:
                return this._handleInternal(message);

            default:
                this._raiseError(`invalid message type ${message.type}`);
        }
    }

    rpc<T, U>(id: string, payload?: T, transfer?: any): Promise<U> {
        const transactionId = this._nextTransactionId++;

        this._dispatch({
            type: RpcProvider.MessageType.rpc,
            transactionId,
            id,
            payload
        }, transfer ? transfer : undefined);

        return new Promise(
            (resolve, reject) => {
                const transaction = this._pendingTransactions[transactionId] = {
                    id: transactionId,
                    resolve,
                    reject
                };

                if (this._rpcTimeout > 0) {
                    this._pendingTransactions[transactionId].timeoutHandle =
                        setTimeout(() => this._transactionTimeout(transaction), this._rpcTimeout);
                }
            }
        );
    };

    signal<T>(id: string, payload?: T, transfer?: any): this {
        this._dispatch({
            type: RpcProvider.MessageType.signal,
            id,
            payload,
        }, transfer ? transfer : undefined);

        return this;
    }

    registerRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this {
        if (this._rpcHandlers[id]) {
            throw new Error(`rpc handler for ${id} already registered`);
        }

        this._rpcHandlers[id] = handler;

        return this;
    };

    registerSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this {
        if (!this._signalHandlers[id]) {
            this._signalHandlers[id] = [];
        }

        this._signalHandlers[id].push(handler);

        return this;
    }

    deregisterRpcHandler<T, U>(id: string, handler: RpcProviderInterface.RpcHandler<T, U>): this {
        if (this._rpcHandlers[id]) {
            delete this._rpcHandlers[id];
        }

        return this;
    };

    deregisterSignalHandler<T>(id: string, handler: RpcProviderInterface.SignalHandler<T>): this {
        if (this._signalHandlers[id]) {
            this._signalHandlers[id] = this._signalHandlers[id].filter(h => handler !== h);
        }

        return this;
    }

    private _raiseError(error: string): void {
        this.error.dispatch(new Error(error));

        this._dispatch({
            type: RpcProvider.MessageType.internal,
            id: MSG_ERROR,
            payload: error
        });
    }

    private _handleSignal(message: RpcProvider.Message): void {
        if (!this._signalHandlers[message.id]) {
            return this._raiseError(`invalid signal ${message.id}`);
        }

        this._signalHandlers[message.id].forEach(handler => handler(message.payload));
    }

    private _handeRpc(message: RpcProvider.Message): void {
        if (!this._rpcHandlers[message.id]) {
            return this._raiseError(`invalid rpc ${message.id}`);
        }

        Promise.resolve(this._rpcHandlers[message.id](message.payload))
            .then(
                (result: any) => this._dispatch({
                    type: RpcProvider.MessageType.internal,
                    id: MSG_RESOLVE_TRANSACTION,
                    transactionId: message.transactionId,
                    payload: result
                }),
                (reason: string) => this._dispatch({
                    type: RpcProvider.MessageType.internal,
                    id: MSG_REJECT_TRANSACTION,
                    transactionId: message.transactionId,
                    payload: reason
                })
            );
    }

    private _handleInternal(message: RpcProvider.Message): void {
        switch (message.id) {
            case MSG_RESOLVE_TRANSACTION:
                if (!this._pendingTransactions[message.transactionId]) {
                    return this._raiseError(`no pending transaction with id ${message.transactionId}`);
                }

                this._pendingTransactions[message.transactionId].resolve(message.payload);
                this._clearTransaction(this._pendingTransactions[message.transactionId]);

                break;

            case MSG_REJECT_TRANSACTION:
                if (!this._pendingTransactions[message.transactionId]) {
                    return this._raiseError(`no pending transaction with id ${message.transactionId}`);
                }

                this._pendingTransactions[message.transactionId].reject(message.payload);
                this._clearTransaction(this._pendingTransactions[message.transactionId]);

                break;

            case MSG_ERROR:
                this.error.dispatch(new Error(`remote error: ${message.payload}`));
                break;

            default:
                this._raiseError(`unhandled internal message ${message.id}`);
                break;
        }
    }

    private _transactionTimeout(transaction: Transaction): void {
        transaction.reject('transaction timed out');

        this._raiseError(`transaction ${transaction.id} timed out`);

        delete this._pendingTransactions[transaction.id];

        return;
    }

    private _clearTransaction(transaction: Transaction): void {
        if (typeof(transaction.timeoutHandle) !== 'undefined') {
            clearTimeout(transaction.timeoutHandle);
        }

        delete this._pendingTransactions[transaction.id];
    }

    error = new Event<Error>();

    private _rpcHandlers: {[id: string]: RpcProviderInterface.RpcHandler<any, any>} = {};
    private _signalHandlers: {[id: string]: Array<RpcProviderInterface.SignalHandler<any>>} = {};
    private _pendingTransactions: {[id: number]: Transaction} = {};

    private _nextTransactionId = 0;
}

module RpcProvider {

    export enum MessageType {
        signal,
        rpc,
        internal
    };

    export interface Dispatcher {
        (message: Message, transfer?: Array<any>): void;
    }

    export interface Message {
        type: MessageType;
        transactionId?: number;
        id: string;
        payload?: any;
    }

}

export default RpcProvider;
