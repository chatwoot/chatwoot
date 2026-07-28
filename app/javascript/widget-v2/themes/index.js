// Styling kits: named bundles of design tokens. A kit sets any key in
// TOKEN_VARS (see helpers/theme.js); explicit host tokens win over the kit, so
// a customer can adopt a kit and still override its accent colour.
//
// fontSizeRoot is the strongest lever: Tailwind's type and spacing are
// rem-based, so it rescales the entire interface — density and size at once.

// Blocky arcade look: zero radius, thick black borders, hard offset shadows,
// square avatars, a pixel typeface and a faint playfield grid.
const tetris = {
  primary: '#00B8B8',
  primaryForeground: '#000000',
  radius: '0px',
  borderWidth: '3px',
  border: '#111111',
  bubbleRadius: '0px',
  bubbleTailRadius: '0px',
  avatarRadius: '0px',
  shadowCard: '4px 4px 0 #111111',
  font: '"Press Start 2P"',
  fontUrl:
    'https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap',
  fontSizeRoot: '13px',
  fontWeightStrong: '400',
  trackingDisplay: '0em',
  transitionDuration: '0ms',
  bubbleAgentBg: '#F2F2F2',
  bubbleAgentText: '#111111',
  headerHeight: '3.5rem',
  tabHeight: '2.75rem',
  rowPaddingY: '0.75rem',
  cardGap: '0.75rem',
  iconSize: '1rem',
  ringWidth: '2px',
  canvasImage:
    'repeating-linear-gradient(0deg, rgba(17,17,17,0.06) 0 1px, transparent 1px 24px), repeating-linear-gradient(90deg, rgba(17,17,17,0.06) 0 1px, transparent 1px 24px)',
};

// Restrained publishing look: generous radius, hairline borders, no shadows,
// larger and airier type, serif display, sentence-case labels.
const editorial = {
  primary: '#1A1A1A',
  radius: '20px',
  borderWidth: '1px',
  border: '#E6E1D8',
  bubbleRadius: '20px',
  bubbleTailRadius: '20px',
  shadowCard: 'none',
  background: '#FAF8F4',
  surface: '#F4F1EA',
  solid: '#FFFDF9',
  font: 'Georgia, "Times New Roman"',
  fontSizeRoot: '17px',
  fontWeightStrong: '600',
  trackingDisplay: '-0.01em',
  overlineTransform: 'none',
  bubbleAgentBg: '#F0EBE1',
  bubbleAgentText: '#1A1A1A',
  headerHeight: '4.5rem',
  rowPaddingY: '1.25rem',
  cardGap: '1.25rem',
};

export const THEME_PRESETS = { tetris, editorial };

export const getPreset = name => THEME_PRESETS[name] || null;
