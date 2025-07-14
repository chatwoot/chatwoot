"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Analytics = void 0;
var tslib_1 = require("tslib");
var arguments_resolver_1 = require("../arguments-resolver");
var connection_1 = require("../connection");
var context_1 = require("../context");
var analytics_core_1 = require("@segment/analytics-core");
var events_1 = require("../events");
var event_queue_1 = require("../queue/event-queue");
var user_1 = require("../user");
var bind_all_1 = tslib_1.__importDefault(require("../../lib/bind-all"));
var persisted_1 = require("../../lib/priority-queue/persisted");
var version_1 = require("../../generated/version");
var priority_queue_1 = require("../../lib/priority-queue");
var get_global_1 = require("../../lib/get-global");
var deprecationWarning = 'This is being deprecated and will be not be available in future releases of Analytics JS';
// reference any pre-existing "analytics" object so a user can restore the reference
var global = (0, get_global_1.getGlobal)();
var _analytics = global === null || global === void 0 ? void 0 : global.analytics;
function createDefaultQueue(retryQueue, disablePersistance) {
    if (retryQueue === void 0) { retryQueue = false; }
    if (disablePersistance === void 0) { disablePersistance = false; }
    var maxAttempts = retryQueue ? 4 : 1;
    var priorityQueue = disablePersistance
        ? new priority_queue_1.PriorityQueue(maxAttempts, [])
        : new persisted_1.PersistedPriorityQueue(maxAttempts, 'event-queue');
    return new event_queue_1.EventQueue(priorityQueue);
}
/* analytics-classic stubs */
function _stub() {
    console.warn(deprecationWarning);
}
var Analytics = /** @class */ (function (_super) {
    tslib_1.__extends(Analytics, _super);
    function Analytics(settings, options, queue, user, group) {
        var _this = this;
        var _a, _b, _c;
        _this = _super.call(this) || this;
        _this._debug = false;
        _this.initialized = false;
        _this.user = function () {
            return _this._user;
        };
        _this.init = _this.initialize.bind(_this);
        _this.log = _stub;
        _this.addIntegrationMiddleware = _stub;
        _this.listeners = _stub;
        _this.addEventListener = _stub;
        _this.removeAllListeners = _stub;
        _this.removeListener = _stub;
        _this.removeEventListener = _stub;
        _this.hasListeners = _stub;
        _this.add = _stub;
        _this.addIntegration = _stub;
        var cookieOptions = options === null || options === void 0 ? void 0 : options.cookie;
        var disablePersistance = (_a = options === null || options === void 0 ? void 0 : options.disableClientPersistence) !== null && _a !== void 0 ? _a : false;
        _this.settings = settings;
        _this.settings.timeout = (_b = _this.settings.timeout) !== null && _b !== void 0 ? _b : 300;
        _this.queue =
            queue !== null && queue !== void 0 ? queue : createDefaultQueue(options === null || options === void 0 ? void 0 : options.retryQueue, disablePersistance);
        _this._universalStorage = new user_1.UniversalStorage(disablePersistance ? ['memory'] : ['localStorage', 'cookie', 'memory'], (0, user_1.getAvailableStorageOptions)(cookieOptions));
        _this._user =
            user !== null && user !== void 0 ? user : new user_1.User(disablePersistance
                ? tslib_1.__assign(tslib_1.__assign({}, options === null || options === void 0 ? void 0 : options.user), { persist: false }) : options === null || options === void 0 ? void 0 : options.user, cookieOptions).load();
        _this._group =
            group !== null && group !== void 0 ? group : new user_1.Group(disablePersistance
                ? tslib_1.__assign(tslib_1.__assign({}, options === null || options === void 0 ? void 0 : options.group), { persist: false }) : options === null || options === void 0 ? void 0 : options.group, cookieOptions).load();
        _this.eventFactory = new events_1.EventFactory(_this._user);
        _this.integrations = (_c = options === null || options === void 0 ? void 0 : options.integrations) !== null && _c !== void 0 ? _c : {};
        _this.options = options !== null && options !== void 0 ? options : {};
        (0, bind_all_1.default)(_this);
        return _this;
    }
    Object.defineProperty(Analytics.prototype, "storage", {
        get: function () {
            return this._universalStorage;
        },
        enumerable: false,
        configurable: true
    });
    Analytics.prototype.track = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _a, name, data, opts, cb, segmentEvent;
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                _a = arguments_resolver_1.resolveArguments.apply(void 0, args), name = _a[0], data = _a[1], opts = _a[2], cb = _a[3];
                segmentEvent = this.eventFactory.track(name, data, opts, this.integrations);
                return [2 /*return*/, this._dispatch(segmentEvent, cb).then(function (ctx) {
                        _this.emit('track', name, ctx.event.properties, ctx.event.options);
                        return ctx;
                    })];
            });
        });
    };
    Analytics.prototype.page = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _a, category, page, properties, options, callback, segmentEvent;
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                _a = arguments_resolver_1.resolvePageArguments.apply(void 0, args), category = _a[0], page = _a[1], properties = _a[2], options = _a[3], callback = _a[4];
                segmentEvent = this.eventFactory.page(category, page, properties, options, this.integrations);
                return [2 /*return*/, this._dispatch(segmentEvent, callback).then(function (ctx) {
                        _this.emit('page', category, page, ctx.event.properties, ctx.event.options);
                        return ctx;
                    })];
            });
        });
    };
    Analytics.prototype.identify = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _a, id, _traits, options, callback, segmentEvent;
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                _a = (0, arguments_resolver_1.resolveUserArguments)(this._user).apply(void 0, args), id = _a[0], _traits = _a[1], options = _a[2], callback = _a[3];
                this._user.identify(id, _traits);
                segmentEvent = this.eventFactory.identify(this._user.id(), this._user.traits(), options, this.integrations);
                return [2 /*return*/, this._dispatch(segmentEvent, callback).then(function (ctx) {
                        _this.emit('identify', ctx.event.userId, ctx.event.traits, ctx.event.options);
                        return ctx;
                    })];
            });
        });
    };
    Analytics.prototype.group = function () {
        var _this = this;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        if (args.length === 0) {
            return this._group;
        }
        var _a = (0, arguments_resolver_1.resolveUserArguments)(this._group).apply(void 0, args), id = _a[0], _traits = _a[1], options = _a[2], callback = _a[3];
        this._group.identify(id, _traits);
        var groupId = this._group.id();
        var groupTraits = this._group.traits();
        var segmentEvent = this.eventFactory.group(groupId, groupTraits, options, this.integrations);
        return this._dispatch(segmentEvent, callback).then(function (ctx) {
            _this.emit('group', ctx.event.groupId, ctx.event.traits, ctx.event.options);
            return ctx;
        });
    };
    Analytics.prototype.alias = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _a, to, from, options, callback, segmentEvent;
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                _a = arguments_resolver_1.resolveAliasArguments.apply(void 0, args), to = _a[0], from = _a[1], options = _a[2], callback = _a[3];
                segmentEvent = this.eventFactory.alias(to, from, options, this.integrations);
                return [2 /*return*/, this._dispatch(segmentEvent, callback).then(function (ctx) {
                        _this.emit('alias', to, from, ctx.event.options);
                        return ctx;
                    })];
            });
        });
    };
    Analytics.prototype.screen = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _a, category, page, properties, options, callback, segmentEvent;
            var _this = this;
            return tslib_1.__generator(this, function (_b) {
                _a = arguments_resolver_1.resolvePageArguments.apply(void 0, args), category = _a[0], page = _a[1], properties = _a[2], options = _a[3], callback = _a[4];
                segmentEvent = this.eventFactory.screen(category, page, properties, options, this.integrations);
                return [2 /*return*/, this._dispatch(segmentEvent, callback).then(function (ctx) {
                        _this.emit('screen', category, page, ctx.event.properties, ctx.event.options);
                        return ctx;
                    })];
            });
        });
    };
    Analytics.prototype.trackClick = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var autotrack;
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "auto-track" */ '../auto-track')); })];
                    case 1:
                        autotrack = _b.sent();
                        return [2 /*return*/, (_a = autotrack.link).call.apply(_a, tslib_1.__spreadArray([this], args, false))];
                }
            });
        });
    };
    Analytics.prototype.trackLink = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var autotrack;
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "auto-track" */ '../auto-track')); })];
                    case 1:
                        autotrack = _b.sent();
                        return [2 /*return*/, (_a = autotrack.link).call.apply(_a, tslib_1.__spreadArray([this], args, false))];
                }
            });
        });
    };
    Analytics.prototype.trackSubmit = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var autotrack;
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "auto-track" */ '../auto-track')); })];
                    case 1:
                        autotrack = _b.sent();
                        return [2 /*return*/, (_a = autotrack.form).call.apply(_a, tslib_1.__spreadArray([this], args, false))];
                }
            });
        });
    };
    Analytics.prototype.trackForm = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var autotrack;
            var _a;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "auto-track" */ '../auto-track')); })];
                    case 1:
                        autotrack = _b.sent();
                        return [2 /*return*/, (_a = autotrack.form).call.apply(_a, tslib_1.__spreadArray([this], args, false))];
                }
            });
        });
    };
    Analytics.prototype.register = function () {
        var plugins = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            plugins[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var ctx, registrations;
            var _this = this;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        ctx = context_1.Context.system();
                        registrations = plugins.map(function (xt) {
                            return _this.queue.register(ctx, xt, _this);
                        });
                        return [4 /*yield*/, Promise.all(registrations)];
                    case 1:
                        _a.sent();
                        return [2 /*return*/, ctx];
                }
            });
        });
    };
    Analytics.prototype.deregister = function () {
        var plugins = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            plugins[_i] = arguments[_i];
        }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var ctx, deregistrations;
            var _this = this;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        ctx = context_1.Context.system();
                        deregistrations = plugins.map(function (pl) {
                            var plugin = _this.queue.plugins.find(function (p) { return p.name === pl; });
                            if (plugin) {
                                return _this.queue.deregister(ctx, plugin, _this);
                            }
                            else {
                                ctx.log('warn', "plugin ".concat(pl, " not found"));
                            }
                        });
                        return [4 /*yield*/, Promise.all(deregistrations)];
                    case 1:
                        _a.sent();
                        return [2 /*return*/, ctx];
                }
            });
        });
    };
    Analytics.prototype.debug = function (toggle) {
        // Make sure legacy ajs debug gets turned off if it was enabled before upgrading.
        if (toggle === false && localStorage.getItem('debug')) {
            localStorage.removeItem('debug');
        }
        this._debug = toggle;
        return this;
    };
    Analytics.prototype.reset = function () {
        this._user.reset();
        this._group.reset();
        this.emit('reset');
    };
    Analytics.prototype.timeout = function (timeout) {
        this.settings.timeout = timeout;
    };
    Analytics.prototype._dispatch = function (event, callback) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var ctx;
            return tslib_1.__generator(this, function (_a) {
                ctx = new context_1.Context(event);
                if ((0, connection_1.isOffline)() && !this.options.retryQueue) {
                    return [2 /*return*/, ctx];
                }
                return [2 /*return*/, (0, analytics_core_1.dispatch)(ctx, this.queue, this, {
                        callback: callback,
                        debug: this._debug,
                        timeout: this.settings.timeout,
                    })];
            });
        });
    };
    Analytics.prototype.addSourceMiddleware = function (fn) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var _this = this;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.queue.criticalTasks.run(function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
                            var sourceMiddlewarePlugin, integrations, plugin;
                            return tslib_1.__generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                                        /* webpackChunkName: "middleware" */ '../../plugins/middleware')); })];
                                    case 1:
                                        sourceMiddlewarePlugin = (_a.sent()).sourceMiddlewarePlugin;
                                        integrations = {};
                                        this.queue.plugins.forEach(function (plugin) {
                                            if (plugin.type === 'destination') {
                                                return (integrations[plugin.name] = true);
                                            }
                                        });
                                        plugin = sourceMiddlewarePlugin(fn, integrations);
                                        return [4 /*yield*/, this.register(plugin)];
                                    case 2:
                                        _a.sent();
                                        return [2 /*return*/];
                                }
                            });
                        }); })];
                    case 1:
                        _a.sent();
                        return [2 /*return*/, this];
                }
            });
        });
    };
    /* TODO: This does not have to return a promise? */
    Analytics.prototype.addDestinationMiddleware = function (integrationName) {
        var middlewares = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            middlewares[_i - 1] = arguments[_i];
        }
        var legacyDestinations = this.queue.plugins.filter(function (xt) { return xt.name.toLowerCase() === integrationName.toLowerCase(); });
        legacyDestinations.forEach(function (destination) {
            destination.addMiddleware.apply(destination, middlewares);
        });
        return Promise.resolve(this);
    };
    Analytics.prototype.setAnonymousId = function (id) {
        return this._user.anonymousId(id);
    };
    Analytics.prototype.queryString = function (query) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var queryString;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (this.options.useQueryString === false) {
                            return [2 /*return*/, []];
                        }
                        return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                            /* webpackChunkName: "queryString" */ '../query-string')); })];
                    case 1:
                        queryString = (_a.sent()).queryString;
                        return [2 /*return*/, queryString(this, query)];
                }
            });
        });
    };
    /**
     * @deprecated This function does not register a destination plugin.
     *
     * Instantiates a legacy Analytics.js destination.
     *
     * This function does not register the destination as an Analytics.JS plugin,
     * all the it does it to invoke the factory function back.
     */
    Analytics.prototype.use = function (legacyPluginFactory) {
        legacyPluginFactory(this);
        return this;
    };
    Analytics.prototype.ready = function (callback) {
        if (callback === void 0) { callback = function (res) { return res; }; }
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                return [2 /*return*/, Promise.all(this.queue.plugins.map(function (i) { return (i.ready ? i.ready() : Promise.resolve()); })).then(function (res) {
                        callback(res);
                        return res;
                    })];
            });
        });
    };
    // analytics-classic api
    Analytics.prototype.noConflict = function () {
        console.warn(deprecationWarning);
        window.analytics = _analytics !== null && _analytics !== void 0 ? _analytics : this;
        return this;
    };
    Analytics.prototype.normalize = function (msg) {
        console.warn(deprecationWarning);
        return this.eventFactory.normalize(msg);
    };
    Object.defineProperty(Analytics.prototype, "failedInitializations", {
        get: function () {
            console.warn(deprecationWarning);
            return this.queue.failedInitializations;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Analytics.prototype, "VERSION", {
        get: function () {
            return version_1.version;
        },
        enumerable: false,
        configurable: true
    });
    /* @deprecated - noop */
    Analytics.prototype.initialize = function (_settings, _options) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                console.warn(deprecationWarning);
                return [2 /*return*/, Promise.resolve(this)];
            });
        });
    };
    Analytics.prototype.pageview = function (url) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.warn(deprecationWarning);
                        return [4 /*yield*/, this.page({ path: url })];
                    case 1:
                        _a.sent();
                        return [2 /*return*/, this];
                }
            });
        });
    };
    Object.defineProperty(Analytics.prototype, "plugins", {
        get: function () {
            var _a;
            console.warn(deprecationWarning);
            // @ts-expect-error
            return (_a = this._plugins) !== null && _a !== void 0 ? _a : {};
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Analytics.prototype, "Integrations", {
        get: function () {
            console.warn(deprecationWarning);
            var integrations = this.queue.plugins
                .filter(function (plugin) { return plugin.type === 'destination'; })
                .reduce(function (acc, plugin) {
                var name = "".concat(plugin.name
                    .toLowerCase()
                    .replace('.', '')
                    .split(' ')
                    .join('-'), "Integration");
                // @ts-expect-error
                var integration = window[name];
                if (!integration) {
                    return acc;
                }
                var nested = integration.Integration; // hack - Google Analytics function resides in the "Integration" field
                if (nested) {
                    acc[plugin.name] = nested;
                    return acc;
                }
                acc[plugin.name] = integration;
                return acc;
            }, {});
            return integrations;
        },
        enumerable: false,
        configurable: true
    });
    // snippet function
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Analytics.prototype.push = function (args) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var an = this;
        var method = args.shift();
        if (method) {
            if (!an[method])
                return;
        }
        an[method].apply(this, args);
    };
    return Analytics;
}(analytics_core_1.Emitter));
exports.Analytics = Analytics;
//# sourceMappingURL=index.js.map