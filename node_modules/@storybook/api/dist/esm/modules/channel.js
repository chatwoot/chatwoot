import "core-js/modules/es.array.concat.js";
import { STORIES_COLLAPSE_ALL, STORIES_EXPAND_ALL } from '@storybook/core-events';
export var init = function init(_ref) {
  var provider = _ref.provider;
  var api = {
    getChannel: function getChannel() {
      return provider.channel;
    },
    on: function on(type, cb) {
      provider.channel.addListener(type, cb);
      return function () {
        return provider.channel.removeListener(type, cb);
      };
    },
    off: function off(type, cb) {
      return provider.channel.removeListener(type, cb);
    },
    once: function once(type, cb) {
      return provider.channel.once(type, cb);
    },
    emit: function emit(type) {
      var _provider$channel;

      for (var _len = arguments.length, args = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
        args[_key - 1] = arguments[_key];
      }

      return (_provider$channel = provider.channel).emit.apply(_provider$channel, [type].concat(args));
    },
    collapseAll: function collapseAll() {
      provider.channel.emit(STORIES_COLLAPSE_ALL, {});
    },
    expandAll: function expandAll() {
      api.emit(STORIES_EXPAND_ALL);
    }
  };
  return {
    api: api
  };
};