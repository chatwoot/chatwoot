function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.reflect.construct.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

import global from 'global';
import { Provider } from '@storybook/ui';
import { addons } from '@storybook/addons';
import createPostMessageChannel from '@storybook/channel-postmessage';
import createWebSocketChannel from '@storybook/channel-websocket';
import Events from '@storybook/core-events';
var FEATURES = global.FEATURES,
    SERVER_CHANNEL_URL = global.SERVER_CHANNEL_URL;

var ReactProvider = /*#__PURE__*/function (_Provider) {
  _inherits(ReactProvider, _Provider);

  var _super = _createSuper(ReactProvider);

  function ReactProvider() {
    var _this;

    _classCallCheck(this, ReactProvider);

    _this = _super.call(this);
    _this.addons = void 0;
    _this.channel = void 0;
    _this.serverChannel = void 0;
    var channel = createPostMessageChannel({
      page: 'manager'
    });
    addons.setChannel(channel);
    channel.emit(Events.CHANNEL_CREATED);
    _this.addons = addons;
    _this.channel = channel;

    if (FEATURES !== null && FEATURES !== void 0 && FEATURES.storyStoreV7 && SERVER_CHANNEL_URL) {
      var serverChannel = createWebSocketChannel({
        url: SERVER_CHANNEL_URL
      });
      _this.serverChannel = serverChannel;
      addons.setServerChannel(_this.serverChannel);
    }

    return _this;
  }

  _createClass(ReactProvider, [{
    key: "getElements",
    value: function getElements(type) {
      return this.addons.getElements(type);
    }
  }, {
    key: "getConfig",
    value: function getConfig() {
      return this.addons.getConfig();
    }
  }, {
    key: "handleAPI",
    value: function handleAPI(api) {
      this.addons.loadAddons(api);
    }
  }]);

  return ReactProvider;
}(Provider);

export { ReactProvider as default };