"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.prepareForInline = void 0;

var _react = _interopRequireDefault(require("react"));

var _vue = _interopRequireDefault(require("vue"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

// Inspired by https://github.com/egoist/vue-to-react,
// modified to store args as props in the root store
// FIXME get this from @storybook/vue
var COMPONENT = 'STORYBOOK_COMPONENT';
var VALUES = 'STORYBOOK_VALUES';

var prepareForInline = function prepareForInline(storyFn, _ref) {
  var args = _ref.args;
  var component = storyFn();

  var el = _react.default.useRef(null); // FIXME: This recreates the Vue instance every time, which should be optimized


  _react.default.useEffect(function () {
    var root = new _vue.default({
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

  return /*#__PURE__*/_react.default.createElement('div', null, /*#__PURE__*/_react.default.createElement('div', {
    ref: el
  }));
};

exports.prepareForInline = prepareForInline;