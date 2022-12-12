'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
Object.defineProperty(exports, 'clearLine', {
  enumerable: true,
  get: function () {
    return _clearLine.default;
  }
});
Object.defineProperty(exports, 'createDirectory', {
  enumerable: true,
  get: function () {
    return _createDirectory.default;
  }
});
Object.defineProperty(exports, 'ErrorWithStack', {
  enumerable: true,
  get: function () {
    return _ErrorWithStack.default;
  }
});
Object.defineProperty(exports, 'installCommonGlobals', {
  enumerable: true,
  get: function () {
    return _installCommonGlobals.default;
  }
});
Object.defineProperty(exports, 'interopRequireDefault', {
  enumerable: true,
  get: function () {
    return _interopRequireDefault.default;
  }
});
Object.defineProperty(exports, 'isInteractive', {
  enumerable: true,
  get: function () {
    return _isInteractive.default;
  }
});
Object.defineProperty(exports, 'isPromise', {
  enumerable: true,
  get: function () {
    return _isPromise.default;
  }
});
Object.defineProperty(exports, 'setGlobal', {
  enumerable: true,
  get: function () {
    return _setGlobal.default;
  }
});
Object.defineProperty(exports, 'deepCyclicCopy', {
  enumerable: true,
  get: function () {
    return _deepCyclicCopy.default;
  }
});
Object.defineProperty(exports, 'convertDescriptorToString', {
  enumerable: true,
  get: function () {
    return _convertDescriptorToString.default;
  }
});
Object.defineProperty(exports, 'replacePathSepForGlob', {
  enumerable: true,
  get: function () {
    return _replacePathSepForGlob.default;
  }
});
Object.defineProperty(exports, 'testPathPatternToRegExp', {
  enumerable: true,
  get: function () {
    return _testPathPatternToRegExp.default;
  }
});
Object.defineProperty(exports, 'pluralize', {
  enumerable: true,
  get: function () {
    return _pluralize.default;
  }
});
exports.preRunMessage = exports.specialChars = void 0;

var _clearLine = _interopRequireDefault2(require('./clearLine'));

var _createDirectory = _interopRequireDefault2(require('./createDirectory'));

var _ErrorWithStack = _interopRequireDefault2(require('./ErrorWithStack'));

var _installCommonGlobals = _interopRequireDefault2(
  require('./installCommonGlobals')
);

var _interopRequireDefault = _interopRequireDefault2(
  require('./interopRequireDefault')
);

var _isInteractive = _interopRequireDefault2(require('./isInteractive'));

var _isPromise = _interopRequireDefault2(require('./isPromise'));

var _setGlobal = _interopRequireDefault2(require('./setGlobal'));

var _deepCyclicCopy = _interopRequireDefault2(require('./deepCyclicCopy'));

var _convertDescriptorToString = _interopRequireDefault2(
  require('./convertDescriptorToString')
);

var specialChars = _interopRequireWildcard(require('./specialChars'));

exports.specialChars = specialChars;

var _replacePathSepForGlob = _interopRequireDefault2(
  require('./replacePathSepForGlob')
);

var _testPathPatternToRegExp = _interopRequireDefault2(
  require('./testPathPatternToRegExp')
);

var preRunMessage = _interopRequireWildcard(require('./preRunMessage'));

exports.preRunMessage = preRunMessage;

var _pluralize = _interopRequireDefault2(require('./pluralize'));

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

function _interopRequireDefault2(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}
