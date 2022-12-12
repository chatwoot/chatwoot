function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.get-own-property-descriptors.js";
import "core-js/modules/es.object.get-own-property-descriptor.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import uuidv4 from 'uuid-browser/v4';
import { addons } from '@storybook/addons';
import { EVENT_ID } from '../constants';
import { config } from './configureActions';

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

export function action(name) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var actionOptions = Object.assign({}, config, options);

  var handler = function actionHandler() {
    var channel = addons.getChannel();
    var id = uuidv4();
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
    channel.emit(EVENT_ID, actionDisplayToEmit);
  };

  return handler;
}