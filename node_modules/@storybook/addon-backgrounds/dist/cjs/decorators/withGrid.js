"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.withGrid = void 0;

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.array.concat.js");

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _addons = require("@storybook/addons");

var _helpers = require("../helpers");

var _constants = require("../constants");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var deprecatedCellSizeWarning = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Backgrounds Addon: The cell size parameter has been changed.\n\n    - parameters.grid.cellSize should now be parameters.backgrounds.grid.cellSize\n    See https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-grid-parameter\n  "]))));

var withGrid = function withGrid(StoryFn, context) {
  var _globals$BACKGROUNDS_, _parameters$grid, _gridParameters$offse, _gridParameters$offse2;

  var globals = context.globals,
      parameters = context.parameters;
  var gridParameters = parameters[_constants.PARAM_KEY].grid;
  var isActive = ((_globals$BACKGROUNDS_ = globals[_constants.PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.grid) === true && gridParameters.disable !== true;
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
  var gridStyles = (0, _addons.useMemo)(function () {
    var selector = context.viewMode === 'docs' ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
    var backgroundSize = ["".concat(gridSize * cellAmount, "px ").concat(gridSize * cellAmount, "px"), "".concat(gridSize * cellAmount, "px ").concat(gridSize * cellAmount, "px"), "".concat(gridSize, "px ").concat(gridSize, "px"), "".concat(gridSize, "px ").concat(gridSize, "px")].join(', ');
    return "\n      ".concat(selector, " {\n        background-size: ").concat(backgroundSize, " !important;\n        background-position: ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px, ").concat(offsetX, "px ").concat(offsetY, "px !important;\n        background-blend-mode: difference !important;\n        background-image: linear-gradient(rgba(130, 130, 130, ").concat(opacity, ") 1px, transparent 1px),\n         linear-gradient(90deg, rgba(130, 130, 130, ").concat(opacity, ") 1px, transparent 1px),\n         linear-gradient(rgba(130, 130, 130, ").concat(opacity / 2, ") 1px, transparent 1px),\n         linear-gradient(90deg, rgba(130, 130, 130, ").concat(opacity / 2, ") 1px, transparent 1px) !important;\n      }\n    ");
  }, [gridSize]);
  (0, _addons.useEffect)(function () {
    var selectorId = context.viewMode === 'docs' ? "addon-backgrounds-grid-docs-".concat(context.id) : "addon-backgrounds-grid";

    if (!isActive) {
      (0, _helpers.clearStyles)(selectorId);
      return;
    }

    (0, _helpers.addGridStyle)(selectorId, gridStyles);
  }, [isActive, gridStyles, context]);
  return StoryFn();
};

exports.withGrid = withGrid;