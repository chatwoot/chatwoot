Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var utils_1 = require("@sentry/utils");
var helpers_1 = require("../helpers");
var DEFAULT_EVENT_TARGET = [
    'EventTarget',
    'Window',
    'Node',
    'ApplicationCache',
    'AudioTrackList',
    'ChannelMergerNode',
    'CryptoOperation',
    'EventSource',
    'FileReader',
    'HTMLUnknownElement',
    'IDBDatabase',
    'IDBRequest',
    'IDBTransaction',
    'KeyOperation',
    'MediaController',
    'MessagePort',
    'ModalWindow',
    'Notification',
    'SVGElementInstance',
    'Screen',
    'TextTrack',
    'TextTrackCue',
    'TextTrackList',
    'WebSocket',
    'WebSocketWorker',
    'Worker',
    'XMLHttpRequest',
    'XMLHttpRequestEventTarget',
    'XMLHttpRequestUpload',
];
/** Wrap timer functions and event targets to catch errors and provide better meta data */
var TryCatch = /** @class */ (function () {
    /**
     * @inheritDoc
     */
    function TryCatch(options) {
        /**
         * @inheritDoc
         */
        this.name = TryCatch.id;
        this._options = tslib_1.__assign({ XMLHttpRequest: true, eventTarget: true, requestAnimationFrame: true, setInterval: true, setTimeout: true }, options);
    }
    /**
     * Wrap timer functions and event targets to catch errors
     * and provide better metadata.
     */
    TryCatch.prototype.setupOnce = function () {
        var global = utils_1.getGlobalObject();
        if (this._options.setTimeout) {
            utils_1.fill(global, 'setTimeout', _wrapTimeFunction);
        }
        if (this._options.setInterval) {
            utils_1.fill(global, 'setInterval', _wrapTimeFunction);
        }
        if (this._options.requestAnimationFrame) {
            utils_1.fill(global, 'requestAnimationFrame', _wrapRAF);
        }
        if (this._options.XMLHttpRequest && 'XMLHttpRequest' in global) {
            utils_1.fill(XMLHttpRequest.prototype, 'send', _wrapXHR);
        }
        var eventTargetOption = this._options.eventTarget;
        if (eventTargetOption) {
            var eventTarget = Array.isArray(eventTargetOption) ? eventTargetOption : DEFAULT_EVENT_TARGET;
            eventTarget.forEach(_wrapEventTarget);
        }
    };
    /**
     * @inheritDoc
     */
    TryCatch.id = 'TryCatch';
    return TryCatch;
}());
exports.TryCatch = TryCatch;
/** JSDoc */
function _wrapTimeFunction(original) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        var originalCallback = args[0];
        args[0] = helpers_1.wrap(originalCallback, {
            mechanism: {
                data: { function: utils_1.getFunctionName(original) },
                handled: true,
                type: 'instrument',
            },
        });
        return original.apply(this, args);
    };
}
/** JSDoc */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _wrapRAF(original) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return function (callback) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        return original.apply(this, [
            helpers_1.wrap(callback, {
                mechanism: {
                    data: {
                        function: 'requestAnimationFrame',
                        handler: utils_1.getFunctionName(original),
                    },
                    handled: true,
                    type: 'instrument',
                },
            }),
        ]);
    };
}
/** JSDoc */
function _wrapXHR(originalSend) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        // eslint-disable-next-line @typescript-eslint/no-this-alias
        var xhr = this;
        var xmlHttpRequestProps = ['onload', 'onerror', 'onprogress', 'onreadystatechange'];
        xmlHttpRequestProps.forEach(function (prop) {
            if (prop in xhr && typeof xhr[prop] === 'function') {
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                utils_1.fill(xhr, prop, function (original) {
                    var wrapOptions = {
                        mechanism: {
                            data: {
                                function: prop,
                                handler: utils_1.getFunctionName(original),
                            },
                            handled: true,
                            type: 'instrument',
                        },
                    };
                    // If Instrument integration has been called before TryCatch, get the name of original function
                    var originalFunction = utils_1.getOriginalFunction(original);
                    if (originalFunction) {
                        wrapOptions.mechanism.data.handler = utils_1.getFunctionName(originalFunction);
                    }
                    // Otherwise wrap directly
                    return helpers_1.wrap(original, wrapOptions);
                });
            }
        });
        return originalSend.apply(this, args);
    };
}
/** JSDoc */
function _wrapEventTarget(target) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    var global = utils_1.getGlobalObject();
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    var proto = global[target] && global[target].prototype;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, no-prototype-builtins
    if (!proto || !proto.hasOwnProperty || !proto.hasOwnProperty('addEventListener')) {
        return;
    }
    utils_1.fill(proto, 'addEventListener', function (original) {
        return function (eventName, fn, options) {
            try {
                if (typeof fn.handleEvent === 'function') {
                    fn.handleEvent = helpers_1.wrap(fn.handleEvent.bind(fn), {
                        mechanism: {
                            data: {
                                function: 'handleEvent',
                                handler: utils_1.getFunctionName(fn),
                                target: target,
                            },
                            handled: true,
                            type: 'instrument',
                        },
                    });
                }
            }
            catch (err) {
                // can sometimes get 'Permission denied to access property "handle Event'
            }
            return original.apply(this, [
                eventName,
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                helpers_1.wrap(fn, {
                    mechanism: {
                        data: {
                            function: 'addEventListener',
                            handler: utils_1.getFunctionName(fn),
                            target: target,
                        },
                        handled: true,
                        type: 'instrument',
                    },
                }),
                options,
            ]);
        };
    });
    utils_1.fill(proto, 'removeEventListener', function (originalRemoveEventListener) {
        return function (eventName, fn, options) {
            /**
             * There are 2 possible scenarios here:
             *
             * 1. Someone passes a callback, which was attached prior to Sentry initialization, or by using unmodified
             * method, eg. `document.addEventListener.call(el, name, handler). In this case, we treat this function
             * as a pass-through, and call original `removeEventListener` with it.
             *
             * 2. Someone passes a callback, which was attached after Sentry was initialized, which means that it was using
             * our wrapped version of `addEventListener`, which internally calls `wrap` helper.
             * This helper "wraps" whole callback inside a try/catch statement, and attached appropriate metadata to it,
             * in order for us to make a distinction between wrapped/non-wrapped functions possible.
             * If a function was wrapped, it has additional property of `__sentry_wrapped__`, holding the handler.
             *
             * When someone adds a handler prior to initialization, and then do it again, but after,
             * then we have to detach both of them. Otherwise, if we'd detach only wrapped one, it'd be impossible
             * to get rid of the initial handler and it'd stick there forever.
             */
            var wrappedEventHandler = fn;
            try {
                var originalEventHandler = wrappedEventHandler && wrappedEventHandler.__sentry_wrapped__;
                if (originalEventHandler) {
                    originalRemoveEventListener.call(this, eventName, originalEventHandler, options);
                }
            }
            catch (e) {
                // ignore, accessing __sentry_wrapped__ will throw in some Selenium environments
            }
            return originalRemoveEventListener.call(this, eventName, wrappedEventHandler, options);
        };
    });
}
//# sourceMappingURL=trycatch.js.map