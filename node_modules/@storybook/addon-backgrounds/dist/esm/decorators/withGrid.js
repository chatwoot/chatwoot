import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

import "core-js/modules/es.array.join.js";
import "core-js/modules/es.array.concat.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import dedent from 'ts-dedent';
import deprecate from 'util-deprecate';
import { useMemo, useEffect } from '@storybook/addons';
import { clearStyles, addGridStyle } from '../helpers';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
var deprecatedCellSizeWarning = deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Backgrounds Addon: The cell size parameter has been changed.\n\n    - parameters.grid.cellSize should now be parameters.backgrounds.grid.cellSize\n    See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-grid-parameter\n  "]))));
export var withGrid = function withGrid(StoryFn, context) {
  var _globals$BACKGROUNDS_, _parameters$grid, _gridParameters$offse, _gridParameters$offse2;

  var globals = context.globals,
      parameters = context.parameters;
  var gridParameters = parameters[BACKGROUNDS_PARAM_KEY].grid;
  var isActive = ((_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.grid) === true && gridParameters.disable !== true;
  var cellAmount = gridParameters.cellAmount,
      cellSize = gridParameters.cellSize,
      opacity = gridParameters.opacity;
  var isInDocs = context.viewMode === 'docs';
  var gridSize;

  if ((_parameters$grid = parameters.grid) !== null && _parameters$grid !== void 0 && _parameters$grid.cellSize) {
    gridSize = parameters.grid.cellSize;
    deprecatedCellSizeWarning();
  } else {
    gridSize = cellSize;
  }

  var isLayoutPadded = parameters.layout === undefined || parameters.layout === 'padded'; // 16px offset in the grid to account for padded layout

  var defaultOffset = isLayoutPadded ? 16 : 0;
  var offsetX = (_gridParameters$offse = gridParameters.offsetX) !== null && _gridParameters$offse !== void 0 ? _gridParameters$offse : isInDocs ? 20 : defaultOffset;
  var offsetY = (_gridParameters$offse2 = gridParameters.offsetY) !== null && _gridParameters$offse2 !== void 0 ? _gridParameters$offse2 : isInDocs ? 20 : defaultOffset;
  var gridStyles = useMemo(function () {
    var selector = context.viewMode === 'docs' ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
    var backgroundSize = ["".concat(gridSize * cellAmount, "px ").concat(gridSize * cellAmount, "px"), "".concat(gridSize * cellAmount, "px ").concat(gridSize * cellAmount, "px"), "".concat(gridSize, "px ").concat(gridSize, "px"), "".concat(gridSize, "px ").concat(gridSize, "px")].join(', ');
    return "\n      ".concat(selector, " {\n        background-size: ").concat(backgroundSize, " !important;\n        background-position: ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px !important;\n        background-blend-mode: difference !important;\n        background-image: linear-gradient(rgba(130, 130, 130, ").concat(opacity, ") 1px, transparent 1px),\n         linear-gradient(90deg, rgba(130, 130, 130, ").concat(opacity, ") 1px, transparent 1px),\n         linear-gradient(rgba(130, 130, 130, ").concat(opacity / 2, ") 1px, transparent 1px),\n         linear-gradient(90deg, rgba(130, 130, 130, ").concat(opacity / 2, ") 1px, transparent 1px) !important;\n      }\n    ");
  }, [gridSize]);
  useEffect(function () {
    var selectorId = context.viewMode === 'docs' ? "addon-backgrounds-grid-docs-".concat(context.id) : "addon-backgrounds-grid";

    if (!isActive) {
      clearStyles(selectorId);
      return;
    }

    addGridStyle(selectorId, gridStyles);
  }, [isActive, gridStyles, context]);
  return StoryFn();
};