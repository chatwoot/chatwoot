'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var jsxPlugin = _interopDefault(require('babel-plugin-transform-vue-jsx'));
var eventModifiersPlugin = _interopDefault(require('babel-plugin-jsx-event-modifiers'));
var vModelPlugin = _interopDefault(require('babel-plugin-jsx-v-model'));

var index = (function (_) {
  var _ref = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
      _ref$eventModifiers = _ref.eventModifiers,
      eventModifiers = _ref$eventModifiers === void 0 ? true : _ref$eventModifiers,
      _ref$vModel = _ref.vModel,
      vModel = _ref$vModel === void 0 ? true : _ref$vModel;

  return {
    plugins: [eventModifiers && eventModifiersPlugin, vModel && vModelPlugin, jsxPlugin].filter(Boolean)
  };
});

module.exports = index;
