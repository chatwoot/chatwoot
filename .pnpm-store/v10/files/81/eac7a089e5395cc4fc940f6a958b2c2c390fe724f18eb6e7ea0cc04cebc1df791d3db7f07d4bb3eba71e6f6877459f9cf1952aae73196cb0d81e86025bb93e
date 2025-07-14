"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CacheLoader = void 0;
const default_timeouts_1 = require("./default-timeouts");
class CacheLoader {
    constructor(loader, timeout = () => default_timeouts_1.CACHE_LOADER) {
        this._cacheKey = null;
        this._cache = null;
        this.loader = loader;
        this.timeout = timeout;
        this._cacheTime = Number.MIN_SAFE_INTEGER;
    }
    get(...args) {
        const key = JSON.stringify(args);
        const now = Date.now();
        if (this._cacheKey === key) {
            const timeout = typeof this.timeout === 'function' ? this.timeout() : this.timeout;
            if (this._cacheTime + timeout > now) {
                return this._cache;
            }
        }
        this._cacheKey = key;
        this._cacheTime = now;
        return (this._cache = this.loader(...args));
    }
}
exports.CacheLoader = CacheLoader;
