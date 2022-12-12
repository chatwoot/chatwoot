"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.WebsocketTransport = void 0;
exports.default = createChannel;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _global = _interopRequireDefault(require("global"));

var _channels = require("@storybook/channels");

var _clientLogger = require("@storybook/client-logger");

var _telejson = require("telejson");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var WebSocket = _global.default.WebSocket;

var WebsocketTransport = /*#__PURE__*/function () {
  function WebsocketTransport(_ref) {
    var url = _ref.url,
        onError = _ref.onError;

    _classCallCheck(this, WebsocketTransport);

    this.socket = void 0;
    this.handler = void 0;
    this.buffer = [];
    this.isReady = false;
    this.connect(url, onError);
  }

  _createClass(WebsocketTransport, [{
    key: "setHandler",
    value: function setHandler(handler) {
      this.handler = handler;
    }
  }, {
    key: "send",
    value: function send(event) {
      if (!this.isReady) {
        this.sendLater(event);
      } else {
        this.sendNow(event);
      }
    }
  }, {
    key: "sendLater",
    value: function sendLater(event) {
      this.buffer.push(event);
    }
  }, {
    key: "sendNow",
    value: function sendNow(event) {
      var data = (0, _telejson.stringify)(event, {
        maxDepth: 15,
        allowFunction: true
      });
      this.socket.send(data);
    }
  }, {
    key: "flush",
    value: function flush() {
      var _this = this;

      var buffer = this.buffer;
      this.buffer = [];
      buffer.forEach(function (event) {
        return _this.send(event);
      });
    }
  }, {
    key: "connect",
    value: function connect(url, onError) {
      var _this2 = this;

      this.socket = new WebSocket(url);

      this.socket.onopen = function () {
        _this2.isReady = true;

        _this2.flush();
      };

      this.socket.onmessage = function (_ref2) {
        var data = _ref2.data;
        var event = typeof data === 'string' && (0, _telejson.isJSON)(data) ? (0, _telejson.parse)(data) : data;

        _this2.handler(event);
      };

      this.socket.onerror = function (e) {
        if (onError) {
          onError(e);
        }
      };
    }
  }]);

  return WebsocketTransport;
}();

exports.WebsocketTransport = WebsocketTransport;

function createChannel(_ref3) {
  var url = _ref3.url,
      _ref3$async = _ref3.async,
      async = _ref3$async === void 0 ? false : _ref3$async,
      _ref3$onError = _ref3.onError,
      onError = _ref3$onError === void 0 ? function (err) {
    return _clientLogger.logger.warn(err);
  } : _ref3$onError;
  var transport = new WebsocketTransport({
    url: url,
    onError: onError
  });
  return new _channels.Channel({
    transport: transport,
    async: async
  });
}