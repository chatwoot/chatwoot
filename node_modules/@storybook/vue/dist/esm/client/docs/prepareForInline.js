function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import React from 'react';
import Vue from 'vue';
// Inspired by https://github.com/egoist/vue-to-react,
// modified to store args as props in the root store
// FIXME get this from @storybook/vue
var COMPONENT = 'STORYBOOK_COMPONENT';
var VALUES = 'STORYBOOK_VALUES';
export var prepareForInline = function prepareForInline(storyFn, _ref) {
  var args = _ref.args;
  var component = storyFn();
  var el = React.useRef(null); // FIXME: This recreates the Vue instance every time, which should be optimized

  React.useEffect(function () {
    var root = new Vue({
      el: el.current,
      data: function data() {
        var _ref2;

        return _ref2 = {}, _defineProperty(_ref2, COMPONENT, component), _defineProperty(_ref2, VALUES, args), _ref2;
      },
      render: function render(h) {
        var children = this[COMPONENT] ? [h(this[COMPONENT])] : undefined;
        return h('div', {
          attrs: {
            id: 'root'
          }
        }, children);
      }
    });
    return function () {
      return root.$destroy();
    };
  });
  return /*#__PURE__*/React.createElement('div', null, /*#__PURE__*/React.createElement('div', {
    ref: el
  }));
};