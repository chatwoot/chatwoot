"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sourceMiddlewarePlugin = exports.applyDestinationMiddleware = void 0;
var tslib_1 = require("tslib");
var context_1 = require("../../core/context");
var to_facade_1 = require("../../lib/to-facade");
function applyDestinationMiddleware(destination, evt, middleware) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        function applyMiddleware(event, fn) {
            return tslib_1.__awaiter(this, void 0, void 0, function () {
                var nextCalled, returnedEvent;
                var _a;
                return tslib_1.__generator(this, function (_b) {
                    switch (_b.label) {
                        case 0:
                            nextCalled = false;
                            returnedEvent = null;
                            return [4 /*yield*/, fn({
                                    payload: (0, to_facade_1.toFacade)(event, {
                                        clone: true,
                                        traverse: false,
                                    }),
                                    integration: destination,
                                    next: function (evt) {
                                        nextCalled = true;
                                        if (evt === null) {
                                            returnedEvent = null;
                                        }
                                        if (evt) {
                                            returnedEvent = evt.obj;
                                        }
                                    },
                                })];
                        case 1:
                            _b.sent();
                            if (!nextCalled && returnedEvent !== null) {
                                returnedEvent = returnedEvent;
                                returnedEvent.integrations = tslib_1.__assign(tslib_1.__assign({}, event.integrations), (_a = {}, _a[destination] = false, _a));
                            }
                            return [2 /*return*/, returnedEvent];
                    }
                });
            });
        }
        var modifiedEvent, _i, middleware_1, md, result;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    modifiedEvent = (0, to_facade_1.toFacade)(evt, {
                        clone: true,
                        traverse: false,
                    }).rawEvent();
                    _i = 0, middleware_1 = middleware;
                    _a.label = 1;
                case 1:
                    if (!(_i < middleware_1.length)) return [3 /*break*/, 4];
                    md = middleware_1[_i];
                    return [4 /*yield*/, applyMiddleware(modifiedEvent, md)];
                case 2:
                    result = _a.sent();
                    if (result === null) {
                        return [2 /*return*/, null];
                    }
                    modifiedEvent = result;
                    _a.label = 3;
                case 3:
                    _i++;
                    return [3 /*break*/, 1];
                case 4: return [2 /*return*/, modifiedEvent];
            }
        });
    });
}
exports.applyDestinationMiddleware = applyDestinationMiddleware;
function sourceMiddlewarePlugin(fn, integrations) {
    function apply(ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var nextCalled;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        nextCalled = false;
                        return [4 /*yield*/, fn({
                                payload: (0, to_facade_1.toFacade)(ctx.event, {
                                    clone: true,
                                    traverse: false,
                                }),
                                integrations: integrations !== null && integrations !== void 0 ? integrations : {},
                                next: function (evt) {
                                    nextCalled = true;
                                    if (evt) {
                                        ctx.event = evt.obj;
                                    }
                                },
                            })];
                    case 1:
                        _a.sent();
                        if (!nextCalled) {
                            throw new context_1.ContextCancelation({
                                retry: false,
                                type: 'middleware_cancellation',
                                reason: 'Middleware `next` function skipped',
                            });
                        }
                        return [2 /*return*/, ctx];
                }
            });
        });
    }
    return {
        name: "Source Middleware ".concat(fn.name),
        type: 'before',
        version: '0.1.0',
        isLoaded: function () { return true; },
        load: function (ctx) { return Promise.resolve(ctx); },
        track: apply,
        page: apply,
        identify: apply,
        alias: apply,
        group: apply,
    };
}
exports.sourceMiddlewarePlugin = sourceMiddlewarePlugin;
//# sourceMappingURL=index.js.map