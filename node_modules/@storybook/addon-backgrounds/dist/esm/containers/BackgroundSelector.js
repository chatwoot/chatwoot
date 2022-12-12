function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.array.map.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.regexp.exec.js";
import React, { Fragment, useCallback, useMemo, memo } from 'react';
import memoize from 'memoizerific';
import { useParameter, useGlobals } from '@storybook/api';
import { logger } from '@storybook/client-logger';
import { Icons, IconButton, WithTooltip, TooltipLinkList } from '@storybook/components';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
import { ColorIcon } from '../components/ColorIcon';
import { getBackgroundColorByName } from '../helpers';
var createBackgroundSelectorItem = memoize(1000)(function (id, name, value, hasSwatch, change, active) {
  return {
    id: id || name,
    title: name,
    onClick: function onClick() {
      change({
        selected: value,
        name: name
      });
    },
    value: value,
    right: hasSwatch ? /*#__PURE__*/React.createElement(ColorIcon, {
      background: value
    }) : undefined,
    active: active
  };
});
var getDisplayedItems = memoize(10)(function (backgrounds, selectedBackgroundColor, change) {
  var backgroundSelectorItems = backgrounds.map(function (_ref) {
    var name = _ref.name,
        value = _ref.value;
    return createBackgroundSelectorItem(null, name, value, true, change, value === selectedBackgroundColor);
  });

  if (selectedBackgroundColor !== 'transparent') {
    return [createBackgroundSelectorItem('reset', 'Clear background', 'transparent', null, change, false)].concat(_toConsumableArray(backgroundSelectorItems));
  }

  return backgroundSelectorItems;
});
var DEFAULT_BACKGROUNDS_CONFIG = {
  default: null,
  disable: true,
  values: []
};
export var BackgroundSelector = /*#__PURE__*/memo(function () {
  var _globals$BACKGROUNDS_;

  var backgroundsConfig = useParameter(BACKGROUNDS_PARAM_KEY, DEFAULT_BACKGROUNDS_CONFIG);

  var _useGlobals = useGlobals(),
      _useGlobals2 = _slicedToArray(_useGlobals, 2),
      globals = _useGlobals2[0],
      updateGlobals = _useGlobals2[1];

  var globalsBackgroundColor = (_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.value;
  var selectedBackgroundColor = useMemo(function () {
    return getBackgroundColorByName(globalsBackgroundColor, backgroundsConfig.values, backgroundsConfig.default);
  }, [backgroundsConfig, globalsBackgroundColor]);

  if (Array.isArray(backgroundsConfig)) {
    logger.warn('Addon Backgrounds api has changed in Storybook 6.0. Please refer to the migration guide: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md');
  }

  var onBackgroundChange = useCallback(function (value) {
    updateGlobals(_defineProperty({}, BACKGROUNDS_PARAM_KEY, Object.assign({}, globals[BACKGROUNDS_PARAM_KEY], {
      value: value
    })));
  }, [backgroundsConfig, globals, updateGlobals]);

  if (backgroundsConfig.disable) {
    return null;
  }

  return /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(WithTooltip, {
    placement: "top",
    trigger: "click",
    closeOnClick: true,
    tooltip: function tooltip(_ref2) {
      var onHide = _ref2.onHide;
      return /*#__PURE__*/React.createElement(TooltipLinkList, {
        links: getDisplayedItems(backgroundsConfig.values, selectedBackgroundColor, function (_ref3) {
          var selected = _ref3.selected;

          if (selectedBackgroundColor !== selected) {
            onBackgroundChange(selected);
          }

          onHide();
        })
      });
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    key: "background",
    title: "Change the background of the preview",
    active: selectedBackgroundColor !== 'transparent'
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "photo"
  }))));
});