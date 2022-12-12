"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.clearStyles = exports.addOutlineStyles = void 0;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _global = _interopRequireDefault(require("global"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var clearStyles = function clearStyles(selector) {
  var selectors = Array.isArray(selector) ? selector : [selector];
  selectors.forEach(clearStyle);
};

exports.clearStyles = clearStyles;

var clearStyle = function clearStyle(selector) {
  var element = _global.default.document.getElementById(selector);

  if (element && element.parentElement) {
    element.parentElement.removeChild(element);
  }
};

var addOutlineStyles = function addOutlineStyles(selector, css) {
  var existingStyle = _global.default.document.getElementById(selector);

  if (existingStyle) {
    if (existingStyle.innerHTML !== css) {
      existingStyle.innerHTML = css;
    }
  } else {
    var style = _global.default.document.createElement('style');

    style.setAttribute('id', selector);
    style.innerHTML = css;

    _global.default.document.head.appendChild(style);
  }
};

exports.addOutlineStyles = addOutlineStyles;