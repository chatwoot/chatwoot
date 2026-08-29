// Prefix that turns a stored icon name (e.g. "rocket-line") into a class.
// Swapping icon libraries means changing this and the curated set only.
export const ICON_PREFIX = 'i-ri-';

export const ICON_STYLE = {
  LINE: 'line',
  FILL: 'fill',
};

// Icon values are ascii names (e.g. "rocket-line"); emoji are non-ascii.
export const isIconValue = value =>
  typeof value === 'string' && /^[a-z][a-z0-9-]*$/.test(value);

export const iconClassFor = value =>
  value.startsWith(ICON_PREFIX) ? value : `${ICON_PREFIX}${value}`;

export const ICON_COLORS = [
  { name: 'SLATE', value: '#64748B' },
  { name: 'RED', value: '#EF4444' },
  { name: 'ORANGE', value: '#F97316' },
  { name: 'AMBER', value: '#F59E0B' },
  { name: 'GREEN', value: '#22C55E' },
  { name: 'TEAL', value: '#14B8A6' },
  { name: 'BLUE', value: '#3B82F6' },
  { name: 'INDIGO', value: '#6366F1' },
  { name: 'VIOLET', value: '#8B5CF6' },
  { name: 'PINK', value: '#EC4899' },
];

export const DEFAULT_ICON_COLOR = '#3B82F6';

export const PICKER_MODE = {
  BOTH: 'both',
  EMOJI: 'emoji',
};

export const PICKER_TAB = {
  ICONS: 'icons',
  EMOJIS: 'emojis',
};
