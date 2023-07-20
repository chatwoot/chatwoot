import { colord, extend } from 'colord';
import mixPlugin from 'colord/plugins/mix';
import a11yPlugin from 'colord/plugins/a11y';

extend([a11yPlugin, mixPlugin]);

export const isWidgetColorLighter = color => {
  const colorToCheck = color.replace('#', '');
  const c_r = parseInt(colorToCheck.substr(0, 2), 16);
  const c_g = parseInt(colorToCheck.substr(2, 2), 16);
  const c_b = parseInt(colorToCheck.substr(4, 2), 16);
  const brightness = (c_r * 299 + c_g * 587 + c_b * 114) / 1000;
  return brightness > 225;
};

export const generateColorPalette = baseColor => {
  const palette = {};
  const color = colord(baseColor);
  const isReadableOnWhite = color.isReadable('#fff');

  const shades = color.shades(7).map(c => c.toHex());
  const tints = color.tints(7).map(c => c.toHex());
  const textColor = isReadableOnWhite ? color.toHex() : shades[2];

  // Color variable guidelines
  // textColor - text color variant of brand color which needs to be used on white background

  palette.primary = baseColor;
  palette.text = textColor;
  palette.header = colord('#fff').isReadable(shades[1]) ? '#fff' : shades[5];
  palette.body = colord('#fff').isReadable(shades[1]) ? '#fff' : shades[4];
  palette.textButton = colord('#fff').isReadable(shades[1])
    ? '#fff'
    : shades[5];
  palette.textButtonClear = isReadableOnWhite ? shades[1] : shades[3];
  palette.bgLight = tints[5];

  palette.bgDark = shades[1];
  palette.bgDarker = shades[2];

  return palette;
};

// the rest of the code...

export const addPaletteToCss = (palette, paletteName) => {
  let style = document.createElement('style');
  let cssVariables = `:root { \n`;

  Object.keys(palette).forEach(shade => {
    cssVariables += `--${paletteName}-${shade}: ${palette[shade]};\n`;
  });
  cssVariables += `}`;

  style.innerHTML = cssVariables;
  document.head.appendChild(style);
};
