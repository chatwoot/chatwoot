// Themes are named token bundles. `standard` is the default and ships empty
// because its values are the defaults declared in widget-v2.scss; every other
// theme is expressed purely as overrides of those tokens.
//
// See ./README.md for the full token reference and how to author a theme.

const standard = {};

// Translucent chrome that picks up the host page behind the iframe.
// `material` is the only non-token key a theme may set.
const frosted = {
  material: 'frosted',
};

// Blocky arcade look: zero radius, thick black borders, hard offset shadows,
// square avatars, a pixel typeface, dense scale and no motion.
const tetris = {
  avatarRadius: '0px',
  border: '#111111',
  borderWidth: '3px',
  bubbleAgentBg: '#F2F2F2',
  bubbleAgentText: '#111111',
  bubbleRadius: '0px',
  bubbleTailRadius: '0px',
  canvasImage:
    'repeating-linear-gradient(0deg, rgba(17,17,17,0.06) 0 1px, transparent 1px 24px), repeating-linear-gradient(90deg, rgba(17,17,17,0.06) 0 1px, transparent 1px 24px)',
  cardGap: '0.75rem',
  font: '"Press Start 2P"',
  fontSizeRoot: '13px',
  fontUrl:
    'https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap',
  fontWeightStrong: '400',
  headerHeight: '3.5rem',
  iconSize: '1rem',
  primary: '#00B8B8',
  primaryForeground: '#000000',
  radius: '0px',
  ringWidth: '2px',
  rowPaddingY: '0.75rem',
  shadowCard: '4px 4px 0 #111111',
  tabHeight: '2.75rem',
  trackingDisplay: '0em',
  transitionDuration: '0ms',
};

// Restrained publishing look: generous radius, hairline borders, no shadows,
// larger airier type, serif display, sentence-case labels.
const editorial = {
  background: '#FAF8F4',
  border: '#E6E1D8',
  bubbleAgentBg: '#F0EBE1',
  bubbleAgentText: '#1A1A1A',
  bubbleRadius: '20px',
  bubbleTailRadius: '20px',
  cardGap: '1.25rem',
  font: 'Georgia, "Times New Roman"',
  fontSizeRoot: '17px',
  fontWeightStrong: '600',
  headerHeight: '4.5rem',
  overlineTransform: 'none',
  primary: '#1A1A1A',
  radius: '20px',
  rowPaddingY: '1.25rem',
  shadowCard: 'none',
  solid: '#FFFDF9',
  surface: '#F4F1EA',
  trackingDisplay: '-0.01em',
};

export const THEMES = { standard, frosted, tetris, editorial };

export const THEME_NAMES = Object.keys(THEMES);

export const getTheme = name => THEMES[name] || THEMES.standard;
