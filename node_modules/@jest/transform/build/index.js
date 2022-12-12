'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
Object.defineProperty(exports, 'ScriptTransformer', {
  enumerable: true,
  get: function () {
    return _ScriptTransformer.default;
  }
});
Object.defineProperty(exports, 'createTranspilingRequire', {
  enumerable: true,
  get: function () {
    return _ScriptTransformer.createTranspilingRequire;
  }
});
Object.defineProperty(exports, 'shouldInstrument', {
  enumerable: true,
  get: function () {
    return _shouldInstrument.default;
  }
});
Object.defineProperty(exports, 'handlePotentialSyntaxError', {
  enumerable: true,
  get: function () {
    return _enhanceUnexpectedTokenMessage.default;
  }
});

var _ScriptTransformer = _interopRequireWildcard(
  require('./ScriptTransformer')
);

var _shouldInstrument = _interopRequireDefault(require('./shouldInstrument'));

var _enhanceUnexpectedTokenMessage = _interopRequireDefault(
  require('./enhanceUnexpectedTokenMessage')
);

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}
