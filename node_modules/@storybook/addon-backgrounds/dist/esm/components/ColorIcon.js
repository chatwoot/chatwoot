import { styled } from '@storybook/theming';
export var ColorIcon = styled.span(function (_ref) {
  var background = _ref.background;
  return {
    borderRadius: '1rem',
    display: 'block',
    height: '1rem',
    width: '1rem',
    background: background
  };
}, function (_ref2) {
  var theme = _ref2.theme;
  return {
    boxShadow: "".concat(theme.appBorderColor, " 0 0 0 1px inset")
  };
});