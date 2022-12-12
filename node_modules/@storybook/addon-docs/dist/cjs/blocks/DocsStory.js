"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DocsStory = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _react = _interopRequireDefault(require("react"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _Subheading = require("./Subheading");

var _Anchor = require("./Anchor");

var _Description = require("./Description");

var _Story = require("./Story");

var _Canvas = require("./Canvas");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var warnStoryDescription = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Deprecated parameter: docs.storyDescription => docs.description.story\n      \n    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#docs-description-parameter\n  "]))));

var DocsStory = function DocsStory(_ref) {
  var id = _ref.id,
      name = _ref.name,
      _ref$expanded = _ref.expanded,
      expanded = _ref$expanded === void 0 ? true : _ref$expanded,
      _ref$withToolbar = _ref.withToolbar,
      withToolbar = _ref$withToolbar === void 0 ? false : _ref$withToolbar,
      _ref$parameters = _ref.parameters,
      parameters = _ref$parameters === void 0 ? {} : _ref$parameters;
  var description;
  var docs = parameters.docs;

  if (expanded && docs) {
    var _docs$description;

    description = (_docs$description = docs.description) === null || _docs$description === void 0 ? void 0 : _docs$description.story;

    if (!description) {
      description = docs.storyDescription;
      if (description) warnStoryDescription();
    }
  }

  var subheading = expanded && name;
  return /*#__PURE__*/_react.default.createElement(_Anchor.Anchor, {
    storyId: id
  }, subheading && /*#__PURE__*/_react.default.createElement(_Subheading.Subheading, null, subheading), description && /*#__PURE__*/_react.default.createElement(_Description.Description, {
    markdown: description
  }), /*#__PURE__*/_react.default.createElement(_Canvas.Canvas, {
    withToolbar: withToolbar
  }, /*#__PURE__*/_react.default.createElement(_Story.Story, {
    id: id,
    parameters: parameters
  })));
};

exports.DocsStory = DocsStory;