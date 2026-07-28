// The widget ships `standard` — whose values are the defaults declared in
// widget-v2.scss, which is why it is empty here — plus brand themes.
//
// Brands customise the widget by passing tokens rather than picking a preset:
//
//   theme: { primary: '#0F766E', radius: '4px', fontSizeRoot: '15px' }
//
// Anything registered in THEMES becomes selectable as `theme: '<name>'`.
// See ./README.md for the token reference.

const standard = {};

// Context (context.dev) — a developer/AI infrastructure API. Azul on a cool
// near-white ground, near-black ink, tighter radius to read as a dev tool.
const context = {
  background: '#F6F8FD',
  border: '#DCE4F6',
  bubbleAgentBg: '#EDF2FD',
  fontSizeRoot: '15px',
  hairline: 'rgba(4, 4, 4, 0.06)',
  muted: '#EDF2FD',
  primary: '#2464EC',
  radius: '8px',
  shadowCard: '0 1px 2px rgba(4, 4, 4, 0.05)',
  solid: '#FFFFFF',
  surface: '#EFF3FC',
  text: '#040404',
  textFaint: '#8CA0C4',
  textMuted: '#4A5568',
};

// Spotify — dark ground, Limonana green accent, generous rounding and no
// borders, matching the app's surface language.
const spotify = {
  avatarRadius: '9999px',
  background: '#050906',
  border: '#2A2A2A',
  bubbleAgentBg: '#232323',
  bubbleAgentText: '#FFFFFF',
  bubbleRadius: '16px',
  bubbleTailRadius: '16px',
  // The palette is dark by design, so it stays dark on a light host page.
  colorScheme: 'dark',
  hairline: 'rgba(255, 255, 255, 0.08)',
  muted: '#232323',
  primary: '#1CD463',
  primaryForeground: '#050906',
  radius: '16px',
  shadowCard: 'none',
  solid: '#121212',
  surface: '#1A1A1A',
  text: '#FFFFFF',
  textFaint: '#6A6A6A',
  textMuted: '#B3B3B3',
};

export const THEMES = { standard, context, spotify };

export const THEME_NAMES = Object.keys(THEMES);

export const getTheme = name => THEMES[name] || THEMES.standard;
