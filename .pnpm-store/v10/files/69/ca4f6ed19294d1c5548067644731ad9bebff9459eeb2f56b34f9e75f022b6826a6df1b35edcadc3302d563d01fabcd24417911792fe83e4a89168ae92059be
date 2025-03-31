"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defineCacheFunction = void 0;
const cache_loader_1 = require("./cache-loader");
function defineCacheFunction(fn) {
    const loader = new cache_loader_1.CacheLoader(fn, Infinity);
    return (...args) => {
        return loader.get(...args);
    };
}
exports.defineCacheFunction = defineCacheFunction;
