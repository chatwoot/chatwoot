"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _getLazyHashedEtag = _interopRequireDefault(require("webpack/lib/cache/getLazyHashedEtag"));

var _webpack = require("webpack");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line import/extensions,import/no-unresolved
class Cache {
  // eslint-disable-next-line no-unused-vars
  constructor(compilation, ignored) {
    this.compilation = compilation;
  }

  isEnabled() {
    return Boolean(this.compilation.cache);
  }

  createCacheIdent(task) {
    const {
      outputOptions: {
        hashSalt,
        hashDigest,
        hashDigestLength,
        hashFunction
      }
    } = this.compilation;

    const hash = _webpack.util.createHash(hashFunction);

    if (hashSalt) {
      hash.update(hashSalt);
    }

    hash.update(JSON.stringify(task.cacheKeys));
    const digest = hash.digest(hashDigest);
    const cacheKeys = digest.substr(0, hashDigestLength);
    return `${this.compilation.compilerPath}/CompressionPlugin/${cacheKeys}/${task.filename}`;
  }

  get(task) {
    // eslint-disable-next-line no-param-reassign
    task.cacheIdent = task.cacheIdent || this.createCacheIdent(task); // eslint-disable-next-line no-param-reassign

    task.cacheETag = task.cacheETag || (0, _getLazyHashedEtag.default)(task.assetSource);
    return new Promise((resolve, reject) => {
      this.compilation.cache.get(task.cacheIdent, task.cacheETag, (err, result) => {
        if (err) {
          reject(err);
        } else if (result) {
          resolve(result);
        } else {
          reject();
        }
      });
    });
  }

  store(task, data) {
    return new Promise((resolve, reject) => {
      this.compilation.cache.store(task.cacheIdent, task.cacheETag, data, err => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

}

exports.default = Cache;