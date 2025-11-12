import { clampToRange } from "./number-utils.mjs";
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
        this._bucketSize = clampToRange(this._options.bucketSize, 0, 100, this._options._logger);
        this._refillRate = clampToRange(this._options.refillRate, 0, this._bucketSize, this._options._logger);
        this._refillInterval = clampToRange(this._options.refillInterval, 0, 86400000, this._options._logger);
        setInterval(()=>{
            this._refillBuckets();
        }, this._refillInterval);
    }
}
export { BucketedRateLimiter };
