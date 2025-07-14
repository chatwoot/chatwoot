"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensure = exports.attempt = void 0;
var tslib_1 = require("tslib");
var context_1 = require("../context");
function tryAsync(fn) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var err_1;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, fn()];
                case 1: return [2 /*return*/, _a.sent()];
                case 2:
                    err_1 = _a.sent();
                    return [2 /*return*/, Promise.reject(err_1)];
                case 3: return [2 /*return*/];
            }
        });
    });
}
function attempt(ctx, plugin) {
    ctx.log('debug', 'plugin', { plugin: plugin.name });
    var start = new Date().getTime();
    var hook = plugin[ctx.event.type];
    if (hook === undefined) {
        return Promise.resolve(ctx);
    }
    var newCtx = tryAsync(function () { return hook.apply(plugin, [ctx]); })
        .then(function (ctx) {
        var done = new Date().getTime() - start;
        ctx.stats.gauge('plugin_time', done, ["plugin:".concat(plugin.name)]);
        return ctx;
    })
        .catch(function (err) {
        if (err instanceof context_1.ContextCancelation &&
            err.type === 'middleware_cancellation') {
            throw err;
        }
        if (err instanceof context_1.ContextCancelation) {
            ctx.log('warn', err.type, {
                plugin: plugin.name,
                error: err,
            });
            return err;
        }
        ctx.log('error', 'plugin Error', {
            plugin: plugin.name,
            error: err,
        });
        ctx.stats.increment('plugin_error', 1, ["plugin:".concat(plugin.name)]);
        return err;
    });
    return newCtx;
}
exports.attempt = attempt;
function ensure(ctx, plugin) {
    return attempt(ctx, plugin).then(function (newContext) {
        if (newContext instanceof context_1.CoreContext) {
            return newContext;
        }
        ctx.log('debug', 'Context canceled');
        ctx.stats.increment('context_canceled');
        ctx.cancel(newContext);
    });
}
exports.ensure = ensure;
//# sourceMappingURL=delivery.js.map