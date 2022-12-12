"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isReduceMotionEnabled = exports.getBackgroundColorByName = exports.clearStyles = exports.addGridStyle = exports.addBackgroundStyle = void 0;

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _global = _interopRequireDefault(require("global"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _clientLogger = require("@storybook/client-logger");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var document = _global.default.document,
    window = _global.default.window;

var isReduceMotionEnabled = function isReduceMotionEnabled() {
  var prefersReduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  return prefersReduceMotion.matches;
};

exports.isReduceMotionEnabled = isReduceMotionEnabled;

var getBackgroundColorByName = function getBackgroundColorByName(currentSelectedValue) {
  var backgrounds = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
  var defaultName = arguments.length > 2 ? arguments[2] : undefined;

  if (currentSelectedValue === 'transparent') {
    return 'transparent';
  }

  if (backgrounds.find(function (background) {
    return background.value === currentSelectedValue;
  })) {
    return currentSelectedValue;
  }

  var defaultBackground = backgrounds.find(function (background) {
    return background.name === defaultName;
  });

  if (defaultBackground) {
    return defaultBackground.value;
  }

  if (defaultName) {
    var availableColors = backgrounds.map(function (background) {
      return background.name;
    }).join(', ');

    _clientLogger.logger.warn((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n        Backgrounds Addon: could not find the default color \"", "\".\n        These are the available colors for your story based on your configuration:\n        ", ".\n      "])), defaultName, availableColors));
  }

  return 'transparent';
};

exports.getBackgroundColorByName = getBackgroundColorByName;

var clearStyles = function clearStyles(selector) {
  var selectors = Array.isArray(selector) ? selector : [selector];
  selectors.forEach(clearStyle);
};

exports.clearStyles = clearStyles;

var clearStyle = function clearStyle(selector) {
  var element = document.getElementById(selector);

  if (element) {
    element.parentElement.removeChild(element);
  }
};

var addGridStyle = function addGridStyle(selector, css) {
  var existingStyle = document.getElementById(selector);

  if (existingStyle) {
    if (existingStyle.innerHTML !== css) {
      existingStyle.innerHTML = css;
    }
  } else {
    var style = document.createElement('style');
    style.setAttribute('id', selector);
    style.innerHTML = css;
    document.head.appendChild(style);
  }
};

exports.addGridStyle = addGridStyle;

var addBackgroundStyle = function addBackgroundStyle(selector, css, storyId) {
  var existingStyle = document.getElementById(selector);

  if (existingStyle) {
    if (existingStyle.innerHTML !== css) {
      existingStyle.innerHTML = css;
    }
  } else {
    var style = document.createElement('style');
    style.setAttribute('id', selector);
    style.innerHTML = css;
    var gridStyleSelector = "addon-backgrounds-grid".concat(storyId ? "-docs-".concat(storyId) : ''); // If grids already exist, we want to add the style tag BEFORE it so the background doesn't override grid

    var existingGridStyle = document.getElementById(gridStyleSelector);

    if (existingGridStyle) {
      existingGridStyle.parentElement.insertBefore(style, existingGridStyle);
    } else {
      document.head.appendChild(style);
    }
  }
};

exports.addBackgroundStyle = addBackgroundStyle;