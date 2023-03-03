export const isWidgetColorLighter = color => {
  const colorToCheck = color.replace('#', '');
  const c_r = parseInt(colorToCheck.substr(0, 2), 16);
  const c_g = parseInt(colorToCheck.substr(2, 2), 16);
  const c_b = parseInt(colorToCheck.substr(4, 2), 16);
  const brightness = (c_r * 299 + c_g * 587 + c_b * 114) / 1000;
  return brightness > 225;
};
