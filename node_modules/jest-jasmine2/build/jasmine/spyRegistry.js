'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

var _CallTracker = _interopRequireDefault(require('./CallTracker'));

var _SpyStrategy = _interopRequireDefault(require('./SpyStrategy'));

var _createSpy = _interopRequireDefault(require('./createSpy'));

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

const formatErrorMsg = (domain, usage) => {
  const usageDefinition = usage ? '\nUsage: ' + usage : '';
  return msg => domain + ' : ' + msg + usageDefinition;
};

function isSpy(putativeSpy) {
  if (!putativeSpy) {
    return false;
  }

  return (
    putativeSpy.and instanceof _SpyStrategy.default &&
    putativeSpy.calls instanceof _CallTracker.default
  );
}

const getErrorMsg = formatErrorMsg('<spyOn>', 'spyOn(<object>, <methodName>)');

class SpyRegistry {
  constructor({currentSpies = () => []} = {}) {
    _defineProperty(this, 'allowRespy', void 0);

    _defineProperty(this, 'spyOn', void 0);

    _defineProperty(this, 'clearSpies', void 0);

    _defineProperty(this, 'respy', void 0);

    _defineProperty(this, '_spyOnProperty', void 0);

    this.allowRespy = function (allow) {
      this.respy = allow;
    };

    this.spyOn = (obj, methodName, accessType) => {
      if (accessType) {
        return this._spyOnProperty(obj, methodName, accessType);
      }

      if (obj === void 0) {
        throw new Error(
          getErrorMsg(
            'could not find an object to spy upon for ' + methodName + '()'
          )
        );
      }

      if (methodName === void 0) {
        throw new Error(getErrorMsg('No method name supplied'));
      }

      if (obj[methodName] === void 0) {
        throw new Error(getErrorMsg(methodName + '() method does not exist'));
      }

      if (obj[methodName] && isSpy(obj[methodName])) {
        if (this.respy) {
          return obj[methodName];
        } else {
          throw new Error(
            getErrorMsg(methodName + ' has already been spied upon')
          );
        }
      }

      let descriptor;

      try {
        descriptor = Object.getOwnPropertyDescriptor(obj, methodName);
      } catch {
        // IE 8 doesn't support `definePropery` on non-DOM nodes
      }

      if (descriptor && !(descriptor.writable || descriptor.set)) {
        throw new Error(
          getErrorMsg(methodName + ' is not declared writable or has no setter')
        );
      }

      const originalMethod = obj[methodName];
      const spiedMethod = (0, _createSpy.default)(methodName, originalMethod);
      let restoreStrategy;

      if (Object.prototype.hasOwnProperty.call(obj, methodName)) {
        restoreStrategy = function () {
          obj[methodName] = originalMethod;
        };
      } else {
        restoreStrategy = function () {
          if (!delete obj[methodName]) {
            obj[methodName] = originalMethod;
          }
        };
      }

      currentSpies().push({
        restoreObjectToOriginalState: restoreStrategy
      });
      obj[methodName] = spiedMethod;
      return spiedMethod;
    };

    this._spyOnProperty = function (obj, propertyName, accessType = 'get') {
      if (!obj) {
        throw new Error(
          getErrorMsg(
            'could not find an object to spy upon for ' + propertyName
          )
        );
      }

      if (!propertyName) {
        throw new Error(getErrorMsg('No property name supplied'));
      }

      let descriptor;

      try {
        descriptor = Object.getOwnPropertyDescriptor(obj, propertyName);
      } catch {
        // IE 8 doesn't support `definePropery` on non-DOM nodes
      }

      if (!descriptor) {
        throw new Error(getErrorMsg(propertyName + ' property does not exist'));
      }

      if (!descriptor.configurable) {
        throw new Error(
          getErrorMsg(propertyName + ' is not declared configurable')
        );
      }

      if (!descriptor[accessType]) {
        throw new Error(
          getErrorMsg(
            'Property ' +
              propertyName +
              ' does not have access type ' +
              accessType
          )
        );
      }

      if (obj[propertyName] && isSpy(obj[propertyName])) {
        if (this.respy) {
          return obj[propertyName];
        } else {
          throw new Error(
            getErrorMsg(propertyName + ' has already been spied upon')
          );
        }
      }

      const originalDescriptor = descriptor;
      const spiedProperty = (0, _createSpy.default)(
        propertyName,
        descriptor[accessType]
      );
      let restoreStrategy;

      if (Object.prototype.hasOwnProperty.call(obj, propertyName)) {
        restoreStrategy = function () {
          Object.defineProperty(obj, propertyName, originalDescriptor);
        };
      } else {
        restoreStrategy = function () {
          delete obj[propertyName];
        };
      }

      currentSpies().push({
        restoreObjectToOriginalState: restoreStrategy
      });
      const spiedDescriptor = {...descriptor, [accessType]: spiedProperty};
      Object.defineProperty(obj, propertyName, spiedDescriptor);
      return spiedProperty;
    };

    this.clearSpies = function () {
      const spies = currentSpies();

      for (let i = spies.length - 1; i >= 0; i--) {
        const spyEntry = spies[i];
        spyEntry.restoreObjectToOriginalState();
      }
    };
  }
}

exports.default = SpyRegistry;
