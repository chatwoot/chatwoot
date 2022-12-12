"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.drawSelectedElement = drawSelectedElement;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

require("core-js/modules/es.number.is-integer.js");

require("core-js/modules/es.number.constructor.js");

require("core-js/modules/es.number.to-fixed.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.array.concat.js");

var _global = _interopRequireDefault(require("global"));

var _canvas = require("./canvas");

var _labels = require("./labels");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var colors = {
  margin: '#f6b26ba8',
  border: '#ffe599a8',
  padding: '#93c47d8c',
  content: '#6fa8dca8'
};
var SMALL_NODE_SIZE = 30;

function pxToNumber(px) {
  return parseInt(px.replace('px', ''), 10);
}

function round(value) {
  return Number.isInteger(value) ? value : value.toFixed(2);
}

function filterZeroValues(labels) {
  return labels.filter(function (l) {
    return l.text !== 0 && l.text !== '0';
  });
}

function floatingAlignment(extremities) {
  var windowExtremities = {
    top: _global.default.window.scrollY,
    bottom: _global.default.window.scrollY + _global.default.window.innerHeight,
    left: _global.default.window.scrollX,
    right: _global.default.window.scrollX + _global.default.window.innerWidth
  };
  var distances = {
    top: Math.abs(windowExtremities.top - extremities.top),
    bottom: Math.abs(windowExtremities.bottom - extremities.bottom),
    left: Math.abs(windowExtremities.left - extremities.left),
    right: Math.abs(windowExtremities.right - extremities.right)
  };
  return {
    x: distances.left > distances.right ? 'left' : 'right',
    y: distances.top > distances.bottom ? 'top' : 'bottom'
  };
}

function measureElement(element) {
  var style = _global.default.getComputedStyle(element); // eslint-disable-next-line prefer-const


  var _element$getBoundingC = element.getBoundingClientRect(),
      top = _element$getBoundingC.top,
      left = _element$getBoundingC.left,
      right = _element$getBoundingC.right,
      bottom = _element$getBoundingC.bottom,
      width = _element$getBoundingC.width,
      height = _element$getBoundingC.height;

  var marginTop = style.marginTop,
      marginBottom = style.marginBottom,
      marginLeft = style.marginLeft,
      marginRight = style.marginRight,
      paddingTop = style.paddingTop,
      paddingBottom = style.paddingBottom,
      paddingLeft = style.paddingLeft,
      paddingRight = style.paddingRight,
      borderBottomWidth = style.borderBottomWidth,
      borderTopWidth = style.borderTopWidth,
      borderLeftWidth = style.borderLeftWidth,
      borderRightWidth = style.borderRightWidth;
  top = top + _global.default.window.scrollY;
  left = left + _global.default.window.scrollX;
  bottom = bottom + _global.default.window.scrollY;
  right = right + _global.default.window.scrollX;
  var margin = {
    top: pxToNumber(marginTop),
    bottom: pxToNumber(marginBottom),
    left: pxToNumber(marginLeft),
    right: pxToNumber(marginRight)
  };
  var padding = {
    top: pxToNumber(paddingTop),
    bottom: pxToNumber(paddingBottom),
    left: pxToNumber(paddingLeft),
    right: pxToNumber(paddingRight)
  };
  var border = {
    top: pxToNumber(borderTopWidth),
    bottom: pxToNumber(borderBottomWidth),
    left: pxToNumber(borderLeftWidth),
    right: pxToNumber(borderRightWidth)
  };
  var extremities = {
    top: top - margin.top,
    bottom: bottom + margin.bottom,
    left: left - margin.left,
    right: right + margin.right
  };
  return {
    margin: margin,
    padding: padding,
    border: border,
    top: top,
    left: left,
    bottom: bottom,
    right: right,
    width: width,
    height: height,
    extremities: extremities,
    floatingAlignment: floatingAlignment(extremities)
  };
}

function drawMargin(context, _ref) {
  var margin = _ref.margin,
      width = _ref.width,
      height = _ref.height,
      top = _ref.top,
      left = _ref.left,
      bottom = _ref.bottom,
      right = _ref.right;
  // Draw Margin
  var marginHeight = height + margin.bottom + margin.top;
  context.fillStyle = colors.margin; // Top margin rect

  context.fillRect(left, top - margin.top, width, margin.top); // Right margin rect

  context.fillRect(right, top - margin.top, margin.right, marginHeight); // Bottom margin rect

  context.fillRect(left, bottom, width, margin.bottom); // Left margin rect

  context.fillRect(left - margin.left, top - margin.top, margin.left, marginHeight);
  var marginLabels = [{
    type: 'margin',
    text: round(margin.top),
    position: 'top'
  }, {
    type: 'margin',
    text: round(margin.right),
    position: 'right'
  }, {
    type: 'margin',
    text: round(margin.bottom),
    position: 'bottom'
  }, {
    type: 'margin',
    text: round(margin.left),
    position: 'left'
  }];
  return filterZeroValues(marginLabels);
}

function drawPadding(context, _ref2) {
  var padding = _ref2.padding,
      border = _ref2.border,
      width = _ref2.width,
      height = _ref2.height,
      top = _ref2.top,
      left = _ref2.left,
      bottom = _ref2.bottom,
      right = _ref2.right;
  var paddingWidth = width - border.left - border.right;
  var paddingHeight = height - padding.top - padding.bottom - border.top - border.bottom;
  context.fillStyle = colors.padding; // Top padding rect

  context.fillRect(left + border.left, top + border.top, paddingWidth, padding.top); // Right padding rect

  context.fillRect(right - padding.right - border.right, top + padding.top + border.top, padding.right, paddingHeight); // Bottom padding rect

  context.fillRect(left + border.left, bottom - padding.bottom - border.bottom, paddingWidth, padding.bottom); // Left padding rect

  context.fillRect(left + border.left, top + padding.top + border.top, padding.left, paddingHeight);
  var paddingLabels = [{
    type: 'padding',
    text: padding.top,
    position: 'top'
  }, {
    type: 'padding',
    text: padding.right,
    position: 'right'
  }, {
    type: 'padding',
    text: padding.bottom,
    position: 'bottom'
  }, {
    type: 'padding',
    text: padding.left,
    position: 'left'
  }];
  return filterZeroValues(paddingLabels);
}

function drawBorder(context, _ref3) {
  var border = _ref3.border,
      width = _ref3.width,
      height = _ref3.height,
      top = _ref3.top,
      left = _ref3.left,
      bottom = _ref3.bottom,
      right = _ref3.right;
  var borderHeight = height - border.top - border.bottom;
  context.fillStyle = colors.border; // Top border rect

  context.fillRect(left, top, width, border.top); // Bottom border rect

  context.fillRect(left, bottom - border.bottom, width, border.bottom); // Left border rect

  context.fillRect(left, top + border.top, border.left, borderHeight); // Right border rect

  context.fillRect(right - border.right, top + border.top, border.right, borderHeight);
  var borderLabels = [{
    type: 'border',
    text: border.top,
    position: 'top'
  }, {
    type: 'border',
    text: border.right,
    position: 'right'
  }, {
    type: 'border',
    text: border.bottom,
    position: 'bottom'
  }, {
    type: 'border',
    text: border.left,
    position: 'left'
  }];
  return filterZeroValues(borderLabels);
}

function drawContent(context, _ref4) {
  var padding = _ref4.padding,
      border = _ref4.border,
      width = _ref4.width,
      height = _ref4.height,
      top = _ref4.top,
      left = _ref4.left;
  var contentWidth = width - border.left - border.right - padding.left - padding.right;
  var contentHeight = height - padding.top - padding.bottom - border.top - border.bottom;
  context.fillStyle = colors.content; // content rect

  context.fillRect(left + border.left + padding.left, top + border.top + padding.top, contentWidth, contentHeight); // Dimension label

  return [{
    type: 'content',
    position: 'center',
    text: "".concat(round(contentWidth), " x ").concat(round(contentHeight))
  }];
}

function drawBoxModel(element) {
  return function (context) {
    if (element && context) {
      var measurements = measureElement(element);
      var marginLabels = drawMargin(context, measurements);
      var paddingLabels = drawPadding(context, measurements);
      var borderLabels = drawBorder(context, measurements);
      var contentLabels = drawContent(context, measurements);
      var externalLabels = measurements.width <= SMALL_NODE_SIZE * 3 || measurements.height <= SMALL_NODE_SIZE;
      (0, _labels.labelStacks)(context, measurements, [].concat(_toConsumableArray(contentLabels), _toConsumableArray(paddingLabels), _toConsumableArray(borderLabels), _toConsumableArray(marginLabels)), externalLabels);
    }
  };
}

function drawSelectedElement(element) {
  (0, _canvas.draw)(drawBoxModel(element));
}