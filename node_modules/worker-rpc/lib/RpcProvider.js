"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var microevent_ts_1 = require("microevent.ts");
var MSG_RESOLVE_TRANSACTION = "resolve_transaction", MSG_REJECT_TRANSACTION = "reject_transaction", MSG_ERROR = "error";
var RpcProvider = /** @class */ (function () {
    function RpcProvider(_dispatch, _rpcTimeout) {
        if (_rpcTimeout === void 0) { _rpcTimeout = 0; }
        this._dispatch = _dispatch;
        this._rpcTimeout = _rpcTimeout;
        this.error = new microevent_ts_1.Event();
        this._rpcHandlers = {};
        this._signalHandlers = {};
        this._pendingTransactions = {};
        this._nextTransactionId = 0;
    }
    RpcProvider.prototype.dispatch = function (payload) {
        var message = payload;
        switch (message.type) {
            case RpcProvider.MessageType.signal:
                return this._handleSignal(message);
            case RpcProvider.MessageType.rpc:
                return this._handeRpc(message);
            case RpcProvider.MessageType.internal:
                return this._handleInternal(message);
            default:
                this._raiseError("invalid message type " + message.type);
        }
    };
    RpcProvider.prototype.rpc = function (id, payload, transfer) {
        var _this = this;
        var transactionId = this._nextTransactionId++;
        this._dispatch({
            type: RpcProvider.MessageType.rpc,
            transactionId: transactionId,
            id: id,
            payload: payload
        }, transfer ? transfer : undefined);
        return new Promise(function (resolve, reject) {
            var transaction = _this._pendingTransactions[transactionId] = {
                id: transactionId,
                resolve: resolve,
                reject: reject
            };
            if (_this._rpcTimeout > 0) {
                _this._pendingTransactions[transactionId].timeoutHandle =
                    setTimeout(function () { return _this._transactionTimeout(transaction); }, _this._rpcTimeout);
            }
        });
    };
    ;
    RpcProvider.prototype.signal = function (id, payload, transfer) {
        this._dispatch({
            type: RpcProvider.MessageType.signal,
            id: id,
            payload: payload,
        }, transfer ? transfer : undefined);
        return this;
    };
    RpcProvider.prototype.registerRpcHandler = function (id, handler) {
        if (this._rpcHandlers[id]) {
            throw new Error("rpc handler for " + id + " already registered");
        }
        this._rpcHandlers[id] = handler;
        return this;
    };
    ;
    RpcProvider.prototype.registerSignalHandler = function (id, handler) {
        if (!this._signalHandlers[id]) {
            this._signalHandlers[id] = [];
        }
        this._signalHandlers[id].push(handler);
        return this;
    };
    RpcProvider.prototype.deregisterRpcHandler = function (id, handler) {
        if (this._rpcHandlers[id]) {
            delete this._rpcHandlers[id];
        }
        return this;
    };
    ;
    RpcProvider.prototype.deregisterSignalHandler = function (id, handler) {
        if (this._signalHandlers[id]) {
            this._signalHandlers[id] = this._signalHandlers[id].filter(function (h) { return handler !== h; });
        }
        return this;
    };
    RpcProvider.prototype._raiseError = function (error) {
        this.error.dispatch(new Error(error));
        this._dispatch({
            type: RpcProvider.MessageType.internal,
            id: MSG_ERROR,
            payload: error
        });
    };
    RpcProvider.prototype._handleSignal = function (message) {
        if (!this._signalHandlers[message.id]) {
            return this._raiseError("invalid signal " + message.id);
        }
        this._signalHandlers[message.id].forEach(function (handler) { return handler(message.payload); });
    };
    RpcProvider.prototype._handeRpc = function (message) {
        var _this = this;
        if (!this._rpcHandlers[message.id]) {
            return this._raiseError("invalid rpc " + message.id);
        }
        Promise.resolve(this._rpcHandlers[message.id](message.payload))
            .then(function (result) { return _this._dispatch({
            type: RpcProvider.MessageType.internal,
            id: MSG_RESOLVE_TRANSACTION,
            transactionId: message.transactionId,
            payload: result
        }); }, function (reason) { return _this._dispatch({
            type: RpcProvider.MessageType.internal,
            id: MSG_REJECT_TRANSACTION,
            transactionId: message.transactionId,
            payload: reason
        }); });
    };
    RpcProvider.prototype._handleInternal = function (message) {
        switch (message.id) {
            case MSG_RESOLVE_TRANSACTION:
                if (!this._pendingTransactions[message.transactionId]) {
                    return this._raiseError("no pending transaction with id " + message.transactionId);
                }
                this._pendingTransactions[message.transactionId].resolve(message.payload);
                this._clearTransaction(this._pendingTransactions[message.transactionId]);
                break;
            case MSG_REJECT_TRANSACTION:
                if (!this._pendingTransactions[message.transactionId]) {
                    return this._raiseError("no pending transaction with id " + message.transactionId);
                }
                this._pendingTransactions[message.transactionId].reject(message.payload);
                this._clearTransaction(this._pendingTransactions[message.transactionId]);
                break;
            case MSG_ERROR:
                this.error.dispatch(new Error("remote error: " + message.payload));
                break;
            default:
                this._raiseError("unhandled internal message " + message.id);
                break;
        }
    };
    RpcProvider.prototype._transactionTimeout = function (transaction) {
        transaction.reject('transaction timed out');
        this._raiseError("transaction " + transaction.id + " timed out");
        delete this._pendingTransactions[transaction.id];
        return;
    };
    RpcProvider.prototype._clearTransaction = function (transaction) {
        if (typeof (transaction.timeoutHandle) !== 'undefined') {
            clearTimeout(transaction.timeoutHandle);
        }
        delete this._pendingTransactions[transaction.id];
    };
    return RpcProvider;
}());
(function (RpcProvider) {
    var MessageType;
    (function (MessageType) {
        MessageType[MessageType["signal"] = 0] = "signal";
        MessageType[MessageType["rpc"] = 1] = "rpc";
        MessageType[MessageType["internal"] = 2] = "internal";
    })(MessageType = RpcProvider.MessageType || (RpcProvider.MessageType = {}));
    ;
})(RpcProvider || (RpcProvider = {}));
exports.default = RpcProvider;
