function _toArray(arr) { return _arrayWithHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableRest(); }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.from-entries.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.number.is-integer.js";
import "core-js/modules/es.number.constructor.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.search.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.object.values.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/web.url.js";
import "core-js/modules/web.url-search-params.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import global from 'global';
import * as EVENTS from '@storybook/core-events';
import Channel from '@storybook/channels';
import { logger, pretty } from '@storybook/client-logger';
import { isJSON, parse, stringify } from 'telejson';
import qs from 'qs';
var globalWindow = global.window,
    document = global.document,
    location = global.location;
export var KEY = 'storybook-channel';
var defaultEventOptions = {
  allowFunction: true,
  maxDepth: 25
}; // TODO: we should export a method for opening child windows here and keep track of em.
// that way we can send postMessage to child windows as well, not just iframe
// https://stackoverflow.com/questions/6340160/how-to-get-the-references-of-all-already-opened-child-windows

export var PostmsgTransport = /*#__PURE__*/function () {
  function PostmsgTransport(config) {
    _classCallCheck(this, PostmsgTransport);

    this.config = config;
    this.buffer = void 0;
    this.handler = void 0;
    this.connected = void 0;
    this.buffer = [];
    this.handler = null;
    globalWindow.addEventListener('message', this.handleEvent.bind(this), false); // Check whether the config.page parameter has a valid value

    if (config.page !== 'manager' && config.page !== 'preview') {
      throw new Error("postmsg-channel: \"config.page\" cannot be \"".concat(config.page, "\""));
    }
  }

  _createClass(PostmsgTransport, [{
    key: "setHandler",
    value: function setHandler(handler) {
      var _this = this;

      this.handler = function () {
        for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
          args[_key] = arguments[_key];
        }

        handler.apply(_this, args);

        if (!_this.connected && _this.getLocalFrame().length) {
          _this.flush();

          _this.connected = true;
        }
      };
    }
    /**
     * Sends `event` to the associated window. If the window does not yet exist
     * the event will be stored in a buffer and sent when the window exists.
     * @param event
     */

  }, {
    key: "send",
    value: function send(event, options) {
      var _this2 = this;

      var _ref = options || {},
          target = _ref.target,
          allowRegExp = _ref.allowRegExp,
          allowFunction = _ref.allowFunction,
          allowSymbol = _ref.allowSymbol,
          allowDate = _ref.allowDate,
          allowUndefined = _ref.allowUndefined,
          allowClass = _ref.allowClass,
          maxDepth = _ref.maxDepth,
          space = _ref.space,
          lazyEval = _ref.lazyEval;

      var eventOptions = Object.fromEntries(Object.entries({
        allowRegExp: allowRegExp,
        allowFunction: allowFunction,
        allowSymbol: allowSymbol,
        allowDate: allowDate,
        allowUndefined: allowUndefined,
        allowClass: allowClass,
        maxDepth: maxDepth,
        space: space,
        lazyEval: lazyEval
      }).filter(function (_ref2) {
        var _ref3 = _slicedToArray(_ref2, 2),
            k = _ref3[0],
            v = _ref3[1];

        return typeof v !== 'undefined';
      }));
      var stringifyOptions = Object.assign({}, defaultEventOptions, global.CHANNEL_OPTIONS || {}, eventOptions); // backwards compat: convert depth to maxDepth

      if (options && Number.isInteger(options.depth)) {
        stringifyOptions.maxDepth = options.depth;
      }

      var frames = this.getFrames(target);
      var query = qs.parse(location.search, {
        ignoreQueryPrefix: true
      });
      var data = stringify({
        key: KEY,
        event: event,
        refId: query.refId
      }, stringifyOptions);

      if (!frames.length) {
        return new Promise(function (resolve, reject) {
          _this2.buffer.push({
            event: event,
            resolve: resolve,
            reject: reject
          });
        });
      }

      if (this.buffer.length) {
        this.flush();
      }

      frames.forEach(function (f) {
        try {
          f.postMessage(data, '*');
        } catch (e) {
          console.error('sending over postmessage fail');
        }
      });
      return Promise.resolve(null);
    }
  }, {
    key: "flush",
    value: function flush() {
      var _this3 = this;

      var buffer = this.buffer;
      this.buffer = [];
      buffer.forEach(function (item) {
        _this3.send(item.event).then(item.resolve).catch(item.reject);
      });
    }
  }, {
    key: "getFrames",
    value: function getFrames(target) {
      if (this.config.page === 'manager') {
        var nodes = _toConsumableArray(document.querySelectorAll('iframe[data-is-storybook][data-is-loaded]'));

        var list = nodes.filter(function (e) {
          try {
            return !!e.contentWindow && e.dataset.isStorybook !== undefined && e.id === target;
          } catch (er) {
            return false;
          }
        }).map(function (e) {
          return e.contentWindow;
        });
        return list.length ? list : this.getCurrentFrames();
      }

      if (globalWindow && globalWindow.parent && globalWindow.parent !== globalWindow) {
        return [globalWindow.parent];
      }

      return [];
    }
  }, {
    key: "getCurrentFrames",
    value: function getCurrentFrames() {
      if (this.config.page === 'manager') {
        var list = _toConsumableArray(document.querySelectorAll('[data-is-storybook="true"]'));

        return list.map(function (e) {
          return e.contentWindow;
        });
      }

      if (globalWindow && globalWindow.parent) {
        return [globalWindow.parent];
      }

      return [];
    }
  }, {
    key: "getLocalFrame",
    value: function getLocalFrame() {
      if (this.config.page === 'manager') {
        var list = _toConsumableArray(document.querySelectorAll('#storybook-preview-iframe'));

        return list.map(function (e) {
          return e.contentWindow;
        });
      }

      if (globalWindow && globalWindow.parent) {
        return [globalWindow.parent];
      }

      return [];
    }
  }, {
    key: "handleEvent",
    value: function handleEvent(rawEvent) {
      try {
        var data = rawEvent.data;

        var _ref4 = typeof data === 'string' && isJSON(data) ? parse(data, global.CHANNEL_OPTIONS || {}) : data,
            key = _ref4.key,
            event = _ref4.event,
            refId = _ref4.refId;

        if (key === KEY) {
          var pageString = this.config.page === 'manager' ? "<span style=\"color: #37D5D3; background: black\"> manager </span>" : "<span style=\"color: #1EA7FD; background: black\"> preview </span>";
          var eventString = Object.values(EVENTS).includes(event.type) ? "<span style=\"color: #FF4785\">".concat(event.type, "</span>") : "<span style=\"color: #FFAE00\">".concat(event.type, "</span>");

          if (refId) {
            event.refId = refId;
          }

          event.source = this.config.page === 'preview' ? rawEvent.origin : getEventSourceUrl(rawEvent);

          if (!event.source) {
            pretty.error("".concat(pageString, " received ").concat(eventString, " but was unable to determine the source of the event"));
            return;
          }

          var message = "".concat(pageString, " received ").concat(eventString, " (").concat(data.length, ")");
          pretty.debug.apply(pretty, [location.origin !== event.source ? message : "".concat(message, " <span style=\"color: gray\">(on ").concat(location.origin, " from ").concat(event.source, ")</span>")].concat(_toConsumableArray(event.args)));
          this.handler(event);
        }
      } catch (error) {
        logger.error(error);
      }
    }
  }]);

  return PostmsgTransport;
}();

var getEventSourceUrl = function getEventSourceUrl(event) {
  var frames = _toConsumableArray(document.querySelectorAll('iframe[data-is-storybook]')); // try to find the originating iframe by matching it's contentWindow
  // This might not be cross-origin safe


  var _frames$filter = frames.filter(function (element) {
    try {
      return element.contentWindow === event.source;
    } catch (err) {// continue
    }

    var src = element.getAttribute('src');
    var origin;

    try {
      var _URL = new URL(src, document.location);

      origin = _URL.origin;
    } catch (err) {
      return false;
    }

    return origin === event.origin;
  }),
      _frames$filter2 = _toArray(_frames$filter),
      frame = _frames$filter2[0],
      remainder = _frames$filter2.slice(1);

  if (frame && remainder.length === 0) {
    var src = frame.getAttribute('src');

    var _URL2 = new URL(src, document.location),
        protocol = _URL2.protocol,
        host = _URL2.host,
        pathname = _URL2.pathname;

    return "".concat(protocol, "//").concat(host).concat(pathname);
  }

  if (remainder.length > 0) {
    // If we found multiple matches, there's going to be trouble
    logger.error('found multiple candidates for event source');
  } // If we found no frames of matches


  return null;
};
/**
 * Creates a channel which communicates with an iframe or child window.
 */


export default function createChannel(_ref5) {
  var page = _ref5.page;
  var transport = new PostmsgTransport({
    page: page
  });
  return new Channel({
    transport: transport
  });
}