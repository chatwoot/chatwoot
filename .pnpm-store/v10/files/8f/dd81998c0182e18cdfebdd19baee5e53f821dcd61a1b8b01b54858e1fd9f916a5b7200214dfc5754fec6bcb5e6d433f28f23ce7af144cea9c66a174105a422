'use strict';

const MAX_HUE = 360;
const COLOR_NB = 12;
const MAX_RGB_VALUE = 255;

// https://www.w3.org/TR/css-color-4/#hsl-to-rgb
exports.hslToRgb = (hue, sat, light) => {
  hue = hue % MAX_HUE;
  if (hue < 0) {
    hue += MAX_HUE;
  }
  function f(n) {
    const k = (n + hue / (MAX_HUE / COLOR_NB)) % COLOR_NB;
    const a = sat * Math.min(light, 1 - light);
    return light - a * Math.max(-1, Math.min(k - 3, 9 - k, 1));
  }
  return [f(0), f(8), f(4)].map((value) => Math.round(value * MAX_RGB_VALUE));
};
