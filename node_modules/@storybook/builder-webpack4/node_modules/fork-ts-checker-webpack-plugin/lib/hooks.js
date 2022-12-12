"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var tapable_1 = require("tapable");
var compilerHookMap = new WeakMap();
function createForkTsCheckerWebpackPluginHooks() {
    return {
        serviceBeforeStart: new tapable_1.AsyncSeriesHook([]),
        cancel: new tapable_1.SyncHook(['cancellationToken']),
        serviceStartError: new tapable_1.SyncHook(['error']),
        waiting: new tapable_1.SyncHook([]),
        serviceStart: new tapable_1.SyncHook(['tsconfigPath', 'memoryLimit']),
        receive: new tapable_1.SyncHook(['diagnostics', 'lints']),
        serviceOutOfMemory: new tapable_1.SyncHook([]),
        emit: new tapable_1.SyncHook(['diagnostics', 'lints', 'elapsed']),
        done: new tapable_1.SyncHook(['diagnostics', 'lints', 'elapsed'])
    };
}
function getForkTsCheckerWebpackPluginHooks(compiler) {
    var hooks = compilerHookMap.get(compiler);
    if (hooks === undefined) {
        hooks = createForkTsCheckerWebpackPluginHooks();
        compilerHookMap.set(compiler, hooks);
    }
    return hooks;
}
exports.getForkTsCheckerWebpackPluginHooks = getForkTsCheckerWebpackPluginHooks;
//# sourceMappingURL=hooks.js.map