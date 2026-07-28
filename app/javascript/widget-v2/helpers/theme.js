import { getTheme } from 'widget-v2/themes';

const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');

const HEX_PATTERN = /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i;

// Every token a styling kit (or a host) may set, mapped to its CSS variable.
const TOKEN_VARS = {
  avatarRadius: '--cw-avatar-radius',
  background: '--cw-background',
  border: '--cw-border',
  borderWidth: '--cw-border-width',
  bubbleAgentBg: '--cw-bubble-agent-bg',
  bubbleAgentText: '--cw-bubble-agent-text',
  bubbleRadius: '--cw-bubble-radius',
  bubbleTailRadius: '--cw-bubble-tail-radius',
  bubbleVisitorBg: '--cw-bubble-visitor-bg',
  bubbleVisitorText: '--cw-bubble-visitor-text',
  buttonRadius: '--cw-button-radius',
  canvasImage: '--cw-canvas-image',
  cardGap: '--cw-card-gap',
  fontSizeRoot: '--cw-font-size-root',
  hairline: '--cw-hairline',
  headerHeight: '--cw-header-height',
  iconSize: '--cw-icon-size',
  fontWeightStrong: '--cw-font-weight-strong',
  muted: '--cw-muted',
  overlineTransform: '--cw-overline-transform',
  primary: '--cw-primary',
  primaryForeground: '--cw-primary-foreground',
  radius: '--cw-radius',
  ringWidth: '--cw-ring-width',
  rowPaddingX: '--cw-row-padding-x',
  rowPaddingY: '--cw-row-padding-y',
  shadowCard: '--cw-shadow-card',
  solid: '--cw-solid',
  surface: '--cw-surface',
  tabHeight: '--cw-tab-height',
  text: '--cw-text',
  textFaint: '--cw-text-faint',
  textMuted: '--cw-text-muted',
  trackingDisplay: '--cw-tracking-display',
  transitionDuration: '--cw-transition-duration',
};

// Values land in CSS custom properties, so reject anything that could close a
// declaration or pull in remote resources.
const isSafeValue = value =>
  typeof value === 'string' &&
  value.length < 500 &&
  !/[;{}]|@import|javascript:|expression\(/i.test(value) &&
  !/url\(/i.test(value);

// White text on a light brand colour is illegible; pick the foreground by
// relative luminance of the brand colour.
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

// A theme is either a name ('tetris') or an object ({ name, ...overrides }).
// Precedence: scss defaults → inbox accent → named theme → explicit overrides.
// The inbox accent is the weakest so a theme's own palette isn't overwritten
// by the colour configured in the dashboard.
export const applyTheme = (theme = {}, { defaultPrimary } = {}) => {
  const root = document.documentElement;
  const config = typeof theme === 'string' ? { name: theme } : theme || {};
  const named = getTheme(config.name);
  const resolved = {
    ...(defaultPrimary && !named.primary ? { primary: defaultPrimary } : {}),
    ...named,
    ...config,
  };

  root.classList.toggle('frosted', resolved.material === 'frosted');

  // Themes replace rather than accumulate: clear anything a previous theme set
  // so its tokens can't leak into the next one.
  Object.values(TOKEN_VARS).forEach(cssVar =>
    root.style.removeProperty(cssVar)
  );
  root.style.removeProperty('--cw-font-sans');

  Object.entries(TOKEN_VARS).forEach(([token, cssVar]) => {
    const value = resolved[token];
    // An empty value means "unset", leaving the default in place.
    if (value === undefined || value === '' || !isSafeValue(String(value))) {
      return;
    }
    root.style.setProperty(cssVar, value);
  });

  if (HEX_PATTERN.test(resolved.primary || '') && !resolved.primaryForeground) {
    root.style.setProperty(
      '--cw-primary-foreground',
      foregroundFor(resolved.primary)
    );
  }

  if (resolved.fontUrl) loadFontStylesheet(resolved.fontUrl);
  if (isSafeValue(resolved.font || '')) {
    root.style.setProperty(
      '--cw-font-sans',
      `${resolved.font}, Inter, -apple-system, system-ui, sans-serif`
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
