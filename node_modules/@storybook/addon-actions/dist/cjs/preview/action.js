"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.action = action;

require("core-js/modules/es.object.get-prototype-of.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.get-own-property-descriptors.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.map.js");

var _v = _interopRequireDefault(require("uuid-browser/v4"));

var _addons = require("@storybook/addons");

var _constants = require("../constants");

var _configureActions = require("./configureActions");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

// import('react').SyntheticEvent;
var findProto = function findProto(obj, callback) {
  var proto = Object.getPrototypeOf(obj);
  if (!proto || callback(proto)) return proto;
  return findProto(proto, callback);
};

var isReactSyntheticEvent = function isReactSyntheticEvent(e) {
  return Boolean(_typeof(e) === 'object' && e && findProto(e, function (proto) {
    return /^Synthetic(?:Base)?Event$/.test(proto.constructor.name);
  }) && typeof e.persist === 'function');
};

var serializeArg = function serializeArg(a) {
  if (isReactSyntheticEvent(a)) {
    var e = Object.create(a.constructor.prototype, Object.getOwnPropertyDescriptors(a));
    e.persist();
    var viewDescriptor = Object.getOwnPropertyDescriptor(e, 'view'); // don't send the entire window object over.

    var view = viewDescriptor === null || viewDescriptor === void 0 ? void 0 : viewDescriptor.value;

    if (_typeof(view) === 'object' && (view === null || view === void 0 ? void 0 : view.constructor.name) === 'Window') {
      Object.defineProperty(e, 'view', Object.assign({}, viewDescriptor, {
        value: Object.create(view.constructor.prototype)
      }));
    }

    return e;
  }

  return a;
};

function action(name) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var actionOptions = Object.assign({}, _configureActions.config, options);

  var handler = function actionHandler() {
    var channel = _addons.addons.getChannel();

    var id = (0, _v.default)();
    var minDepth = 5; // anything less is really just storybook internals

    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    var serializedArgs = args.map(serializeArg);
    var normalizedArgs = args.length > 1 ? serializedArgs : serializedArgs[0];
    var actionDisplayToEmit = {
      id: id,
      count: 0,
      data: {
        name: name,
        args: normalizedArgs
      },
      options: Object.assign({}, actionOptions, {
        maxDepth: minDepth + (actionOptions.depth || 3),
        allowFunction: actionOptions.allowFunction || false
      })
    };
    channel.emit(_constants.EVENT_ID, actionDisplayToEmit);
  };

  return handler;
}