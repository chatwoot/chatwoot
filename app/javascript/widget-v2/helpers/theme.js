const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');

const HEX_PATTERN = /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i;
const SIZE_PATTERN = /^\d+(\.\d+)?(px|rem|em)$/;

// White text on light brand colors is illegible; pick the foreground by
// relative luminance of the brand color.
const foregroundFor = hex => {
  let value = hex.slice(1);
  if (value.length === 3) {
    value = value.replace(/./g, char => char + char);
  }
  const [r, g, b] = [0, 2, 4].map(i => parseInt(value.slice(i, i + 2), 16));
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance > 0.65 ? '#131316' : '#ffffff';
};

// Brand fonts must be loaded inside the iframe to render; the host page's
// webfonts do not cross the frame boundary.
const loadFontStylesheet = url => {
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:') return;
  } catch {
    return;
  }
  if (document.querySelector(`link[href="${url}"]`)) return;

  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = url;
  document.head.appendChild(link);
};

// Allowlisted brand tokens; anything else in the theme object is ignored.
// Order of precedence: defaults in widget-v2.scss → inbox widget_color → host theme.
export const applyTheme = (theme = {}) => {
  const root = document.documentElement;

  if (HEX_PATTERN.test(theme.primary || '')) {
    root.style.setProperty('--cw-primary', theme.primary);
    root.style.setProperty(
      '--cw-primary-foreground',
      foregroundFor(theme.primary)
    );
  }
  if (SIZE_PATTERN.test(theme.radius || '')) {
    root.style.setProperty('--cw-radius', theme.radius);
  }
  if (theme.fontUrl) loadFontStylesheet(theme.fontUrl);
  if (typeof theme.font === 'string' && theme.font.length < 200) {
    root.style.setProperty(
      '--cw-font-sans',
      `${theme.font}, Inter, -apple-system, system-ui, sans-serif`
    );
  }
};

export const applyDarkMode = mode => {
  const root = document.documentElement;
  const isDark = mode === 'dark' || (mode === 'auto' && darkModeQuery.matches);
  root.classList.toggle('dark', isDark);
};

export const watchSystemDarkMode = getMode => {
  darkModeQuery.addEventListener('change', () => applyDarkMode(getMode()));
};
