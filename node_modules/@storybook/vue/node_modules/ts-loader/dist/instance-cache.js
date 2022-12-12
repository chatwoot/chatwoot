"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setTSInstanceInCache = exports.getTSInstanceFromCache = void 0;
// Some loaders (e.g. thread-loader) will set the _compiler property to undefined.
// We can't use undefined as a WeakMap key as it will throw an error at runtime,
// thus we keep a dummy "marker" object to use as key in those situations.
const marker = {};
// Each TypeScript instance is cached based on the webpack instance (key of the WeakMap)
// and also the name that was generated or passed via the options (string key of the
// internal Map)
const cache = new WeakMap();
function getTSInstanceFromCache(key, name) {
    const compiler = key !== null && key !== void 0 ? key : marker;
    let instances = cache.get(compiler);
    if (!instances) {
        instances = new Map();
        cache.set(compiler, instances);
    }
    return instances.get(name);
}
exports.getTSInstanceFromCache = getTSInstanceFromCache;
function setTSInstanceInCache(key, name, instance) {
    var _a;
    const compiler = key !== null && key !== void 0 ? key : marker;
    const instances = (_a = cache.get(compiler)) !== null && _a !== void 0 ? _a : new Map();
    instances.set(name, instance);
    cache.set(compiler, instances);
}
exports.setTSInstanceInCache = setTSInstanceInCache;
//# sourceMappingURL=instance-cache.js.map