"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/* eslint-disable @typescript-eslint/no-var-requires */
var LRUCache = require('lru-cache');
var hash = require('hash-sum');
var cache = new LRUCache(250);
function default_1(creator) {
    var argsKey = [];
    for (var _i = 1; _i < arguments.length; _i++) {
        argsKey[_i - 1] = arguments[_i];
    }
    var cacheKey = hash(argsKey.join(''));
    // source-map cache busting for hot-reloadded modules
    var output = cache.get(cacheKey);
    if (output) {
        return output;
    }
    output = creator();
    cache.set(cacheKey, output);
    return output;
}
exports.default = default_1;
