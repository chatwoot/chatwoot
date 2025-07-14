import { __assign, __awaiter, __generator } from "tslib";
import { loadScript } from '../../lib/load-script';
import { getCDN } from '../../lib/parse-cdn';
import { applyDestinationMiddleware, } from '../middleware';
import { Context, ContextCancelation } from '../../core/context';
var ActionDestination = /** @class */ (function () {
    function ActionDestination(name, action) {
        this.version = '1.0.0';
        this.alternativeNames = [];
        this.middleware = [];
        this.alias = this._createMethod('alias');
        this.group = this._createMethod('group');
        this.identify = this._createMethod('identify');
        this.page = this._createMethod('page');
        this.screen = this._createMethod('screen');
        this.track = this._createMethod('track');
        this.action = action;
        this.name = name;
        this.type = action.type;
        this.alternativeNames.push(action.name);
    }
    ActionDestination.prototype.addMiddleware = function () {
        var _a;
        var fn = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            fn[_i] = arguments[_i];
        }
        if (this.type === 'destination') {
            (_a = this.middleware).push.apply(_a, fn);
        }
    };
    ActionDestination.prototype.transform = function (ctx) {
        return __awaiter(this, void 0, void 0, function () {
            var modifiedEvent;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, applyDestinationMiddleware(this.name, ctx.event, this.middleware)];
                    case 1:
                        modifiedEvent = _a.sent();
                        if (modifiedEvent === null) {
                            ctx.cancel(new ContextCancelation({
                                retry: false,
                                reason: 'dropped by destination middleware',
                            }));
                        }
                        return [2 /*return*/, new Context(modifiedEvent)];
                }
            });
        });
    };
    ActionDestination.prototype._createMethod = function (methodName) {
        var _this = this;
        return function (ctx) { return __awaiter(_this, void 0, void 0, function () {
            var transformedContext;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (!this.action[methodName])
                            return [2 /*return*/, ctx];
                        transformedContext = ctx;
                        if (!(this.type === 'destination')) return [3 /*break*/, 2];
                        return [4 /*yield*/, this.transform(ctx)];
                    case 1:
                        transformedContext = _a.sent();
                        _a.label = 2;
                    case 2: return [4 /*yield*/, this.action[methodName](transformedContext)];
                    case 3:
                        _a.sent();
                        return [2 /*return*/, ctx];
                }
            });
        }); };
    };
    /* --- PASSTHROUGH METHODS --- */
    ActionDestination.prototype.isLoaded = function () {
        return this.action.isLoaded();
    };
    ActionDestination.prototype.ready = function () {
        return this.action.ready ? this.action.ready() : Promise.resolve();
    };
    ActionDestination.prototype.load = function (ctx, analytics) {
        return this.action.load(ctx, analytics);
    };
    ActionDestination.prototype.unload = function (ctx, analytics) {
        var _a, _b;
        return (_b = (_a = this.action).unload) === null || _b === void 0 ? void 0 : _b.call(_a, ctx, analytics);
    };
    return ActionDestination;
}());
export { ActionDestination };
function validate(pluginLike) {
    if (!Array.isArray(pluginLike)) {
        throw new Error('Not a valid list of plugins');
    }
    var required = ['load', 'isLoaded', 'name', 'version', 'type'];
    pluginLike.forEach(function (plugin) {
        required.forEach(function (method) {
            var _a;
            if (plugin[method] === undefined) {
                throw new Error("Plugin: ".concat((_a = plugin.name) !== null && _a !== void 0 ? _a : 'unknown', " missing required function ").concat(method));
            }
        });
    });
    return true;
}
function isPluginDisabled(userIntegrations, remotePlugin) {
    var creationNameEnabled = userIntegrations[remotePlugin.creationName];
    var currentNameEnabled = userIntegrations[remotePlugin.name];
    // Check that the plugin isn't explicitly enabled when All: false
    if (userIntegrations.All === false &&
        !creationNameEnabled &&
        !currentNameEnabled) {
        return true;
    }
    // Check that the plugin isn't explicitly disabled
    if (creationNameEnabled === false || currentNameEnabled === false) {
        return true;
    }
    return false;
}
export function remoteLoader(settings, userIntegrations, mergedIntegrations, obfuscate, routingMiddleware) {
    var _a, _b, _c;
    return __awaiter(this, void 0, void 0, function () {
        var allPlugins, cdn, routingRules, pluginPromises;
        var _this = this;
        return __generator(this, function (_d) {
            switch (_d.label) {
                case 0:
                    allPlugins = [];
                    cdn = getCDN();
                    routingRules = (_b = (_a = settings.middlewareSettings) === null || _a === void 0 ? void 0 : _a.routingRules) !== null && _b !== void 0 ? _b : [];
                    pluginPromises = ((_c = settings.remotePlugins) !== null && _c !== void 0 ? _c : []).map(function (remotePlugin) { return __awaiter(_this, void 0, void 0, function () {
                        var urlSplit, name_1, obfuscatedURL, error_1, libraryName, pluginFactory, plugin, plugins, routing_1, error_2;
                        return __generator(this, function (_a) {
                            switch (_a.label) {
                                case 0:
                                    if (isPluginDisabled(userIntegrations, remotePlugin))
                                        return [2 /*return*/];
                                    _a.label = 1;
                                case 1:
                                    _a.trys.push([1, 12, , 13]);
                                    if (!obfuscate) return [3 /*break*/, 7];
                                    urlSplit = remotePlugin.url.split('/');
                                    name_1 = urlSplit[urlSplit.length - 2];
                                    obfuscatedURL = remotePlugin.url.replace(name_1, btoa(name_1).replace(/=/g, ''));
                                    _a.label = 2;
                                case 2:
                                    _a.trys.push([2, 4, , 6]);
                                    return [4 /*yield*/, loadScript(obfuscatedURL.replace('https://cdn.june.so', cdn))];
                                case 3:
                                    _a.sent();
                                    return [3 /*break*/, 6];
                                case 4:
                                    error_1 = _a.sent();
                                    // Due to syncing concerns it is possible that the obfuscated action destination (or requested version) might not exist.
                                    // We should use the unobfuscated version as a fallback.
                                    return [4 /*yield*/, loadScript(remotePlugin.url.replace('https://cdn.june.so', cdn))];
                                case 5:
                                    // Due to syncing concerns it is possible that the obfuscated action destination (or requested version) might not exist.
                                    // We should use the unobfuscated version as a fallback.
                                    _a.sent();
                                    return [3 /*break*/, 6];
                                case 6: return [3 /*break*/, 9];
                                case 7: return [4 /*yield*/, loadScript(remotePlugin.url.replace('https://cdn.june.so', cdn))];
                                case 8:
                                    _a.sent();
                                    _a.label = 9;
                                case 9:
                                    libraryName = remotePlugin.libraryName;
                                    if (!(typeof window[libraryName] === 'function')) return [3 /*break*/, 11];
                                    pluginFactory = window[libraryName];
                                    return [4 /*yield*/, pluginFactory(__assign(__assign({}, remotePlugin.settings), mergedIntegrations[remotePlugin.name]))];
                                case 10:
                                    plugin = _a.sent();
                                    plugins = Array.isArray(plugin) ? plugin : [plugin];
                                    validate(plugins);
                                    routing_1 = routingRules.filter(function (rule) { return rule.destinationName === remotePlugin.creationName; });
                                    plugins.forEach(function (plugin) {
                                        var wrapper = new ActionDestination(remotePlugin.creationName, plugin);
                                        /** Make sure we only apply destination filters to actions of the "destination" type to avoid causing issues for hybrid destinations */
                                        if (routing_1.length &&
                                            routingMiddleware &&
                                            plugin.type === 'destination') {
                                            wrapper.addMiddleware(routingMiddleware);
                                        }
                                        allPlugins.push(wrapper);
                                    });
                                    _a.label = 11;
                                case 11: return [3 /*break*/, 13];
                                case 12:
                                    error_2 = _a.sent();
                                    console.warn('Failed to load Remote Plugin', error_2);
                                    return [3 /*break*/, 13];
                                case 13: return [2 /*return*/];
                            }
                        });
                    }); });
                    return [4 /*yield*/, Promise.all(pluginPromises)];
                case 1:
                    _d.sent();
                    return [2 /*return*/, allPlugins.filter(Boolean)];
            }
        });
    });
}
//# sourceMappingURL=index.js.map