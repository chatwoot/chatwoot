/**
 * Shared lookup tables and helper functions used by the parser,
 * suggestions, and localization modules.
 */

import {
  add,
  set,
  isValid,
  isAfter,
  nextMonday,
  nextTuesday,
  nextWednesday,
  nextThursday,
  nextFriday,
  nextSaturday,
  nextSunday,
} from 'date-fns';

// ─── Token Maps ──────────────────────────────────────────────────────────────
// All keys are lowercase. Short forms and full names both work.

/** Weekday name or short form → day index (0 = Sunday). */
export const WEEKDAY_MAP = {
  sunday: 0,
  sun: 0,
  monday: 1,
  mon: 1,
  tuesday: 2,
  tue: 2,
  tues: 2,
  wednesday: 3,
  wed: 3,
  thursday: 4,
  thu: 4,
  thur: 4,
  thurs: 4,
  friday: 5,
  fri: 5,
  saturday: 6,
  sat: 6,
};

/** Month name or short form → month index (0 = January). */
export const MONTH_MAP = {
  january: 0,
  jan: 0,
  february: 1,
  feb: 1,
  march: 2,
  mar: 2,
  april: 3,
  apr: 3,
  may: 4,
  june: 5,
  jun: 5,
  july: 6,
  jul: 6,
  august: 7,
  aug: 7,
  september: 8,
  sep: 8,
  sept: 8,
  october: 9,
  oct: 9,
  november: 10,
  nov: 10,
  december: 11,
  dec: 11,
};

/** Words like "today" or "tomorrow" → how many days from now. */
export const RELATIVE_DAY_MAP = {
  today: 0,
  tonight: 0,
  tonite: 0,
  tomorrow: 1,
  tmr: 1,
  tmrw: 1,
};

/** Unit shorthand → full unit name used by date-fns. */
export const UNIT_MAP = {
  m: 'minutes',
  min: 'minutes',
  mins: 'minutes',
  minute: 'minutes',
  minutes: 'minutes',
  h: 'hours',
  hr: 'hours',
  hrs: 'hours',
  hour: 'hours',
  hours: 'hours',
  d: 'days',
  day: 'days',
  days: 'days',
  w: 'weeks',
  wk: 'weeks',
  wks: 'weeks',
  week: 'weeks',
  weeks: 'weeks',
  mo: 'months',
  month: 'months',
  months: 'months',
  y: 'years',
  yr: 'years',
  yrs: 'years',
  year: 'years',
  years: 'years',
};

/** English number words → their numeric value. */
export const WORD_NUMBER_MAP = {
  a: 1,
  an: 1,
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
  six: 6,
  seven: 7,
  eight: 8,
  nine: 9,
  ten: 10,
  eleven: 11,
  twelve: 12,
  thirteen: 13,
  fourteen: 14,
  fifteen: 15,
  sixteen: 16,
  seventeen: 17,
  eighteen: 18,
  nineteen: 19,
  twenty: 20,
  thirty: 30,
  forty: 40,
  fifty: 50,
  sixty: 60,
  ninety: 90,
  half: 0.5,
  couple: 2,
  few: 3,
};

/** Day index → the date-fns function that finds the next occurrence. */
export const NEXT_WEEKDAY_FN = {
  0: nextSunday,
  1: nextMonday,
  2: nextTuesday,
  3: nextWednesday,
  4: nextThursday,
  5: nextFriday,
  6: nextSaturday,
};

/** Time-of-day label → default hour and minute. */
export const TIME_OF_DAY_MAP = {
  morning: { hours: 9, minutes: 0 },
  noon: { hours: 12, minutes: 0 },
  afternoon: { hours: 14, minutes: 0 },
  evening: { hours: 18, minutes: 0 },
  night: { hours: 20, minutes: 0 },
  tonight: { hours: 20, minutes: 0 },
  midnight: { hours: 0, minutes: 0 },
  eod: { hours: 17, minutes: 0 },
  'end of day': { hours: 17, minutes: 0 },
  'end of the day': { hours: 17, minutes: 0 },
};

/** Allowed hour range per label — used to pick am or pm when not specified. */
export const TOD_HOUR_RANGE = {
  morning: [4, 12],
  noon: [11, 13],
  afternoon: [12, 18],
  evening: [16, 22],
  night: [18, 24],
  tonight: [18, 24],
  midnight: [23, 25],
};

/** What "half hour", "half day", etc. actually mean in date-fns terms. */
export const HALF_UNIT_DURATIONS = {
  hour: { minutes: 30 },
  day: { hours: 12 },
  week: { days: 3, hours: 12 },
  month: { days: 15 },
  year: { months: 6 },
};

const FRACTIONAL_CONVERT = {
  hours: { unit: 'minutes', factor: 60 },
  days: { unit: 'hours', factor: 24 },
  weeks: { unit: 'days', factor: 7 },
  months: { unit: 'days', factor: 30 },
  years: { unit: 'months', factor: 12 },
};

// ─── Unicode / Normalization ────────────────────────────────────────────────
// Turn non-ASCII digits and punctuation into plain ASCII so the
// parser only has to deal with standard characters.

const UNICODE_DIGIT_RANGES = [
  [0x30, 0x39],
  [0x660, 0x669], // Arabic-Indic
  [0x6f0, 0x6f9], // Eastern Arabic-Indic
  [0x966, 0x96f], // Devanagari
  [0x9e6, 0x9ef], // Bengali
  [0xa66, 0xa6f], // Gurmukhi
  [0xae6, 0xaef], // Gujarati
  [0xb66, 0xb6f], // Oriya
  [0xbe6, 0xbef], // Tamil
  [0xc66, 0xc6f], // Telugu
  [0xce6, 0xcef], // Kannada
  [0xd66, 0xd6f], // Malayalam
];

const toAsciiDigit = char => {
  const code = char.codePointAt(0);
  const range = UNICODE_DIGIT_RANGES.find(
    ([start, end]) => code >= start && code <= end
  );
  if (!range) return char;
  return String(code - range[0]);
};

/** Turn non-ASCII digits (Arabic, Devanagari, etc.) into 0-9. */
export const normalizeDigits = text => text.replace(/\p{Nd}/gu, toAsciiDigit);

const ARABIC_PUNCT_MAP = {
  '\u061f': '?',
  '\u060c': ',',
  '\u061b': ';',
  '\u066b': '.',
};

const NOISE_RE =
  /^(?:(?:can|could|will|would)\s+you\s+)?(?:(?:please|pls|plz|kindly)\s+)?(?:(?:snooze|remind(?:\s+me)?|set(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze|timer))?|add(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze))?|schedule|postpone|defer|delay|push)(?:\s+(?:it|this))?\s+)?(?:(?:on|to|for|at|until|till|by|from)\s+)?/;

const APPROX_RE = /^(?:approx(?:imately)?|around|about|roughly|~)\s+/;

/** Clean up raw input: lowercase, remove punctuation, collapse spaces. */
export const sanitize = text =>
  normalizeDigits(
    text
      .normalize('NFKC')
      .toLowerCase()
      .replace(/[\u200f\u200e\u066c\u0640]/g, '')
      .replace(/[\u064b-\u065f]/g, '')
      .replace(/\u00a0/g, ' ')
      .replace(/[\u061f\u060c\u061b\u066b]/g, c => ARABIC_PUNCT_MAP[c])
  )
    .replace(/[,!?;]+/g, ' ')
    .replace(/\.+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

/** Strip filler words like "please snooze for" and fix typos like "tommorow". */
export const stripNoise = text =>
  text
    .replace(NOISE_RE, '')
    .replace(APPROX_RE, '')
    .replace(/\bnxt\b/g, 'next')
    .replace(/\bcouple\s+of\b/g, 'couple')
    .replace(/\b(\d+)h(\d+)m?\b/g, '$1 hours $2 minutes')
    .replace(/\btomm?orow\b/g, 'tomorrow')
    .trim();

// ─── Utility Functions ──────────────────────────────────────────────────────

/** Turn a string into a number. Works with digits ("5") and words ("five"). */
export const parseNumber = str => {
  if (!str) return null;
  const lower = normalizeDigits(str.toLowerCase().trim());
  if (WORD_NUMBER_MAP[lower] !== undefined) return WORD_NUMBER_MAP[lower];
  const num = Number(lower);
  return Number.isNaN(num) ? null : num;
};

/** Set the time on a date, clearing seconds and milliseconds. */
export const applyTimeToDate = (date, hours, minutes = 0) =>
  set(date, { hours, minutes, seconds: 0, milliseconds: 0 });

/** Parse "3pm", "14:30", or "2:00am" into { hours, minutes }. Returns null if invalid. */
export const parseTimeString = timeStr => {
  if (!timeStr) return null;
  const match = timeStr
    .toLowerCase()
    .replace(/\s+/g, '')
    .match(/^(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.?|p\.m\.?)?$/);
  if (!match) return null;

  const raw = parseInt(match[1], 10);
  const minutes = match[2] ? parseInt(match[2], 10) : 0;
  const meridiem = match[3]?.replace(/\./g, '');
  if (meridiem && (raw < 1 || raw > 12)) return null;

  const toHours = (h, m) => {
    if (m === 'pm' && h < 12) return h + 12;
    if (m === 'am' && h === 12) return 0;
    return h;
  };
  const hours = toHours(raw, meridiem);
  if (hours > 23 || minutes > 59) return null;
  return { hours, minutes };
};

/** Apply a time string to a date. Falls back to 9 AM if no time is given. */
export const applyTimeOrDefault = (date, timeStr, defaultHours = 9) => {
  if (timeStr) {
    const time = parseTimeString(timeStr);
    if (!time) return null;
    return applyTimeToDate(date, time.hours, time.minutes);
  }
  return applyTimeToDate(date, defaultHours, 0);
};

/** Build a Date only if the day actually exists (e.g. rejects Feb 30). */
export const strictDate = (year, month, day) => {
  const date = new Date(year, month, day);
  if (
    !isValid(date) ||
    date.getFullYear() !== year ||
    date.getMonth() !== month ||
    date.getDate() !== day
  )
    return null;
  return date;
};

/** Try up to 8 years ahead to find a valid future date (handles Feb 29 leap years). */
export const futureOrNextYear = (year, month, day, timeStr, now) => {
  for (let i = 0; i < 9; i += 1) {
    const base = strictDate(year + i, month, day);
    if (base) {
      const date = applyTimeOrDefault(base, timeStr);
      if (!date) return null;
      if (isAfter(date, now)) return date;
    }
  }
  return null;
};

/** If the date is already past, push it to the next day. */
export const ensureFutureOrNextDay = (date, now) =>
  isAfter(date, now) ? date : add(date, { days: 1 });

/** Figure out am/pm from context: "morning 6" → 6am, "evening 6" → 6pm. */
export const inferHoursFromTOD = (todLabel, rawHour, rawMinutes) => {
  const h = parseInt(rawHour, 10);
  const m = rawMinutes ? parseInt(rawMinutes, 10) : 0;
  if (Number.isNaN(h) || h < 1 || h > 12 || m > 59) return null;
  const range = TOD_HOUR_RANGE[todLabel];
  if (!range) return { hours: h, minutes: m };
  // Try both am and pm interpretations, pick the one in range
  const am = h === 12 ? 0 : h;
  const pm = h === 12 ? 12 : h + 12;
  const inRange = v => v >= range[0] && v < range[1];
  if (inRange(am)) return { hours: am, minutes: m };
  if (inRange(pm)) return { hours: pm, minutes: m };
  const mid = (range[0] + range[1]) / 2;
  return {
    hours: Math.abs(am - mid) <= Math.abs(pm - mid) ? am : pm,
    minutes: m,
  };
};

/** Add a duration that might be fractional, e.g. 1.5 hours becomes 90 minutes. */
export const addFractionalSafe = (date, unit, amount) => {
  if (Number.isInteger(amount)) return add(date, { [unit]: amount });
  if (amount % 1 !== 0.5) return null;
  const conv = FRACTIONAL_CONVERT[unit];
  if (conv) return add(date, { [conv.unit]: Math.round(amount * conv.factor) });
  return add(date, { [unit]: Math.round(amount) });
};
