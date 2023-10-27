import tinycolor from 'tinycolor2';

export const isWidgetColorLighter = color => {
  const colorToCheck = color.replace('#', '');
  const c_r = parseInt(colorToCheck.substr(0, 2), 16);
  const c_g = parseInt(colorToCheck.substr(2, 2), 16);
  const c_b = parseInt(colorToCheck.substr(4, 2), 16);
  const brightness = (c_r * 299 + c_g * 587 + c_b * 114) / 1000;
  return brightness > 225;
};

export const adjustColorForContrast = (color, backgroundColor) => {
  const targetRatio = 3.1;
  const getContrastRatio = (color1, color2) => {
    const [L1, L2] = [color1, color2]
      .map(c => tinycolor(c).getLuminance())
      .sort((a, b) => b - a);
    return (L1 + 0.05) / (L2 + 0.05);
  };

  let adjustedColor = tinycolor(color);
  let currentRatio = getContrastRatio(adjustedColor, backgroundColor);

  const MAX_ITERATIONS = 20;
  let iteration = 0;

  while (currentRatio < targetRatio && iteration < MAX_ITERATIONS) {
    if (adjustedColor.isDark()) {
      adjustedColor = adjustedColor.lighten(5);
    } else {
      adjustedColor = adjustedColor.darken(5);
    }

    currentRatio = getContrastRatio(adjustedColor, backgroundColor);
    iteration += 1;
  }

  return adjustedColor.toString();
};
