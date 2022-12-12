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

import React, { useState, useEffect } from 'react';
import { addons, types } from '@storybook/addons';
import { STORY_CHANGED } from '@storybook/core-events';
import ActionLogger from './containers/ActionLogger';
import { ADDON_ID, EVENT_ID, PANEL_ID, PARAM_KEY } from './constants';
addons.register(ADDON_ID, function (api) {
  addons.addPanel(PANEL_ID, {
    title: function title() {
      var _useState = useState(0),
          _useState2 = _slicedToArray(_useState, 2),
          actionsCount = _useState2[0],
          setActionsCount = _useState2[1];

      var onEvent = function onEvent() {
        return setActionsCount(function (previous) {
          return previous + 1;
        });
      };

      var onChange = function onChange() {
        return setActionsCount(0);
      };

      useEffect(function () {
        api.on(EVENT_ID, onEvent);
        api.on(STORY_CHANGED, onChange);
        return function () {
          api.off(EVENT_ID, onEvent);
          api.off(STORY_CHANGED, onChange);
        };
      });
      var suffix = actionsCount === 0 ? '' : " (".concat(actionsCount, ")");
      return "Actions".concat(suffix);
    },
    type: types.PANEL,
    render: function render(_ref) {
      var active = _ref.active,
          key = _ref.key;
      return /*#__PURE__*/React.createElement(ActionLogger, {
        key: key,
        api: api,
        active: active
      });
    },
    paramKey: PARAM_KEY
  });
});