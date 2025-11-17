import { parseToHsla } from 'color2k';

let themeColorStyleId = 'chatwoot-theme-colors';

export const hexToRgb = hex => {
  // Simple hex to RGB conversion without external dependencies
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) {
    return { r: 0, g: 0, b: 0 };
  }
  return {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16),
  };
};

const hslToRgb = (h, s, l) => {
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  let m = l - c / 2;

  let r;
  let g;
  let b;

  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255),
  };
};

export const generateColorTones = (hex, isDark = false) => {
  const tones = {};
  const hsla = parseToHsla(hex);
  const baseHue = hsla[0];
  const baseSaturation = hsla[1];

  const lightnessList = isDark
    ? [0.95, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.15, 0.1, 0.05]
    : [0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95];

  lightnessList.forEach((lightness, index) => {
    const tone = index + 1;
    const rgb = hslToRgb(baseHue, baseSaturation, lightness);
    tones[tone] = `${rgb.r} ${rgb.g} ${rgb.b}`;
  });

  return tones;
};

export const applyThemeColors = primaryHex => {
  if (!primaryHex || !primaryHex.startsWith('#')) {
    return;
  }

  const lightTones = generateColorTones(primaryHex, false);
  const darkTones = generateColorTones(primaryHex, true);

  const root = document.documentElement;

  // Apply light theme colors (default)
  Object.entries(lightTones).forEach(([tone, rgb]) => {
    root.style.setProperty(`--dl-primary-color-${tone}`, rgb);
  });

  // Remove existing dark theme style if it exists
  const existingStyle = document.getElementById(themeColorStyleId);
  if (existingStyle) {
    existingStyle.remove();
  }

  // Apply dark theme colors under .dark selector
  const style = document.createElement('style');
  style.id = themeColorStyleId;
  let darkCss = '.dark {\n';
  Object.entries(darkTones).forEach(([tone, rgb]) => {
    darkCss += `  --dl-primary-color-${tone}: ${rgb};\n`;
  });
  darkCss += '}';
  style.textContent = darkCss;
  document.head.appendChild(style);
};

export const initializeThemeColor = primaryHex => {
  applyThemeColors(primaryHex);
};
