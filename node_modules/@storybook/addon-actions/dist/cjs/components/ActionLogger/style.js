"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.InspectorContainer = exports.Counter = exports.Action = void 0;

require("core-js/modules/es.string.bold.js");

var _theming = require("@storybook/theming");

var _polished = require("polished");

var Action = _theming.styled.div({
  display: 'flex',
  padding: 0,
  borderLeft: '5px solid transparent',
  borderBottom: '1px solid transparent',
  transition: 'all 0.1s',
  alignItems: 'flex-start',
  whiteSpace: 'pre'
});

exports.Action = Action;

var Counter = _theming.styled.div(function (_ref) {
  var theme = _ref.theme;
  return {
    backgroundColor: (0, _polished.opacify)(0.5, theme.appBorderColor),
    color: theme.color.inverseText,
    fontSize: theme.typography.size.s1,
    fontWeight: theme.typography.weight.bold,
    lineHeight: 1,
    padding: '1px 5px',
    borderRadius: 20,
    margin: '2px 0px'
  };
});

exports.Counter = Counter;

var InspectorContainer = _theming.styled.div({
  flex: 1,
  padding: '0 0 0 5px'
});

exports.InspectorContainer = InspectorContainer;