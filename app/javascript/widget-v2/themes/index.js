// The widget ships one theme — `standard` — whose values are the defaults
// declared in widget-v2.scss, which is why it is empty here.
//
// Brands customise the widget by passing tokens rather than picking a preset:
//
//   theme: { primary: '#0F766E', radius: '4px', fontSizeRoot: '15px' }
//
// Named bundles can be registered here later; anything added to THEMES becomes
// selectable as `theme: '<name>'`. See ./README.md for the token reference.

const standard = {};

export const THEMES = { standard };

export const THEME_NAMES = Object.keys(THEMES);

export const getTheme = name => THEMES[name] || THEMES.standard;
