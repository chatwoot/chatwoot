import { __awaiter, __generator } from "tslib";
import { isThenable } from '../../lib/is-thenable';
import { version } from '../../generated/version';
var flushSyncAnalyticsCalls = function (name, analytics, buffer) {
    buffer.getCalls(name).forEach(function (c) {
        // While the underlying methods are synchronous, the callAnalyticsMethod returns a promise,
        // which normalizes success and error states between async and non-async methods, with no perf penalty.
        callAnalyticsMethod(analytics, c).catch(console.error);
    });
};
export var flushAddSourceMiddleware = function (analytics, buffer) { return __awaiter(void 0, void 0, void 0, function () {
    var _i, _a, c;
    return __generator(this, function (_b) {
        switch (_b.label) {
            case 0:
                _i = 0, _a = buffer.getCalls('addSourceMiddleware');
                _b.label = 1;
            case 1:
                if (!(_i < _a.length)) return [3 /*break*/, 4];
                c = _a[_i];
                return [4 /*yield*/, callAnalyticsMethod(analytics, c).catch(console.error)];
            case 2:
                _b.sent();
                _b.label = 3;
            case 3:
                _i++;
                return [3 /*break*/, 1];
            case 4: return [2 /*return*/];
        }
    });
}); };
export var flushOn = flushSyncAnalyticsCalls.bind(this, 'on');
export var flushSetAnonymousID = flushSyncAnalyticsCalls.bind(this, 'setAnonymousId');
export var flushAnalyticsCallsInNewTask = function (analytics, buffer) {
    buffer.toArray().forEach(function (m) {
        setTimeout(function () {
            callAnalyticsMethod(analytics, m).catch(console.error);
        }, 0);
    });
};
/**
 *  Represents any and all the buffered method calls that occurred before initialization.
 */
var PreInitMethodCallBuffer = /** @class */ (function () {
    function PreInitMethodCallBuffer() {
        this._value = {};
    }
    PreInitMethodCallBuffer.prototype.toArray = function () {
        var _a;
        return (_a = []).concat.apply(_a, Object.values(this._value));
    };
    PreInitMethodCallBuffer.prototype.getCalls = function (methodName) {
        var _a;
        return ((_a = this._value[methodName]) !== null && _a !== void 0 ? _a : []);
    };
    PreInitMethodCallBuffer.prototype.push = function () {
        var _this = this;
        var calls = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            calls[_i] = arguments[_i];
        }
        calls.forEach(function (call) {
            if (_this._value[call.method]) {
                _this._value[call.method].push(call);
            }
            else {
                _this._value[call.method] = [call];
            }
        });
        return this;
    };
    PreInitMethodCallBuffer.prototype.clear = function () {
        this._value = {};
        return this;
    };
    return PreInitMethodCallBuffer;
}());
export { PreInitMethodCallBuffer };
/**
 *  Call method and mark as "called"
 *  This function should never throw an error
 */
export function callAnalyticsMethod(analytics, call) {
    return __awaiter(this, void 0, void 0, function () {
        var result, err_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 3, , 4]);
                    if (call.called) {
                        return [2 /*return*/, undefined];
                    }
                    call.called = true;
                    result = analytics[call.method].apply(analytics, call.args);
                    if (!isThenable(result)) return [3 /*break*/, 2];
                    // do not defer for non-async methods
                    return [4 /*yield*/, result];
                case 1:
                    // do not defer for non-async methods
                    _a.sent();
                    _a.label = 2;
                case 2:
                    call.resolve(result);
                    return [3 /*break*/, 4];
                case 3:
                    err_1 = _a.sent();
                    call.reject(err_1);
                    return [3 /*break*/, 4];
                case 4: return [2 /*return*/];
            }
        });
    });
}
var AnalyticsBuffered = /** @class */ (function () {
    function AnalyticsBuffered(loader) {
        var _this = this;
        this._preInitBuffer = new PreInitMethodCallBuffer();
        this.trackSubmit = this._createMethod('trackSubmit');
        this.trackClick = this._createMethod('trackClick');
        this.trackLink = this._createMethod('trackLink');
        this.pageView = this._createMethod('pageview');
        this.identify = this._createMethod('identify');
        this.reset = this._createMethod('reset');
        this.group = this._createMethod('group');
        this.track = this._createMethod('track');
        this.ready = this._createMethod('ready');
        this.alias = this._createMethod('alias');
        this.debug = this._createChainableMethod('debug');
        this.page = this._createMethod('page');
        this.once = this._createChainableMethod('once');
        this.off = this._createChainableMethod('off');
        this.on = this._createChainableMethod('on');
        this.addSourceMiddleware = this._createMethod('addSourceMiddleware');
        this.setAnonymousId = this._createMethod('setAnonymousId');
        this.addDestinationMiddleware = this._createMethod('addDestinationMiddleware');
        this.screen = this._createMethod('screen');
        this.register = this._createMethod('register');
        this.deregister = this._createMethod('deregister');
        this.user = this._createMethod('user');
        this.VERSION = version;
        this._promise = loader(this._preInitBuffer);
        this._promise
            .then(function (_a) {
            var ajs = _a[0], ctx = _a[1];
            _this.instance = ajs;
            _this.ctx = ctx;
        })
            .catch(function () {
            // intentionally do nothing...
            // this result of this promise will be caught by the 'catch' block on this class.
        });
    }
    AnalyticsBuffered.prototype.then = function () {
        var _a;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return (_a = this._promise).then.apply(_a, args);
    };
    AnalyticsBuffered.prototype.catch = function () {
        var _a;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return (_a = this._promise).catch.apply(_a, args);
    };
    AnalyticsBuffered.prototype.finally = function () {
        var _a;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return (_a = this._promise).finally.apply(_a, args);
    };
    AnalyticsBuffered.prototype._createMethod = function (methodName) {
        var _this = this;
        return function () {
            var _a;
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            if (_this.instance) {
                var result = (_a = _this.instance)[methodName].apply(_a, args);
                return Promise.resolve(result);
            }
            return new Promise(function (resolve, reject) {
                _this._preInitBuffer.push({
                    method: methodName,
                    args: args,
                    resolve: resolve,
                    reject: reject,
                    called: false,
                });
            });
        };
    };
    /**
     *  These are for methods that where determining when the method gets "flushed" is not important.
     *  These methods will resolve when analytics is fully initialized, and return type (other than Analytics)will not be available.
     */
    AnalyticsBuffered.prototype._createChainableMethod = function (methodName) {
        var _this = this;
        return function () {
            var _a;
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            if (_this.instance) {
                void (_a = _this.instance)[methodName].apply(_a, args);
                return _this;
            }
            else {
                _this._preInitBuffer.push({
                    method: methodName,
                    args: args,
                    resolve: function () { },
                    reject: console.error,
                    called: false,
                });
            }
            return _this;
        };
    };
    return AnalyticsBuffered;
}());
export { AnalyticsBuffered };
//# sourceMappingURL=index.js.map