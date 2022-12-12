"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = loader;
exports.raw = void 0;

var _loaderUtils = require("loader-utils");

var _schemaUtils = _interopRequireDefault(require("schema-utils"));

var _mime = _interopRequireDefault(require("mime"));

var _normalizeFallback = _interopRequireDefault(require("./utils/normalizeFallback"));

var _options = _interopRequireDefault(require("./options.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/* eslint-disable
  global-require,
  no-param-reassign,
  prefer-destructuring,
  import/no-dynamic-require,
*/
function shouldTransform(limit, size) {
  if (typeof limit === 'boolean') {
    return limit;
  }

  if (typeof limit === 'string') {
    return size <= parseInt(limit, 10);
  }

  if (typeof limit === 'number') {
    return size <= limit;
  }

  return true;
}

function loader(src) {
  // Loader Options
  const options = (0, _loaderUtils.getOptions)(this) || {};
  (0, _schemaUtils.default)(_options.default, options, {
    name: 'URL Loader',
    baseDataPath: 'options'
  }); // No limit or within the specified limit

  if (shouldTransform(options.limit, src.length)) {
    const file = this.resourcePath; // Get MIME type

    const mimetype = options.mimetype || _mime.default.getType(file);

    if (typeof src === 'string') {
      src = Buffer.from(src);
    }

    return `${options.esModules ? 'export default' : 'module.exports ='} ${JSON.stringify(`data:${mimetype || ''};base64,${src.toString('base64')}`)}`;
  } // Normalize the fallback.


  const {
    loader: fallbackLoader,
    options: fallbackOptions
  } = (0, _normalizeFallback.default)(options.fallback, options); // Require the fallback.

  const fallback = require(fallbackLoader); // Call the fallback, passing a copy of the loader context. The copy has the query replaced. This way, the fallback
  // loader receives the query which was intended for it instead of the query which was intended for url-loader.


  const fallbackLoaderContext = Object.assign({}, this, {
    query: fallbackOptions
  });
  return fallback.call(fallbackLoaderContext, src);
} // Loader Mode


const raw = true;
exports.raw = raw;