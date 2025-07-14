"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ajsDestinations = exports.LegacyDestination = void 0;
var tslib_1 = require("tslib");
var facade_1 = require("@segment/facade");
var connection_1 = require("../../core/connection");
var context_1 = require("../../core/context");
var environment_1 = require("../../core/environment");
var analytics_core_1 = require("@segment/analytics-core");
var is_plan_event_enabled_1 = require("../../lib/is-plan-event-enabled");
var merged_options_1 = require("../../lib/merged-options");
var p_while_1 = require("../../lib/p-while");
var priority_queue_1 = require("../../lib/priority-queue");
var persisted_1 = require("../../lib/priority-queue/persisted");
var middleware_1 = require("../middleware");
var loader_1 = require("./loader");
var analytics_core_2 = require("@segment/analytics-core");
var utils_1 = require("./utils");
function flushQueue(xt, queue) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var failedQueue;
        var _this = this;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    failedQueue = [];
                    if ((0, connection_1.isOffline)()) {
                        return [2 /*return*/, queue];
                    }
                    return [4 /*yield*/, (0, p_while_1.pWhile)(function () { return queue.length > 0 && (0, connection_1.isOnline)(); }, function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
                            var ctx, result, success;
                            return tslib_1.__generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        ctx = queue.pop();
                                        if (!ctx) {
                                            return [2 /*return*/];
                                        }
                                        return [4 /*yield*/, (0, analytics_core_1.attempt)(ctx, xt)];
                                    case 1:
                                        result = _a.sent();
                                        success = result instanceof context_1.Context;
                                        if (!success) {
                                            failedQueue.push(ctx);
                                        }
                                        return [2 /*return*/];
                                }
                            });
                        }); })
                        // re-add failed tasks
                    ];
                case 1:
                    _a.sent();
                    // re-add failed tasks
                    failedQueue.map(function (failed) { return queue.pushWithBackoff(failed); });
                    return [2 /*return*/, queue];
            }
        });
    });
}
var LegacyDestination = /** @class */ (function () {
    function LegacyDestination(name, version, settings, options, integrationSource) {
        if (settings === void 0) { settings = {}; }
        this.options = {};
        this.type = 'destination';
        this.middleware = [];
        this._ready = false;
        this._initialized = false;
        this.flushing = false;
        this.name = name;
        this.version = version;
        this.settings = tslib_1.__assign({}, settings);
        this.disableAutoISOConversion = options.disableAutoISOConversion || false;
        this.integrationSource = integrationSource;
        // AJS-Renderer sets an extraneous `type` setting that clobbers
        // existing type defaults. We need to remove it if it's present
        if (this.settings['type'] && this.settings['type'] === 'browser') {
            delete this.settings['type'];
        }
        this.options = options;
        this.buffer = options.disableClientPersistence
            ? new priority_queue_1.PriorityQueue(4, [])
            : new persisted_1.PersistedPriorityQueue(4, "dest-".concat(name));
        this.scheduleFlush();
    }
    LegacyDestination.prototype.isLoaded = function () {
        return this._ready;
    };
    LegacyDestination.prototype.ready = function () {
        var _a;
        return (_a = this.onReady) !== null && _a !== void 0 ? _a : Promise.resolve();
    };
    LegacyDestination.prototype.load = function (ctx, analyticsInstance) {
        var _a;
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var integrationSource, _b;
            var _this = this;
            return tslib_1.__generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        if (this._ready || this.onReady !== undefined) {
                            return [2 /*return*/];
                        }
                        if (!((_a = this.integrationSource) !== null && _a !== void 0)) return [3 /*break*/, 1];
                        _b = _a;
                        return [3 /*break*/, 3];
                    case 1: return [4 /*yield*/, (0, loader_1.loadIntegration)(ctx, this.name, this.version, this.options.obfuscate)];
                    case 2:
                        _b = (_c.sent());
                        _c.label = 3;
                    case 3:
                        integrationSource = _b;
                        this.integration = (0, loader_1.buildIntegration)(integrationSource, this.settings, analyticsInstance);
                        this.onReady = new Promise(function (resolve) {
                            var onReadyFn = function () {
                                _this._ready = true;
                                resolve(true);
                            };
                            _this.integration.once('ready', onReadyFn);
                        });
                        this.onInitialize = new Promise(function (resolve) {
                            var onInit = function () {
                                _this._initialized = true;
                                resolve(true);
                            };
                            _this.integration.on('initialize', onInit);
                        });
                        try {
                            ctx.stats.increment('analytics_js.integration.invoke', 1, [
                                "method:initialize",
                                "integration_name:".concat(this.name),
                            ]);
                            this.integration.initialize();
                        }
                        catch (error) {
                            ctx.stats.increment('analytics_js.integration.invoke.error', 1, [
                                "method:initialize",
                                "integration_name:".concat(this.name),
                            ]);
                            throw error;
                        }
                        return [2 /*return*/];
                }
            });
        });
    };
    LegacyDestination.prototype.unload = function (_ctx, _analyticsInstance) {
        return (0, loader_1.unloadIntegration)(this.name, this.version, this.options.obfuscate);
    };
    LegacyDestination.prototype.addMiddleware = function () {
        var _a;
        var fn = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            fn[_i] = arguments[_i];
        }
        this.middleware = (_a = this.middleware).concat.apply(_a, fn);
    };
    LegacyDestination.prototype.shouldBuffer = function (ctx) {
        return (
        // page events can't be buffered because of destinations that automatically add page views
        ctx.event.type !== 'page' &&
            ((0, connection_1.isOffline)() || this._ready === false || this._initialized === false));
    };
    LegacyDestination.prototype.send = function (ctx, clz, eventType) {
        var _a, _b;
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var plan, ev, planEvent, afterMiddleware, event, err_1;
            return tslib_1.__generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        if (this.shouldBuffer(ctx)) {
                            this.buffer.push(ctx);
                            this.scheduleFlush();
                            return [2 /*return*/, ctx];
                        }
                        plan = (_b = (_a = this.options) === null || _a === void 0 ? void 0 : _a.plan) === null || _b === void 0 ? void 0 : _b.track;
                        ev = ctx.event.event;
                        if (plan && ev && this.name !== 'june.so') {
                            planEvent = plan[ev];
                            if (!(0, is_plan_event_enabled_1.isPlanEventEnabled)(plan, planEvent)) {
                                ctx.updateEvent('integrations', tslib_1.__assign(tslib_1.__assign({}, ctx.event.integrations), { All: false, 'june.so': true }));
                                ctx.cancel(new context_1.ContextCancelation({
                                    retry: false,
                                    reason: "Event ".concat(ev, " disabled for integration ").concat(this.name, " in tracking plan"),
                                    type: 'Dropped by plan',
                                }));
                                return [2 /*return*/, ctx];
                            }
                            else {
                                ctx.updateEvent('integrations', tslib_1.__assign(tslib_1.__assign({}, ctx.event.integrations), planEvent === null || planEvent === void 0 ? void 0 : planEvent.integrations));
                            }
                            if ((planEvent === null || planEvent === void 0 ? void 0 : planEvent.enabled) && (planEvent === null || planEvent === void 0 ? void 0 : planEvent.integrations[this.name]) === false) {
                                ctx.cancel(new context_1.ContextCancelation({
                                    retry: false,
                                    reason: "Event ".concat(ev, " disabled for integration ").concat(this.name, " in tracking plan"),
                                    type: 'Dropped by plan',
                                }));
                                return [2 /*return*/, ctx];
                            }
                        }
                        return [4 /*yield*/, (0, middleware_1.applyDestinationMiddleware)(this.name, ctx.event, this.middleware)];
                    case 1:
                        afterMiddleware = _c.sent();
                        if (afterMiddleware === null) {
                            return [2 /*return*/, ctx];
                        }
                        event = new clz(afterMiddleware, {
                            traverse: !this.disableAutoISOConversion,
                        });
                        ctx.stats.increment('analytics_js.integration.invoke', 1, [
                            "method:".concat(eventType),
                            "integration_name:".concat(this.name),
                        ]);
                        _c.label = 2;
                    case 2:
                        _c.trys.push([2, 5, , 6]);
                        if (!this.integration) return [3 /*break*/, 4];
                        return [4 /*yield*/, this.integration.invoke.call(this.integration, eventType, event)];
                    case 3:
                        _c.sent();
                        _c.label = 4;
                    case 4: return [3 /*break*/, 6];
                    case 5:
                        err_1 = _c.sent();
                        ctx.stats.increment('analytics_js.integration.invoke.error', 1, [
                            "method:".concat(eventType),
                            "integration_name:".concat(this.name),
                        ]);
                        throw err_1;
                    case 6: return [2 /*return*/, ctx];
                }
            });
        });
    };
    LegacyDestination.prototype.track = function (ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                return [2 /*return*/, this.send(ctx, facade_1.Track, 'track')];
            });
        });
    };
    LegacyDestination.prototype.page = function (ctx) {
        var _a;
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                if (((_a = this.integration) === null || _a === void 0 ? void 0 : _a._assumesPageview) && !this._initialized) {
                    this.integration.initialize();
                }
                return [2 /*return*/, this.onInitialize.then(function () {
                        return _this.send(ctx, facade_1.Page, 'page');
                    })];
            });
        });
    };
    LegacyDestination.prototype.identify = function (ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                return [2 /*return*/, this.send(ctx, facade_1.Identify, 'identify')];
            });
        });
    };
    LegacyDestination.prototype.alias = function (ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                return [2 /*return*/, this.send(ctx, facade_1.Alias, 'alias')];
            });
        });
    };
    LegacyDestination.prototype.group = function (ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                return [2 /*return*/, this.send(ctx, facade_1.Group, 'group')];
            });
        });
    };
    LegacyDestination.prototype.scheduleFlush = function () {
        var _this = this;
        if (this.flushing) {
            return;
        }
        // eslint-disable-next-line @typescript-eslint/no-misused-promises
        setTimeout(function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        this.flushing = true;
                        _a = this;
                        return [4 /*yield*/, flushQueue(this, this.buffer)];
                    case 1:
                        _a.buffer = _b.sent();
                        this.flushing = false;
                        if (this.buffer.todo > 0) {
                            this.scheduleFlush();
                        }
                        return [2 /*return*/];
                }
            });
        }); }, Math.random() * 5000);
    };
    return LegacyDestination;
}());
exports.LegacyDestination = LegacyDestination;
function ajsDestinations(settings, globalIntegrations, options, routingMiddleware, legacyIntegrationSources) {
    var _a, _b;
    if (globalIntegrations === void 0) { globalIntegrations = {}; }
    if (options === void 0) { options = {}; }
    if ((0, environment_1.isServer)()) {
        return [];
    }
    if (settings.plan) {
        options = options !== null && options !== void 0 ? options : {};
        options.plan = settings.plan;
    }
    var routingRules = (_b = (_a = settings.middlewareSettings) === null || _a === void 0 ? void 0 : _a.routingRules) !== null && _b !== void 0 ? _b : [];
    var remoteIntegrationsConfig = settings.integrations;
    var localIntegrationsConfig = options.integrations;
    // merged remote CDN settings with user provided options
    var integrationOptions = (0, merged_options_1.mergedOptions)(settings, options !== null && options !== void 0 ? options : {});
    var adhocIntegrationSources = legacyIntegrationSources === null || legacyIntegrationSources === void 0 ? void 0 : legacyIntegrationSources.reduce(function (acc, integrationSource) {
        var _a;
        return (tslib_1.__assign(tslib_1.__assign({}, acc), (_a = {}, _a[(0, loader_1.resolveIntegrationNameFromSource)(integrationSource)] = integrationSource, _a)));
    }, {});
    var installableIntegrations = new Set(tslib_1.__spreadArray(tslib_1.__spreadArray([], Object.keys(remoteIntegrationsConfig).filter(function (name) {
        return (0, utils_1.isInstallableIntegration)(name, remoteIntegrationsConfig[name]);
    }), true), Object.keys(adhocIntegrationSources || {}).filter(function (name) {
        return (0, analytics_core_2.isPlainObject)(remoteIntegrationsConfig[name]) ||
            (0, analytics_core_2.isPlainObject)(localIntegrationsConfig === null || localIntegrationsConfig === void 0 ? void 0 : localIntegrationsConfig[name]);
    }), true));
    return Array.from(installableIntegrations)
        .filter(function (name) { return !(0, utils_1.isDisabledIntegration)(name, globalIntegrations); })
        .map(function (name) {
        var integrationSettings = remoteIntegrationsConfig[name];
        var version = (0, loader_1.resolveVersion)(integrationSettings);
        var destination = new LegacyDestination(name, version, integrationOptions[name], options, adhocIntegrationSources === null || adhocIntegrationSources === void 0 ? void 0 : adhocIntegrationSources[name]);
        var routing = routingRules.filter(function (rule) { return rule.destinationName === name; });
        if (routing.length > 0 && routingMiddleware) {
            destination.addMiddleware(routingMiddleware);
        }
        return destination;
    });
}
exports.ajsDestinations = ajsDestinations;
//# sourceMappingURL=index.js.map