'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _slash() {
  const data = _interopRequireDefault(require('slash'));

  _slash = function () {
    return data;
  };

  return data;
}

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

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

class ModuleNotFoundError extends Error {
  constructor(message, moduleName) {
    super(message);

    _defineProperty(this, 'code', 'MODULE_NOT_FOUND');

    _defineProperty(this, 'hint', void 0);

    _defineProperty(this, 'requireStack', void 0);

    _defineProperty(this, 'siblingWithSimilarExtensionFound', void 0);

    _defineProperty(this, 'moduleName', void 0);

    _defineProperty(this, '_originalMessage', void 0);

    this._originalMessage = message;
    this.moduleName = moduleName;
  }

  buildMessage(rootDir) {
    var _this$requireStack;

    if (!this._originalMessage) {
      this._originalMessage = this.message || '';
    }

    let message = this._originalMessage;

    if (
      ((_this$requireStack = this.requireStack) === null ||
      _this$requireStack === void 0
        ? void 0
        : _this$requireStack.length) &&
      this.requireStack.length > 1
    ) {
      message += `

Require stack:
  ${this.requireStack
    .map(p => p.replace(`${rootDir}${path().sep}`, ''))
    .map(_slash().default)
    .join('\n  ')}
`;
    }

    if (this.hint) {
      message += this.hint;
    }

    this.message = message;
  }

  static duckType(error) {
    error.buildMessage = ModuleNotFoundError.prototype.buildMessage;
    return error;
  }
}

exports.default = ModuleNotFoundError;
