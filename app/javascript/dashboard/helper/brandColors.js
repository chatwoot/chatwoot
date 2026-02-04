const LIGHTNESS_SCALE_LIGHT = [
  99.2, 98.0, 95.7, 92.7, 89.4, 85.5, 79.8, 71.4, 55.9, 48.8, 45.5, 22.0,
];

const LIGHTNESS_SCALE_DARK = [
  7.5, 10.4, 17.1, 21.4, 26.5, 32.0, 38.4, 45.9, 55.9, 49.4, 74.7, 90.2,
];

const REFERENCE_LIGHTNESS = 55.9;
const SCALE_SIZE = 12;
const BRAND_TEXT_LIGHT = { r: 255, g: 255, b: 255 };
const BRAND_TEXT_DARK = { r: 17, g: 24, b: 39 };
const BRAND_TEXT_MIN_CONTRAST = 3.0;

const DERIVED_LIGHT = {
  solidBlue: 4,
  solidBlue2: 1,
  borderBlueStrong: 12,
  textBlue: 12,
};

const DERIVED_DARK = {
  solidBlue: 4,
  solidBlue2: 2,
  borderBlueStrong: 12,
  textBlue: 12,
};

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

const toInt = value => Number.parseInt(value, 10);

const parseHexColor = value => {
  const normalized = value.replace('#', '').trim();
  if (normalized.length === 3) {
    const expanded = normalized
      .split('')
      .map(channel => `${channel}${channel}`)
      .join('');
    return parseHexColor(expanded);
  }
  if (normalized.length !== 6) {
    return null;
  }
  const r = Number.parseInt(normalized.slice(0, 2), 16);
  const g = Number.parseInt(normalized.slice(2, 4), 16);
  const b = Number.parseInt(normalized.slice(4, 6), 16);
  if ([r, g, b].some(channel => Number.isNaN(channel))) {
    return null;
  }
  return { r, g, b };
};

const parseRgbColor = value => {
  const match = value
    .replace(/\s+/g, '')
    .match(/^rgb\((\d{1,3}),(\d{1,3}),(\d{1,3})\)$/i);
  if (!match) {
    return null;
  }
  const r = toInt(match[1]);
  const g = toInt(match[2]);
  const b = toInt(match[3]);
  if ([r, g, b].some(channel => Number.isNaN(channel))) {
    return null;
  }
  if ([r, g, b].some(channel => channel < 0 || channel > 255)) {
    return null;
  }
  return { r, g, b };
};

const normalizeColor = value => {
  if (!value) {
    return null;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }
  if (trimmed.startsWith('#')) {
    return parseHexColor(trimmed);
  }
  if (trimmed.toLowerCase().startsWith('rgb')) {
    return parseRgbColor(trimmed);
  }
  return null;
};

const rgbToHsl = ({ r, g, b }) => {
  const rNorm = r / 255;
  const gNorm = g / 255;
  const bNorm = b / 255;
  const max = Math.max(rNorm, gNorm, bNorm);
  const min = Math.min(rNorm, gNorm, bNorm);
  const delta = max - min;
  const lightness = (max + min) / 2;
  if (delta === 0) {
    return { h: 0, s: 0, l: lightness * 100 };
  }
  const saturation =
    lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min);
  let hue = 0;
  if (max === rNorm) {
    hue = (gNorm - bNorm) / delta + (gNorm < bNorm ? 6 : 0);
  }
  if (max === gNorm) {
    hue = (bNorm - rNorm) / delta + 2;
  }
  if (max === bNorm) {
    hue = (rNorm - gNorm) / delta + 4;
  }
  hue *= 60;
  return { h: hue, s: saturation * 100, l: lightness * 100 };
};

const hueToRgb = (p, q, t) => {
  let normalized = t;
  if (normalized < 0) {
    normalized += 1;
  }
  if (normalized > 1) {
    normalized -= 1;
  }
  if (normalized < 1 / 6) {
    return p + (q - p) * 6 * normalized;
  }
  if (normalized < 1 / 2) {
    return q;
  }
  if (normalized < 2 / 3) {
    return p + (q - p) * (2 / 3 - normalized) * 6;
  }
  return p;
};

const hslToRgb = (h, s, l) => {
  const hue = h / 360;
  const saturation = clamp(s, 0, 100) / 100;
  const lightness = clamp(l, 0, 100) / 100;
  if (saturation === 0) {
    const value = Math.round(lightness * 255);
    return { r: value, g: value, b: value };
  }
  const q =
    lightness < 0.5
      ? lightness * (1 + saturation)
      : lightness + saturation - lightness * saturation;
  const p = 2 * lightness - q;
  const r = hueToRgb(p, q, hue + 1 / 3);
  const g = hueToRgb(p, q, hue);
  const b = hueToRgb(p, q, hue - 1 / 3);
  return {
    r: Math.round(r * 255),
    g: Math.round(g * 255),
    b: Math.round(b * 255),
  };
};

const toLinearChannel = channel => {
  const value = channel / 255;
  if (value <= 0.03928) {
    return value / 12.92;
  }
  return ((value + 0.055) / 1.055) ** 2.4;
};

const relativeLuminance = color => {
  const r = toLinearChannel(color.r);
  const g = toLinearChannel(color.g);
  const b = toLinearChannel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

const contrastRatio = (colorA, colorB) => {
  const lumA = relativeLuminance(colorA);
  const lumB = relativeLuminance(colorB);
  const brightest = Math.max(lumA, lumB);
  const darkest = Math.min(lumA, lumB);
  return (brightest + 0.05) / (darkest + 0.05);
};

const pickBrandText = baseColor => {
  const lightContrast = contrastRatio(baseColor, BRAND_TEXT_LIGHT);
  if (lightContrast >= BRAND_TEXT_MIN_CONTRAST) {
    return BRAND_TEXT_LIGHT;
  }
  return BRAND_TEXT_DARK;
};

const buildScale = (base, lightnessScale) => {
  const { h, s, l } = rgbToHsl(base);
  const delta = l - REFERENCE_LIGHTNESS;
  return lightnessScale.map(lightness =>
    hslToRgb(h, s, clamp(lightness + delta, 0, 100))
  );
};

const formatRgb = color => `${color.r} ${color.g} ${color.b}`;
const formatRgba = (color, alpha) =>
  `${color.r}, ${color.g}, ${color.b}, ${alpha}`;

const applyScale = (element, scale) => {
  if (!element) {
    return;
  }
  scale.forEach((color, index) => {
    element.style.setProperty(`--blue-${index + 1}`, formatRgb(color));
  });
};

const clearScale = element => {
  if (!element) {
    return;
  }
  Array.from({ length: SCALE_SIZE }).forEach((_, index) => {
    element.style.removeProperty(`--blue-${index + 1}`);
  });
};

const applyDerivedVars = (element, scale, baseColor, mapping) => {
  if (!element) {
    return;
  }
  const brandText = pickBrandText(baseColor);
  const pick = step => scale[step - 1];
  element.style.setProperty('--solid-blue', formatRgb(pick(mapping.solidBlue)));
  element.style.setProperty(
    '--solid-blue-2',
    formatRgb(pick(mapping.solidBlue2))
  );
  element.style.setProperty(
    '--border-blue-strong',
    formatRgb(pick(mapping.borderBlueStrong))
  );
  element.style.setProperty('--text-blue', formatRgb(pick(mapping.textBlue)));
  element.style.setProperty('--border-blue', formatRgba(baseColor, 0.5));
  element.style.setProperty('--brand-contrast', formatRgb(brandText));
};

const applyThemeVars = (element, scale, baseColor, mapping) => {
  applyScale(element, scale);
  applyDerivedVars(element, scale, baseColor, mapping);
};

const clearDerivedVars = element => {
  if (!element) {
    return;
  }
  [
    '--solid-blue',
    '--solid-blue-2',
    '--border-blue-strong',
    '--text-blue',
    '--border-blue',
    '--brand-contrast',
  ].forEach(variable => {
    element.style.removeProperty(variable);
  });
};

const syncTheme = (brandColor, lightScale, darkScale) => {
  const root = document.documentElement;
  const body = document.body;
  const rootHasDark = root?.classList.contains('dark');
  const bodyHasDark = body?.classList.contains('dark');

  if (root) {
    const rootScale = rootHasDark ? darkScale : lightScale;
    const rootMapping = rootHasDark ? DERIVED_DARK : DERIVED_LIGHT;
    applyThemeVars(root, rootScale, brandColor, rootMapping);
  }

  if (!body) {
    return;
  }
  if (!bodyHasDark) {
    clearScale(body);
    clearDerivedVars(body);
  }
  if (bodyHasDark) {
    applyThemeVars(body, darkScale, brandColor, DERIVED_DARK);
  }

  const darkNodes = document.querySelectorAll('.dark');
  darkNodes.forEach(node => {
    if (node === root || node === body) {
      return;
    }
    applyThemeVars(node, darkScale, brandColor, DERIVED_DARK);
  });
};

export const initializeBrandColors = brandColorValue => {
  const brandColor = normalizeColor(brandColorValue);
  if (!brandColor) {
    return;
  }
  const lightScale = buildScale(brandColor, LIGHTNESS_SCALE_LIGHT);
  const darkScale = buildScale(brandColor, LIGHTNESS_SCALE_DARK);
  syncTheme(brandColor, lightScale, darkScale);
  const observeElement = element => {
    if (!element) {
      return;
    }
    const observer = new MutationObserver(() =>
      syncTheme(brandColor, lightScale, darkScale)
    );
    observer.observe(element, {
      attributes: true,
      attributeFilter: ['class'],
    });
  };

  if (!document.body) {
    window.addEventListener('DOMContentLoaded', () => {
      syncTheme(brandColor, lightScale, darkScale);
      observeElement(document.documentElement);
      observeElement(document.body);
    });
    return;
  }

  observeElement(document.documentElement);
  observeElement(document.body);
};
