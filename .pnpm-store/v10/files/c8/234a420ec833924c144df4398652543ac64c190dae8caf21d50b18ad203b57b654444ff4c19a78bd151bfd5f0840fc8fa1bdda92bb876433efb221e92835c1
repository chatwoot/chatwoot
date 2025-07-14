"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ResourceLoader = void 0;
const fs_1 = require("fs");
const cache_loader_1 = require("./cache-loader");
const default_timeouts_1 = require("./default-timeouts");
class ResourceLoader {
    constructor(filename, loader, mtimeCheckTimeout = () => default_timeouts_1.MTIME_MS_CHECK) {
        this._mtimeMs = 0;
        this.filename = filename;
        this.loader = loader;
        this._resource = null;
        this._mtimeLoader = new cache_loader_1.CacheLoader(() => {
            try {
                const stat = (0, fs_1.statSync)(this.filename);
                return stat.mtimeMs;
            }
            catch (_e) {
            }
            return this._mtimeMs || 0;
        }, mtimeCheckTimeout);
    }
    getResource() {
        const mtimeMs = this._mtimeLoader.get();
        if (this._resource && this._mtimeMs >= mtimeMs) {
            return this._resource;
        }
        this._mtimeMs = mtimeMs;
        return (this._resource = this.loader(this.filename));
    }
}
exports.ResourceLoader = ResourceLoader;
