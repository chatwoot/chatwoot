export const DURATION_UNITS = {
  MINUTES: 'minutes',
  HOURS: 'hours',
  DAYS: 'days',
};

export const MINUTES_PER_UNIT = {
  [DURATION_UNITS.MINUTES]: 1,
  [DURATION_UNITS.HOURS]: 60,
  [DURATION_UNITS.DAYS]: 24 * 60,
};
