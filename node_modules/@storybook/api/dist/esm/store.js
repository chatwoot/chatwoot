import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import store from 'store2';
import storeSetup from './lib/store-setup';
// setting up the store, overriding set and get to use telejson
// @ts-ignore
storeSetup(store._);
export var STORAGE_KEY = '@storybook/ui/store';

function get(storage) {
  var data = storage.get(STORAGE_KEY);
  return data || {};
}

function set(storage, value) {
  return storage.set(STORAGE_KEY, value);
}

function update(storage, patch) {
  var previous = get(storage); // Apply the same behaviour as react here

  return set(storage, Object.assign({}, previous, patch));
}

// Our store piggybacks off the internal React state of the Context Provider
// It has been augmented to persist state to local/sessionStorage
var Store = /*#__PURE__*/function () {
  function Store(_ref) {
    var setState = _ref.setState,
        getState = _ref.getState;

    _classCallCheck(this, Store);

    this.upstreamGetState = void 0;
    this.upstreamSetState = void 0;
    this.upstreamSetState = setState;
    this.upstreamGetState = getState;
  } // The assumption is that this will be called once, to initialize the React state
  // when the module is instantiated


  _createClass(Store, [{
    key: "getInitialState",
    value: function getInitialState(base) {
      // We don't only merge at the very top level (the same way as React setState)
      // when you set keys, so it makes sense to do the same in combining the two storage modes
      // Really, you shouldn't store the same key in both places
      return Object.assign({}, base, get(store.local), get(store.session));
    }
  }, {
    key: "getState",
    value: function getState() {
      return this.upstreamGetState();
    }
  }, {
    key: "setState",
    value: function () {
      var _setState = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(inputPatch, cbOrOptions, inputOptions) {
        var _this = this;

        var callback, options, _ref2, _ref2$persistence, persistence, patch, delta, newState, storage;

        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                if (typeof cbOrOptions === 'function') {
                  callback = cbOrOptions;
                  options = inputOptions;
                } else {
                  options = cbOrOptions;
                }

                _ref2 = options || {}, _ref2$persistence = _ref2.persistence, persistence = _ref2$persistence === void 0 ? 'none' : _ref2$persistence;
                patch = {}; // What did the patch actually return

                delta = {};

                if (typeof inputPatch === 'function') {
                  // Pass the same function, but set delta on the way
                  patch = function patch(state) {
                    var getDelta = inputPatch;
                    delta = getDelta(state);
                    return delta;
                  };
                } else {
                  patch = inputPatch;
                  delta = patch;
                }

                _context.next = 7;
                return new Promise(function (resolve) {
                  _this.upstreamSetState(patch, resolve);
                });

              case 7:
                newState = _context.sent;

                if (!(persistence !== 'none')) {
                  _context.next = 12;
                  break;
                }

                storage = persistence === 'session' ? store.session : store.local;
                _context.next = 12;
                return update(storage, delta);

              case 12:
                if (callback) {
                  callback(newState);
                }

                return _context.abrupt("return", newState);

              case 14:
              case "end":
                return _context.stop();
            }
          }
        }, _callee);
      }));

      function setState(_x, _x2, _x3) {
        return _setState.apply(this, arguments);
      }

      return setState;
    }()
  }]);

  return Store;
}();

export { Store as default };