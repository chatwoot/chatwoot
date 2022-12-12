function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import React, { memo } from 'react';
import { useGlobals, useParameter } from '@storybook/api';
import { Icons, IconButton } from '@storybook/components';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
export var GridSelector = /*#__PURE__*/memo(function () {
  var _globals$BACKGROUNDS_;

  var _useGlobals = useGlobals(),
      _useGlobals2 = _slicedToArray(_useGlobals, 2),
      globals = _useGlobals2[0],
      updateGlobals = _useGlobals2[1];

  var _useParameter = useParameter(BACKGROUNDS_PARAM_KEY, {
    grid: {
      disable: false
    }
  }),
      grid = _useParameter.grid;

  if (grid !== null && grid !== void 0 && grid.disable) {
    return null;
  }

  var isActive = ((_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.grid) || false;
  return /*#__PURE__*/React.createElement(IconButton, {
    key: "background",
    active: isActive,
    title: "Apply a grid to the preview",
    onClick: function onClick() {
      return updateGlobals(_defineProperty({}, BACKGROUNDS_PARAM_KEY, Object.assign({}, globals[BACKGROUNDS_PARAM_KEY], {
        grid: !isActive
      })));
    }
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "grid"
  }));
});