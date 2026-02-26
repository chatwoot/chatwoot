import { BUBBLE_DESIGN, DARK_MODE, WIDGET_DESIGN } from './constants';

export const getBubbleView = type =>
  BUBBLE_DESIGN.includes(type) ? type : BUBBLE_DESIGN[0];

export const isExpandedView = type => getBubbleView(type) === BUBBLE_DESIGN[1];

export const getWidgetStyle = style =>
  WIDGET_DESIGN.includes(style) ? style : WIDGET_DESIGN[0];

export const isFlatWidgetStyle = style => style === 'flat';

export const getDarkMode = darkMode =>
  DARK_MODE.includes(darkMode) ? darkMode : DARK_MODE[0];
