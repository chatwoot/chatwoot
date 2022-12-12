'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

var _jestGetType = _interopRequireDefault(require('jest-get-type'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
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

const supportTypes = ['map', 'array', 'object'];

/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
class Replaceable {
  constructor(object) {
    _defineProperty(this, 'object', void 0);

    _defineProperty(this, 'type', void 0);

    this.object = object;
    this.type = (0, _jestGetType.default)(object);

    if (!supportTypes.includes(this.type)) {
      throw new Error(`Type ${this.type} is not support in Replaceable!`);
    }
  }

  static isReplaceable(obj1, obj2) {
    const obj1Type = (0, _jestGetType.default)(obj1);
    const obj2Type = (0, _jestGetType.default)(obj2);
    return obj1Type === obj2Type && supportTypes.includes(obj1Type);
  }

  forEach(cb) {
    if (this.type === 'object') {
      const descriptors = Object.getOwnPropertyDescriptors(this.object);
      [
        ...Object.keys(descriptors),
        ...Object.getOwnPropertySymbols(descriptors)
      ] //@ts-expect-error because typescript do not support symbol key in object
        //https://github.com/microsoft/TypeScript/issues/1863
        .filter(key => descriptors[key].enumerable)
        .forEach(key => {
          cb(this.object[key], key, this.object);
        });
    } else {
      this.object.forEach(cb);
    }
  }

  get(key) {
    if (this.type === 'map') {
      return this.object.get(key);
    }

    return this.object[key];
  }

  set(key, value) {
    if (this.type === 'map') {
      this.object.set(key, value);
    } else {
      this.object[key] = value;
    }
  }
}
/* eslint-enable */

exports.default = Replaceable;
