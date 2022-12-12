"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

class Cache {
  constructor(compilation) {
    this.cache = compilation.getCache('TerserWebpackPlugin');
  }

  async get(cacheData) {
    // eslint-disable-next-line no-param-reassign
    cacheData.eTag = cacheData.eTag || Array.isArray(cacheData.inputSource) ? cacheData.inputSource.map(item => this.cache.getLazyHashedEtag(item)).reduce((previousValue, currentValue) => this.cache.mergeEtags(previousValue, currentValue)) : this.cache.getLazyHashedEtag(cacheData.inputSource);
    return this.cache.getPromise(cacheData.name, cacheData.eTag);
  }

  async store(cacheData) {
    let data;

    if (cacheData.target === 'comments') {
      data = cacheData.output;
    } else {
      data = {
        source: cacheData.source,
        extractedCommentsSource: cacheData.extractedCommentsSource,
        commentsFilename: cacheData.commentsFilename
      };
    }

    return this.cache.storePromise(cacheData.name, cacheData.eTag, data);
  }

}

exports.default = Cache;