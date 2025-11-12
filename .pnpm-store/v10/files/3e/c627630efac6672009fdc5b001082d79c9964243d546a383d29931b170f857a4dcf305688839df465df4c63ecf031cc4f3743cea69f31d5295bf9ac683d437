"use strict";
var __webpack_require__ = {};
(()=>{
    __webpack_require__.d = (exports1, definition)=>{
        for(var key in definition)if (__webpack_require__.o(definition, key) && !__webpack_require__.o(exports1, key)) Object.defineProperty(exports1, key, {
            enumerable: true,
            get: definition[key]
        });
    };
})();
(()=>{
    __webpack_require__.o = (obj, prop)=>Object.prototype.hasOwnProperty.call(obj, prop);
})();
(()=>{
    __webpack_require__.r = (exports1)=>{
        if ('undefined' != typeof Symbol && Symbol.toStringTag) Object.defineProperty(exports1, Symbol.toStringTag, {
            value: 'Module'
        });
        Object.defineProperty(exports1, '__esModule', {
            value: true
        });
    };
})();
var __webpack_exports__ = {};
__webpack_require__.r(__webpack_exports__);
__webpack_require__.d(__webpack_exports__, {
    BucketedRateLimiter: ()=>BucketedRateLimiter
});
const external_number_utils_js_namespaceObject = require("./number-utils.js");
class BucketedRateLimiter {
    constructor(_options){
        this._options = _options;
        this._buckets = {};
        this._refillBuckets = ()=>{
            Object.keys(this._buckets).forEach((key)=>{
                const newTokens = this._getBucket(key) + this._refillRate;
                if (newTokens >= this._bucketSize) delete this._buckets[key];
                else this._setBucket(key, newTokens);
            });
        };
        this._getBucket = (key)=>this._buckets[String(key)];
        this._setBucket = (key, value)=>{
            this._buckets[String(key)] = value;
        };
        this.consumeRateLimit = (key)=>{
            var _this__getBucket;
            let tokens = null != (_this__getBucket = this._getBucket(key)) ? _this__getBucket : this._bucketSize;
            tokens = Math.max(tokens - 1, 0);
            if (0 === tokens) return true;
            this._setBucket(key, tokens);
            const hasReachedZero = 0 === tokens;
            if (hasReachedZero) {
                var _this__onBucketRateLimited, _this;
                null == (_this__onBucketRateLimited = (_this = this)._onBucketRateLimited) || _this__onBucketRateLimited.call(_this, key);
            }
            return hasReachedZero;
        };
        this._onBucketRateLimited = this._options._onBucketRateLimited;
        this._bucketSize = (0, external_number_utils_js_namespaceObject.clampToRange)(this._options.bucketSize, 0, 100, this._options._logger);
        this._refillRate = (0, external_number_utils_js_namespaceObject.clampToRange)(this._options.refillRate, 0, this._bucketSize, this._options._logger);
        this._refillInterval = (0, external_number_utils_js_namespaceObject.clampToRange)(this._options.refillInterval, 0, 86400000, this._options._logger);
        setInterval(()=>{
            this._refillBuckets();
        }, this._refillInterval);
    }
}
exports.BucketedRateLimiter = __webpack_exports__.BucketedRateLimiter;
for(var __webpack_i__ in __webpack_exports__)if (-1 === [
    "BucketedRateLimiter"
].indexOf(__webpack_i__)) exports[__webpack_i__] = __webpack_exports__[__webpack_i__];
Object.defineProperty(exports, '__esModule', {
    value: true
});
