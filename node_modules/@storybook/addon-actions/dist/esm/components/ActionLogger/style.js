import "core-js/modules/es.string.bold.js";
import { styled } from '@storybook/theming';
import { opacify } from 'polished';
export var Action = styled.div({
  display: 'flex',
  padding: 0,
  borderLeft: '5px solid transparent',
  borderBottom: '1px solid transparent',
  transition: 'all 0.1s',
  alignItems: 'flex-start',
  whiteSpace: 'pre'
});
export var Counter = styled.div(function (_ref) {
  var theme = _ref.theme;
  return {
    backgroundColor: opacify(0.5, theme.appBorderColor),
    color: theme.color.inverseText,
    fontSize: theme.typography.size.s1,
    fontWeight: theme.typography.weight.bold,
    lineHeight: 1,
    padding: '1px 5px',
    borderRadius: 20,
    margin: '2px 0px'
  };
});
export var InspectorContainer = styled.div({
  flex: 1,
  padding: '0 0 0 5px'
});