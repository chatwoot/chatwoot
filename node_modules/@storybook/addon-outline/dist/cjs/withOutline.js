"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.withOutline = void 0;

var _addons = require("@storybook/addons");

var _helpers = require("./helpers");

var _constants = require("./constants");

var _outlineCSS = _interopRequireDefault(require("./outlineCSS"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var withOutline = function withOutline(StoryFn, context) {
  var globals = context.globals;
  var isActive = globals[_constants.PARAM_KEY] === true;
  var isInDocs = context.viewMode === 'docs';
  var outlineStyles = (0, _addons.useMemo)(function () {
    var selector = isInDocs ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
    return (0, _outlineCSS.default)(selector);
  }, [context]);
  (0, _addons.useEffect)(function () {
    var selectorId = isInDocs ? "addon-outline-docs-".concat(context.id) : "addon-outline";

    if (!isActive) {
      (0, _helpers.clearStyles)(selectorId);
    } else {
      (0, _helpers.addOutlineStyles)(selectorId, outlineStyles);
    }

    return function () {
      (0, _helpers.clearStyles)(selectorId);
    };
  }, [isActive, outlineStyles, context]);
  return StoryFn();
};

exports.withOutline = withOutline;