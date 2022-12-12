"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.withActions = void 0;

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.match.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _global = _interopRequireDefault(require("global"));

var _addons = require("@storybook/addons");

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _actions = require("./actions");

var _constants = require("../constants");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var document = _global.default.document,
    Element = _global.default.Element;
var delegateEventSplitter = /^(\S+)\s*(.*)$/;
var isIE = Element != null && !Element.prototype.matches;
var matchesMethod = isIE ? 'msMatchesSelector' : 'matches';
var root = document && document.getElementById('root');

var hasMatchInAncestry = function hasMatchInAncestry(element, selector) {
  if (element[matchesMethod](selector)) {
    return true;
  }

  var parent = element.parentElement;

  if (!parent) {
    return false;
  }

  return hasMatchInAncestry(parent, selector);
};

var createHandlers = function createHandlers(actionsFn) {
  for (var _len = arguments.length, handles = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
    handles[_key - 1] = arguments[_key];
  }

  var actionsObject = actionsFn.apply(void 0, handles);
  return Object.entries(actionsObject).map(function (_ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        key = _ref2[0],
        action = _ref2[1];

    var _key$match = key.match(delegateEventSplitter),
        _key$match2 = _slicedToArray(_key$match, 3),
        _ = _key$match2[0],
        eventName = _key$match2[1],
        selector = _key$match2[2];

    return {
      eventName: eventName,
      handler: function handler(e) {
        if (!selector || hasMatchInAncestry(e.target, selector)) {
          action(e);
        }
      }
    };
  });
};

var applyEventHandlers = (0, _utilDeprecate.default)(function (actionsFn) {
  for (var _len2 = arguments.length, handles = new Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
    handles[_key2 - 1] = arguments[_key2];
  }

  (0, _addons.useEffect)(function () {
    if (root != null) {
      var handlers = createHandlers.apply(void 0, [actionsFn].concat(handles));
      handlers.forEach(function (_ref3) {
        var eventName = _ref3.eventName,
            handler = _ref3.handler;
        return root.addEventListener(eventName, handler);
      });
      return function () {
        return handlers.forEach(function (_ref4) {
          var eventName = _ref4.eventName,
              handler = _ref4.handler;
          return root.removeEventListener(eventName, handler);
        });
      };
    }

    return undefined;
  }, [root, actionsFn, handles]);
}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    withActions(options) is deprecated, please configure addon-actions using the addParameter api:\n\n    addParameters({\n      actions: {\n        handles: options\n      },\n    });\n  "]))));

var applyDeprecatedOptions = function applyDeprecatedOptions(actionsFn, options) {
  if (options) {
    applyEventHandlers(actionsFn, options);
  }
};

var withActions = (0, _addons.makeDecorator)({
  name: 'withActions',
  parameterName: _constants.PARAM_KEY,
  skipIfNoParametersOrOptions: true,
  wrapper: function wrapper(getStory, context, _ref5) {
    var parameters = _ref5.parameters,
        options = _ref5.options;
    applyDeprecatedOptions(_actions.actions, options);
    if (parameters && parameters.handles) applyEventHandlers.apply(void 0, [_actions.actions].concat(_toConsumableArray(parameters.handles)));
    return getStory(context);
  }
});
exports.withActions = withActions;