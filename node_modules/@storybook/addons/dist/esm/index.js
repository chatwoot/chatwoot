import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.values.js";
import "core-js/modules/es.promise.js";

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

import global from 'global';
import { Channel } from '@storybook/channels';
import { logger } from '@storybook/client-logger';
import { mockChannel } from './storybook-channel-mock';
import { types } from './types';
export { Channel };
export var AddonStore = /*#__PURE__*/_createClass(function AddonStore() {
  var _this = this;

  _classCallCheck(this, AddonStore);

  this.loaders = {};
  this.elements = {};
  this.config = {};
  this.channel = void 0;
  this.serverChannel = void 0;
  this.promise = void 0;
  this.resolve = void 0;

  this.getChannel = function () {
    // this.channel should get overwritten by setChannel. If it wasn't called (e.g. in non-browser environment), set a mock instead.
    if (!_this.channel) {
      _this.setChannel(mockChannel());
    }

    return _this.channel;
  };

  this.getServerChannel = function () {
    if (!_this.serverChannel) {
      throw new Error('Accessing non-existent serverChannel');
    }

    return _this.serverChannel;
  };

  this.ready = function () {
    return _this.promise;
  };

  this.hasChannel = function () {
    return !!_this.channel;
  };

  this.hasServerChannel = function () {
    return !!_this.serverChannel;
  };

  this.setChannel = function (channel) {
    _this.channel = channel;

    _this.resolve();
  };

  this.setServerChannel = function (channel) {
    _this.serverChannel = channel;
  };

  this.getElements = function (type) {
    if (!_this.elements[type]) {
      _this.elements[type] = {};
    }

    return _this.elements[type];
  };

  this.addPanel = function (name, options) {
    _this.add(name, Object.assign({
      type: types.PANEL
    }, options));
  };

  this.add = function (name, addon) {
    var type = addon.type;

    var collection = _this.getElements(type);

    collection[name] = Object.assign({
      id: name
    }, addon);
  };

  this.setConfig = function (value) {
    Object.assign(_this.config, value);
  };

  this.getConfig = function () {
    return _this.config;
  };

  this.register = function (name, registerCallback) {
    if (_this.loaders[name]) {
      logger.warn("".concat(name, " was loaded twice, this could have bad side-effects"));
    }

    _this.loaders[name] = registerCallback;
  };

  this.loadAddons = function (api) {
    Object.values(_this.loaders).forEach(function (value) {
      return value(api);
    });
  };

  this.promise = new Promise(function (res) {
    _this.resolve = function () {
      return res(_this.getChannel());
    };
  });
}); // Enforce addons store to be a singleton

var KEY = '__STORYBOOK_ADDONS';

function getAddonsStore() {
  if (!global[KEY]) {
    global[KEY] = new AddonStore();
  }

  return global[KEY];
} // Exporting this twice in order to to be able to import it like { addons } instead of 'addons'
// prefer import { addons } from '@storybook/addons' over import addons from '@storybook/addons'
//
// See public_api.ts


export var addons = getAddonsStore();