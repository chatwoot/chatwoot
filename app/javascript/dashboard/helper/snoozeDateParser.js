/**
 * snoozeDateParser — Natural language date/time parser for snooze.
 *
 * Converts free-form English text into a future Date object.
 * Handles relative durations ("in 2 hours", "half day"), named days
 * ("tomorrow at 3pm", "next friday"), absolute dates ("jan 15", "2025-01-15"),
 * time-of-day phrases ("morning", "eod"), and various noise/prefix stripping.
 *
 * All results are guaranteed to be strictly in the future relative to the
 * reference date, with a 999-year maximum cap.
 */

import {
  add,
  set,
  startOfDay,
  getDay,
  isSaturday,
  isSunday,
  nextMonday,
  nextTuesday,
  nextWednesday,
  nextThursday,
  nextFriday,
  nextSaturday,
  nextSunday,
  getUnixTime,
  isValid,
  startOfWeek,
  addWeeks,
  isBefore,
  isAfter,
  endOfMonth,
} from 'date-fns';

// ─── Token Maps ──────────────────────────────────────────────────────────────

const WEEKDAY_MAP = {
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

const MONTH_MAP = {
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

const RELATIVE_DAY_MAP = {
  today: 0,
  tonight: 0,
  tonite: 0,
  tomorrow: 1,
  tmr: 1,
  tmrw: 1,
};

const UNIT_MAP = {
  s: 'seconds',
  sec: 'seconds',
  secs: 'seconds',
  second: 'seconds',
  seconds: 'seconds',
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

const WORD_NUMBER_MAP = {
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

const NEXT_WEEKDAY_FN = {
  0: nextSunday,
  1: nextMonday,
  2: nextTuesday,
  3: nextWednesday,
  4: nextThursday,
  5: nextFriday,
  6: nextSaturday,
};

const TIME_OF_DAY_MAP = {
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

const TOD_HOUR_RANGE = {
  morning: [4, 12],
  noon: [11, 13],
  afternoon: [12, 18],
  evening: [16, 22],
  night: [18, 24],
  tonight: [18, 24],
  midnight: [23, 25],
};

// ─── Generated Regex Fragments (from maps, not hand-duplicated) ──────────────

const WEEKDAY_NAMES = Object.keys(WEEKDAY_MAP).join('|');
const MONTH_NAMES = Object.keys(MONTH_MAP).join('|');
const UNIT_NAMES = Object.keys(UNIT_MAP).join('|');
const WORD_NUMBERS = Object.keys(WORD_NUMBER_MAP).join('|');
const RELATIVE_DAYS = Object.keys(RELATIVE_DAY_MAP).join('|');
const TIME_OF_DAY_NAMES = 'morning|afternoon|evening|night|noon|midnight';

const NUM_RE = `(\\d+(?:\\.5)?|${WORD_NUMBERS})`;
const UNIT_RE = `(${UNIT_NAMES})`;
const TIME_SUFFIX_RE =
  '(?:\\s+(?:at\\s+)?(\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.?|p\\.m\\.?)?|\\d{1,2}:\\d{2}))?';

// ─── Pre-compiled Regexes (avoid re-compilation on every parse call) ─────────

const HALF_UNIT_RE = /^(?:in\s+)?half\s+(?:an?\s+)?(hour|day|week|month|year)$/;
const RELATIVE_DURATION_RE = new RegExp(`^(?:in\\s+)?${NUM_RE}\\s+${UNIT_RE}$`);
const DURATION_FROM_NOW_RE = new RegExp(
  `^${NUM_RE}\\s+${UNIT_RE}\\s+from\\s+now$`
);
const RELATIVE_DAY_ONLY_RE = new RegExp(`^(${RELATIVE_DAYS})$`);
const RELATIVE_DAY_TOD_RE = new RegExp(
  `^(${RELATIVE_DAYS})\\s+(?:at\\s+)?(${TIME_OF_DAY_NAMES})$`
);
const RELATIVE_DAY_TOD_TIME_RE = new RegExp(
  `^(${RELATIVE_DAYS})\\s+(?:at\\s+)?(${TIME_OF_DAY_NAMES})\\s+(\\d{1,2}(?::\\d{2})?)$`
);
const RELATIVE_DAY_AT_TIME_RE = new RegExp(
  `^(${RELATIVE_DAYS})\\s+(?:at\\s+)?` +
    '(\\d{1,2}(?::\\d{2})?\\s*' +
    '(?:am|pm|a\\.m\\.?|p\\.m\\.?)?|\\d{1,2}:\\d{2})$'
);
const RELATIVE_DAY_SAME_TIME_RE = new RegExp(
  `^(${RELATIVE_DAYS})\\s+(?:same\\s+time|this\\s+time)$`
);
const NEXT_UNIT_RE = new RegExp(
  `^next\\s+(hour|minute|week|month|year)${TIME_SUFFIX_RE}$`
);
const NEXT_MONTH_RE = new RegExp(`^next\\s+(${MONTH_NAMES})${TIME_SUFFIX_RE}$`);
const NEXT_WEEKDAY_TOD_RE = new RegExp(
  `^next\\s+(${WEEKDAY_NAMES})\\s+(${TIME_OF_DAY_NAMES})$`
);
const NEXT_WEEKDAY_RE = new RegExp(
  `^(?:(${WEEKDAY_NAMES})\\s+(?:of\\s+)?next\\s+week` +
    `|next\\s+week\\s+(${WEEKDAY_NAMES})` +
    `|next\\s+(${WEEKDAY_NAMES}))${TIME_SUFFIX_RE}$`
);
const SAME_TIME_WEEKDAY_RE = new RegExp(
  `^(?:same\\s+time|this\\s+time)\\s+(${WEEKDAY_NAMES})$`
);
const WEEKDAY_TOD_RE = new RegExp(
  `^(?:(?:this|upcoming|coming)\\s+)?` +
    `(${WEEKDAY_NAMES})\\s+(${TIME_OF_DAY_NAMES})$`
);
const WEEKDAY_TOD_TIME_RE = new RegExp(
  `^(?:(?:this|upcoming|coming)\\s+)?` +
    `(${WEEKDAY_NAMES})\\s+(${TIME_OF_DAY_NAMES})\\s+(\\d{1,2}(?::\\d{2})?)$`
);
const WEEKDAY_TIME_RE = new RegExp(
  `^(?:(?:this|upcoming|coming)\\s+)?(${WEEKDAY_NAMES})${TIME_SUFFIX_RE}$`
);
const TIME_ONLY_MERIDIEM_RE =
  /^(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.?|p\.m\.?))$/;
const TIME_ONLY_24H_RE = /^(?:at\s+)?(\d{1,2}:\d{2})$/;
const TOD_WITH_TIME_RE = new RegExp(
  `^(?:(?:this|the)\\s+)?(${TIME_OF_DAY_NAMES})\\s+` +
    '(?:at\\s+)?(\\d{1,2}(?::\\d{2})?\\s*' +
    '(?:am|pm|a\\.m\\.?|p\\.m\\.?)?)$'
);
const TOD_PLAIN_RE = new RegExp(
  '(?:(?:later|in)\\s+)?(?:(?:this|the)\\s+)?' +
    `(?:${TIME_OF_DAY_NAMES}|eod|end of day|end of the day)$`
);
const ABSOLUTE_DATE_RE = new RegExp(
  `^(${MONTH_NAMES})\\s+(\\d{1,2})(?:st|nd|rd|th)?` +
    `(?:[,\\s]+(\\d{4}|next\\s+year))?${TIME_SUFFIX_RE}$`
);
const ABSOLUTE_DATE_REVERSED_RE = new RegExp(
  `^(\\d{1,2})(?:st|nd|rd|th)?\\s+(${MONTH_NAMES})` +
    `(?:[,\\s]+(\\d{4}|next\\s+year))?${TIME_SUFFIX_RE}$`
);
const MONTH_YEAR_RE = new RegExp(`^(${MONTH_NAMES})\\s+(\\d{4})$`);
const DAY_AFTER_TOMORROW_RE = new RegExp(
  `^day\\s+after\\s+tomorrow${TIME_SUFFIX_RE}$`
);

const COMPOUND_DURATION_RE = new RegExp(
  `^(?:in\\s+)?${NUM_RE}\\s+${UNIT_RE}\\s+(?:and\\s+)?${NUM_RE}\\s+${UNIT_RE}$`
);
const DURATION_AT_TIME_RE = new RegExp(
  `^(?:in\\s+)?${NUM_RE}\\s+${UNIT_RE}\\s+at\\s+` +
    '(\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.?|p\\.m\\.?)?)$'
);
const END_OF_RE = /^end\s+of\s+(?:the\s+)?(week|month|day)$/;
const LATER_TODAY_RE = /^later\s+(?:today|this\s+(?:afternoon|evening))$/;

const TIME_SUFFIX_COMPILED = new RegExp(`${TIME_SUFFIX_RE}$`);
const ISO_DATE_RE = new RegExp(
  `^(\\d{4})-(\\d{1,2})-(\\d{1,2})${TIME_SUFFIX_COMPILED.source}`
);
const SLASH_DATE_RE = new RegExp(
  `^(\\d{1,2})/(\\d{1,2})/(\\d{4})${TIME_SUFFIX_COMPILED.source}`
);
const DASH_DATE_RE = new RegExp(
  `^(\\d{1,2})-(\\d{1,2})-(\\d{4})${TIME_SUFFIX_COMPILED.source}`
);
const DOT_DATE_RE = new RegExp(
  `^(\\d{1,2})\\.(\\d{1,2})\\.(\\d{4})${TIME_SUFFIX_COMPILED.source}`
);
const AMBIGUOUS_DATE_RES = [SLASH_DATE_RE, DASH_DATE_RE, DOT_DATE_RE];

const MONTH_NAME_RE = new RegExp(`\\b(?:${MONTH_NAMES})\\b`, 'i');
const NUM_TOD_RE =
  /\b(\d{1,2}(?::\d{2})?)\s+(morning|noon|afternoon|evening|night)\b/g;
const TOD_TO_MERIDIEM = {
  morning: 'am',
  noon: 'pm',
  afternoon: 'pm',
  evening: 'pm',
  night: 'pm',
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

const NOISE_RE =
  /^(?:(?:can|could|will|would)\s+you\s+)?(?:(?:please|pls|plz|kindly)\s+)?(?:(?:snooze|remind(?:\s+me)?|set(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze|timer))?|add(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze))?|schedule|postpone|defer|delay|push)(?:\s+(?:it|this))?\s+)?(?:(?:on|to|for|at|until|till|by|from)\s+)?/;

const APPROX_RE = /^(?:approx(?:imately)?|around|about|roughly|~)\s+/;

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

const normalizeDigits = text => text.replace(/\p{Nd}/gu, toAsciiDigit);

const ARABIC_PUNCT_MAP = {
  '\u061f': '?',
  '\u060c': ',',
  '\u061b': ';',
  '\u066b': '.',
};

const sanitize = text =>
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

const stripNoise = text =>
  text
    .replace(NOISE_RE, '')
    .replace(APPROX_RE, '')
    .replace(/\bnxt\b/g, 'next')
    .replace(/\bcouple\s+of\b/g, 'couple')
    .replace(/\b(\d+)h(\d+)m?\b/g, '$1 hours $2 minutes')
    .replace(/\btomm?orow\b/g, 'tomorrow')
    .trim();

const parseNumber = str => {
  if (!str) return null;
  const lower = normalizeDigits(str.toLowerCase().trim());
  if (WORD_NUMBER_MAP[lower] !== undefined) return WORD_NUMBER_MAP[lower];
  const num = Number(lower);
  return Number.isNaN(num) ? null : num;
};

const applyTimeToDate = (date, hours, minutes = 0) =>
  set(date, { hours, minutes, seconds: 0, milliseconds: 0 });

const parseTimeString = timeStr => {
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

const applyTimeOrDefault = (date, timeStr, defaultHours = 9) => {
  if (timeStr) {
    const time = parseTimeString(timeStr);
    if (!time) return null;
    return applyTimeToDate(date, time.hours, time.minutes);
  }
  return applyTimeToDate(date, defaultHours, 0);
};

const strictDate = (year, month, day) => {
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

// Scan up to 8 years ahead for the next valid future date (handles feb 29 across leap cycles).
const futureOrNextYear = (year, month, day, timeStr, now) => {
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

const ensureFutureOrNextDay = (date, now) =>
  isAfter(date, now) ? date : add(date, { days: 1 });

// Infer hours from a bare number using time-of-day context.
// "morning 6" → 6 (am), "evening 6" → 18 (6pm), "afternoon 3" → 15 (3pm)
const inferHoursFromTOD = (todLabel, rawHour, rawMinutes) => {
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

// ─── Pattern Matchers ────────────────────────────────────────────────────────

const FRACTIONAL_CONVERT = {
  hours: { unit: 'minutes', factor: 60 },
  days: { unit: 'hours', factor: 24 },
  weeks: { unit: 'days', factor: 7 },
  months: { unit: 'days', factor: 30 },
  years: { unit: 'months', factor: 12 },
  minutes: { unit: 'seconds', factor: 60 },
};

const addFractionalSafe = (date, unit, amount) => {
  if (Number.isInteger(amount)) return add(date, { [unit]: amount });
  if (amount % 1 !== 0.5) return null;
  const conv = FRACTIONAL_CONVERT[unit];
  if (conv) return add(date, { [conv.unit]: Math.round(amount * conv.factor) });
  return add(date, { [unit]: Math.round(amount) });
};

const HALF_UNIT_DURATIONS = {
  hour: { minutes: 30 },
  day: { hours: 12 },
  week: { days: 3, hours: 12 },
  month: { days: 15 },
  year: { months: 6 },
};

const parseDuration = (match, now) => {
  if (!match) return null;
  const amount = parseNumber(match[1]);
  const unit = UNIT_MAP[match[2]];
  if (amount == null || !unit) return null;
  return addFractionalSafe(now, unit, amount);
};

const matchDuration = (text, now) => {
  const half = text.match(HALF_UNIT_RE);
  if (half) {
    return HALF_UNIT_DURATIONS[half[1]]
      ? add(now, HALF_UNIT_DURATIONS[half[1]])
      : null;
  }

  const compound = text.match(COMPOUND_DURATION_RE);
  if (compound) {
    const a1 = parseNumber(compound[1]);
    const u1 = UNIT_MAP[compound[2]];
    const a2 = parseNumber(compound[3]);
    const u2 = UNIT_MAP[compound[4]];
    if (a1 == null || !u1 || a2 == null || !u2) {
      return null;
    }
    return add(add(now, { [u1]: a1 }), { [u2]: a2 });
  }

  const atTime = text.match(DURATION_AT_TIME_RE);
  if (atTime) {
    const amount = parseNumber(atTime[1]);
    const unit = UNIT_MAP[atTime[2]];
    const time = parseTimeString(atTime[3]);
    if (amount == null || !unit || !time) {
      return null;
    }
    return applyTimeToDate(
      add(now, { [unit]: amount }),
      time.hours,
      time.minutes
    );
  }

  return (
    parseDuration(text.match(DURATION_FROM_NOW_RE), now) ||
    parseDuration(text.match(RELATIVE_DURATION_RE), now)
  );
};

const applyTimeWithRollover = (offset, hours, minutes, now) => {
  const base = add(startOfDay(now), { days: offset });
  const date = applyTimeToDate(base, hours, minutes);
  if (isAfter(date, now)) return date;
  return applyTimeToDate(add(base, { days: 1 }), hours, minutes);
};

const matchRelativeDay = (text, now) => {
  const dayOnlyMatch = text.match(RELATIVE_DAY_ONLY_RE);
  if (dayOnlyMatch) {
    const key = dayOnlyMatch[1];
    const offset = RELATIVE_DAY_MAP[key];
    if (key === 'tonight' || key === 'tonite') {
      return ensureFutureOrNextDay(
        applyTimeToDate(add(startOfDay(now), { days: offset }), 20, 0),
        now
      );
    }
    if (offset === 1) {
      return applyTimeToDate(add(startOfDay(now), { days: 1 }), 9, 0);
    }
    return add(now, { hours: 1 });
  }

  const dayTodTimeMatch = text.match(RELATIVE_DAY_TOD_TIME_RE);
  if (dayTodTimeMatch) {
    const timeParts = dayTodTimeMatch[3].split(':');
    const time = inferHoursFromTOD(
      dayTodTimeMatch[2],
      timeParts[0],
      timeParts[1]
    );
    if (!time) return null;
    return applyTimeWithRollover(
      RELATIVE_DAY_MAP[dayTodTimeMatch[1]],
      time.hours,
      time.minutes,
      now
    );
  }

  const dayTodMatch = text.match(RELATIVE_DAY_TOD_RE);
  if (dayTodMatch) {
    const { hours, minutes } = TIME_OF_DAY_MAP[dayTodMatch[2]];
    return applyTimeWithRollover(
      RELATIVE_DAY_MAP[dayTodMatch[1]],
      hours,
      minutes,
      now
    );
  }

  const dayAtTimeMatch = text.match(RELATIVE_DAY_AT_TIME_RE);
  if (dayAtTimeMatch) {
    const time = parseTimeString(dayAtTimeMatch[2]);
    if (!time) return null;
    return applyTimeWithRollover(
      RELATIVE_DAY_MAP[dayAtTimeMatch[1]],
      time.hours,
      time.minutes,
      now
    );
  }

  const sameTimeMatch = text.match(RELATIVE_DAY_SAME_TIME_RE);
  if (sameTimeMatch) {
    const offset = RELATIVE_DAY_MAP[sameTimeMatch[1]];
    if (offset <= 0) return null;
    return applyTimeToDate(
      add(startOfDay(now), { days: offset }),
      now.getHours(),
      now.getMinutes()
    );
  }

  return null;
};

const nextWeekdayInNextWeek = (dayIndex, now) => {
  const fn = NEXT_WEEKDAY_FN[dayIndex];
  if (!fn) return null;
  const date = fn(now);
  const sameWeek =
    startOfWeek(now, { weekStartsOn: 1 }).getTime() ===
    startOfWeek(date, { weekStartsOn: 1 }).getTime();
  return sameWeek ? fn(date) : date;
};

const matchNextPattern = (text, now) => {
  const nextUnitMatch = text.match(NEXT_UNIT_RE);
  if (nextUnitMatch) {
    const unit = nextUnitMatch[1];
    if (unit === 'hour') return add(now, { hours: 1 });
    if (unit === 'minute') return add(now, { minutes: 1 });
    if (unit === 'week') {
      const base = startOfWeek(addWeeks(now, 1), { weekStartsOn: 1 });
      return applyTimeOrDefault(base, nextUnitMatch[2]);
    }
    const base = add(startOfDay(now), { [`${unit}s`]: 1 });
    return applyTimeOrDefault(base, nextUnitMatch[2]);
  }

  const nextMonthMatch = text.match(NEXT_MONTH_RE);
  if (nextMonthMatch) {
    const monthIdx = MONTH_MAP[nextMonthMatch[1]];
    let year = now.getFullYear();
    if (monthIdx <= now.getMonth()) year += 1;
    const base = new Date(year, monthIdx, 1);
    return applyTimeOrDefault(base, nextMonthMatch[2]);
  }

  // "next monday morning", "next friday midnight" — weekday + time-of-day
  const nextTodMatch = text.match(NEXT_WEEKDAY_TOD_RE);
  if (nextTodMatch) {
    const date = nextWeekdayInNextWeek(WEEKDAY_MAP[nextTodMatch[1]], now);
    if (!date) return null;
    const { hours, minutes } = TIME_OF_DAY_MAP[nextTodMatch[2]];
    return applyTimeToDate(date, hours, minutes);
  }

  // "monday of next week", "next week monday", "next friday" — all with optional time
  const weekdayMatch = text.match(NEXT_WEEKDAY_RE);
  if (weekdayMatch) {
    const dayName = weekdayMatch[1] || weekdayMatch[2] || weekdayMatch[3];
    const date = nextWeekdayInNextWeek(WEEKDAY_MAP[dayName], now);
    if (!date) return null;
    return applyTimeOrDefault(date, weekdayMatch[4]);
  }

  return null;
};

const resolveWeekdayDate = (dayIndex, timeStr, now) => {
  const fn = NEXT_WEEKDAY_FN[dayIndex];
  if (!fn) return null;
  let adjusted = timeStr;
  if (timeStr && /^\d{1,2}$/.test(timeStr.trim())) {
    const h = parseInt(timeStr, 10);
    if (h >= 1 && h <= 7) adjusted = `${h}pm`;
  }

  if (getDay(now) === dayIndex) {
    const todayDate = applyTimeOrDefault(now, adjusted);
    if (todayDate && isAfter(todayDate, now)) return todayDate;
  }

  return applyTimeOrDefault(fn(now), adjusted);
};

const matchWeekday = (text, now) => {
  const sameTimeWeekday = text.match(SAME_TIME_WEEKDAY_RE);
  if (sameTimeWeekday) {
    const dayIndex = WEEKDAY_MAP[sameTimeWeekday[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    const target = fn(now);
    return applyTimeToDate(target, now.getHours(), now.getMinutes());
  }

  // "monday morning 6", "friday evening 7" — weekday + tod + bare number
  const todTimeMatch = text.match(WEEKDAY_TOD_TIME_RE);
  if (todTimeMatch) {
    const dayIndex = WEEKDAY_MAP[todTimeMatch[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    const timeParts = todTimeMatch[3].split(':');
    const time = inferHoursFromTOD(todTimeMatch[2], timeParts[0], timeParts[1]);
    if (!time) return null;
    const target =
      getDay(now) === dayIndex ? startOfDay(now) : startOfDay(fn(now));
    const date = applyTimeToDate(target, time.hours, time.minutes);
    return isAfter(date, now)
      ? date
      : applyTimeToDate(fn(now), time.hours, time.minutes);
  }

  // "monday morning", "friday midnight", "wednesday evening", etc.
  const todMatch = text.match(WEEKDAY_TOD_RE);
  if (todMatch) {
    const dayIndex = WEEKDAY_MAP[todMatch[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    const { hours, minutes } = TIME_OF_DAY_MAP[todMatch[2]];
    const target =
      getDay(now) === dayIndex ? startOfDay(now) : startOfDay(fn(now));
    const date = applyTimeToDate(target, hours, minutes);
    return isAfter(date, now) ? date : applyTimeToDate(fn(now), hours, minutes);
  }

  const match = text.match(WEEKDAY_TIME_RE);
  if (!match) return null;

  return resolveWeekdayDate(WEEKDAY_MAP[match[1]], match[2], now);
};

const matchTimeOnly = (text, now) => {
  const match =
    text.match(TIME_ONLY_MERIDIEM_RE) || text.match(TIME_ONLY_24H_RE);
  if (!match) return null;

  const time = parseTimeString(match[1]);
  if (!time) return null;
  return ensureFutureOrNextDay(
    applyTimeToDate(now, time.hours, time.minutes),
    now
  );
};

const matchTimeOfDay = (text, now) => {
  const todWithTime = text.match(TOD_WITH_TIME_RE);
  if (todWithTime) {
    const rawTime = todWithTime[2].trim();
    const hasMeridiem = /(?:am|pm|a\.m|p\.m)/i.test(rawTime);
    let time;
    if (hasMeridiem) {
      time = parseTimeString(rawTime);
      const range = TOD_HOUR_RANGE[todWithTime[1]];
      if (!time) return null;
      if (range) {
        const h = time.hours === 0 ? 24 : time.hours;
        if (h < range[0] || h >= range[1]) return null;
      }
    } else {
      const parts = rawTime.split(':');
      time = inferHoursFromTOD(todWithTime[1], parts[0], parts[1]);
    }
    if (!time) return null;
    return ensureFutureOrNextDay(
      applyTimeToDate(now, time.hours, time.minutes),
      now
    );
  }

  const match = text.match(TOD_PLAIN_RE);
  if (!match) return null;

  const key = text
    .replace(/^(?:later|in)\s+/, '')
    .replace(/^(?:this|the)\s+/, '')
    .trim();
  const tod = TIME_OF_DAY_MAP[key];
  if (!tod) return null;
  return ensureFutureOrNextDay(
    applyTimeToDate(now, tod.hours, tod.minutes),
    now
  );
};

const resolveAbsoluteDate = (month, day, yearStr, timeStr, now) => {
  let year = now.getFullYear();
  if (yearStr && /next\s+year/i.test(yearStr)) {
    year += 1;
  } else if (yearStr) {
    year = parseInt(yearStr, 10);
  }
  if (yearStr) {
    const base = strictDate(year, month, day);
    if (!base) return null;
    const date = applyTimeOrDefault(base, timeStr);
    return date && isAfter(date, now) ? date : null;
  }
  return futureOrNextYear(year, month, day, timeStr, now);
};

const matchNamedDate = (text, now) => {
  const abs = text.match(ABSOLUTE_DATE_RE);
  if (abs) {
    return resolveAbsoluteDate(
      MONTH_MAP[abs[1]],
      parseInt(abs[2], 10),
      abs[3],
      abs[4],
      now
    );
  }

  const rev = text.match(ABSOLUTE_DATE_REVERSED_RE);
  if (rev) {
    return resolveAbsoluteDate(
      MONTH_MAP[rev[2]],
      parseInt(rev[1], 10),
      rev[3],
      rev[4],
      now
    );
  }

  const my = text.match(MONTH_YEAR_RE);
  if (my) {
    const date = new Date(parseInt(my[2], 10), MONTH_MAP[my[1]], 1);
    if (!isValid(date)) return null;
    const result = applyTimeToDate(date, 9, 0);
    return isAfter(result, now) ? result : null;
  }

  return null;
};

const buildDateWithOptionalTime = (year, month, day, timeStr) => {
  const date = strictDate(year, month, day);
  if (!date) return null;
  return applyTimeOrDefault(date, timeStr);
};

// When both values are ≤ 12 (ambiguous), defaults to M/D (US format).
const disambiguateDayMonth = (a, b) => {
  if (a > 12) return { day: a, month: b - 1 };
  if (b > 12) return { month: a - 1, day: b };
  return { month: a - 1, day: b };
};

const matchFormalDate = (text, now) => {
  const ensureFuture = date => (date && isAfter(date, now) ? date : null);

  const isoMatch = text.match(ISO_DATE_RE);
  if (isoMatch) {
    return ensureFuture(
      buildDateWithOptionalTime(
        parseInt(isoMatch[1], 10),
        parseInt(isoMatch[2], 10) - 1,
        parseInt(isoMatch[3], 10),
        isoMatch[4]
      )
    );
  }

  let result = null;
  AMBIGUOUS_DATE_RES.some(re => {
    const m = text.match(re);
    if (!m) return false;
    const { month, day } = disambiguateDayMonth(
      parseInt(m[1], 10),
      parseInt(m[2], 10)
    );
    result = ensureFuture(
      buildDateWithOptionalTime(parseInt(m[3], 10), month, day, m[4])
    );
    return true;
  });
  return result;
};

const matchSpecial = (text, now) => {
  const dat = text.match(DAY_AFTER_TOMORROW_RE);
  if (dat) return applyTimeOrDefault(add(startOfDay(now), { days: 2 }), dat[1]);

  const eof = text.match(END_OF_RE);
  if (eof) {
    if (eof[1] === 'day') return applyTimeToDate(now, 17, 0);
    if (eof[1] === 'week') {
      const fri = applyTimeToDate(now, 17, 0);
      if (getDay(now) === 5 && isAfter(fri, now)) return fri;
      return applyTimeToDate(nextFriday(now), 17, 0);
    }
    if (eof[1] === 'month') {
      const eom = applyTimeToDate(endOfMonth(now), 17, 0);
      if (isAfter(eom, now)) return eom;
      return applyTimeToDate(endOfMonth(add(now, { months: 1 })), 17, 0);
    }
  }

  if (LATER_TODAY_RE.test(text)) return add(now, { hours: 3 });

  const weekendMatch = text.match(
    /^(this weekend|weekend|next weekend)(?:\s+(?:at\s+)?(.+))?$/
  );
  if (weekendMatch) {
    const isNext = weekendMatch[1] === 'next weekend';
    const timeStr = weekendMatch[2];

    if (isNext) {
      const sat = nextSaturday(now);
      const d = isSaturday(now) || isSunday(now) ? sat : add(sat, { weeks: 1 });
      return applyTimeOrDefault(d, timeStr);
    }

    if (isSaturday(now)) {
      if (!timeStr) {
        if (now.getHours() < 10) return applyTimeToDate(now, 10, 0);
        if (now.getHours() < 18) return add(now, { hours: 2 });
        return applyTimeToDate(add(startOfDay(now), { days: 1 }), 10, 0);
      }
      const today = applyTimeOrDefault(now, timeStr);
      if (today && isAfter(today, now)) return today;
      return applyTimeOrDefault(add(startOfDay(now), { days: 1 }), timeStr);
    }
    if (isSunday(now)) {
      if (!timeStr) {
        if (now.getHours() < 10) return applyTimeToDate(now, 10, 0);
        return add(now, { hours: 2 });
      }
      const today = applyTimeOrDefault(now, timeStr);
      if (today && isAfter(today, now)) return today;
    }
    return applyTimeOrDefault(nextSaturday(now), timeStr);
  }

  return null;
};

// ─── Main Parser ─────────────────────────────────────────────────────────────

const MATCHERS = [
  matchDuration,
  matchSpecial,
  matchRelativeDay,
  matchNextPattern,
  matchTimeOfDay,
  matchWeekday,
  matchTimeOnly,
  matchNamedDate,
  matchFormalDate,
];

/**
 * Parse a natural language date/time string into a future Date.
 * Returns { date, unix } or null. All results are strictly future.
 * Uses runtime local timezone. 999-year max cap.
 *
 * @param {string} text - Natural language date/time string
 * @param {Date} [referenceDate=new Date()] - Reference date
 * @returns {{ date: Date, unix: number } | null}
 */
export const parseDateFromText = (text, referenceDate = new Date()) => {
  if (!text || typeof text !== 'string') return null;

  const normalized = stripNoise(sanitize(text));
  if (!normalized) return null;

  const maxDate = add(referenceDate, { years: 999 });

  const isValidFuture = d =>
    d && isValid(d) && isAfter(d, referenceDate) && !isBefore(maxDate, d);

  let result = null;
  MATCHERS.some(matcher => {
    const d = matcher(normalized, referenceDate);
    if (isValidFuture(d)) {
      result = { date: d, unix: getUnixTime(d) };
      return true;
    }
    return false;
  });

  return result;
};

// ─── Smart Suggestion Engine ─────────────────────────────────────────────────

const SUGGESTION_UNITS = [...new Set(Object.values(UNIT_MAP))].filter(
  u => u !== 'seconds'
);

const FULL_WEEKDAYS = Object.keys(WEEKDAY_MAP).filter(k => k.length > 3);
const TOD_NAMES = Object.keys(TIME_OF_DAY_MAP).filter(k => !k.includes(' '));
const MONTH_NAMES_LONG = Object.keys(MONTH_MAP).filter(k => k.length > 3);

const ALL_SUGGESTION_PHRASES = [
  ...Object.keys(RELATIVE_DAY_MAP),
  ...FULL_WEEKDAYS,
  ...TOD_NAMES,
  'next week',
  'next month',
  'this weekend',
  'next weekend',
  'day after tomorrow',
  'later today',
  'end of day',
  'end of week',
  'end of month',
  ...TOD_NAMES.map(tod => `tomorrow ${tod}`),
  ...TOD_NAMES.map(tod => `tomorrow at ${tod}`),
  ...FULL_WEEKDAYS.map(wd => `next ${wd}`),
  ...FULL_WEEKDAYS.map(wd => `this ${wd}`),
  ...FULL_WEEKDAYS.flatMap(wd => TOD_NAMES.map(tod => `${wd} ${tod}`)),
  ...FULL_WEEKDAYS.flatMap(wd => TOD_NAMES.map(tod => `next ${wd} ${tod}`)),
  ...MONTH_NAMES_LONG.map(m => `${m} 1`),
];

const prefixMatchScore = (candidate, input) => {
  if (candidate === input) return -1;
  if (candidate.startsWith(input)) return 0;
  const inputWords = input.split(' ');
  const candidateWords = candidate.split(' ');
  const lastIdx = inputWords.reduce((prev, iw) => {
    if (prev === -2) return -2;
    const idx = candidateWords.findIndex(
      (cw, ci) => ci > prev && cw.startsWith(iw)
    );
    return idx === -1 ? -2 : idx;
  }, -1);
  if (lastIdx === -2) return -1;
  return candidateWords.length - inputWords.length;
};

const MAX_SUGGESTIONS = 5;

const buildSuggestionCandidates = text => {
  if (!text) return [];

  if (/^\d/.test(text)) {
    const num = text.match(/^\d+(?:\.5)?/)[0];
    const candidates = SUGGESTION_UNITS.map(u => `${num} ${u}`);
    const trimmed = text.replace(/\s+/g, ' ').trim();
    return trimmed.length > num.length
      ? candidates.filter(c => c.startsWith(trimmed))
      : candidates;
  }

  if (text.length >= 2 && 'half'.startsWith(text)) {
    return Object.keys(HALF_UNIT_DURATIONS).map(u => `half ${u}`);
  }

  const wordNum = WORD_NUMBER_MAP[text];
  if (wordNum != null && wordNum >= 1) {
    return SUGGESTION_UNITS.map(u => `${wordNum} ${u}`);
  }

  const scored = ALL_SUGGESTION_PHRASES.reduce((acc, candidate) => {
    const score = prefixMatchScore(candidate, text);
    if (score >= 0) acc.push({ candidate, score });
    return acc;
  }, []);
  scored.sort((a, b) => a.score - b.score);
  const seen = new Set();
  return scored.reduce((acc, { candidate }) => {
    if (acc.length < MAX_SUGGESTIONS * 3 && !seen.has(candidate)) {
      seen.add(candidate);
      acc.push(candidate);
    }
    return acc;
  }, []);
};

// ─── Localized Input Support ─────────────────────────────────────────────────

const EN_WEEKDAYS_LIST = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];
const EN_MONTHS_LIST = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

const EN_DEFAULTS = {
  UNITS: {
    MINUTE: 'minute',
    MINUTES: 'minutes',
    HOUR: 'hour',
    HOURS: 'hours',
    DAY: 'day',
    DAYS: 'days',
    WEEK: 'week',
    WEEKS: 'weeks',
    MONTH: 'month',
    MONTHS: 'months',
    YEAR: 'year',
    YEARS: 'years',
  },
  RELATIVE: {
    TOMORROW: 'tomorrow',
    DAY_AFTER_TOMORROW: 'day after tomorrow',
    NEXT_WEEK: 'next week',
    NEXT_MONTH: 'next month',
    THIS_WEEKEND: 'this weekend',
    NEXT_WEEKEND: 'next weekend',
  },
  TIME_OF_DAY: {
    MORNING: 'morning',
    AFTERNOON: 'afternoon',
    EVENING: 'evening',
    NIGHT: 'night',
    NOON: 'noon',
    MIDNIGHT: 'midnight',
  },
  WORD_NUMBERS: {
    ONE: 'one',
    TWO: 'two',
    THREE: 'three',
    FOUR: 'four',
    FIVE: 'five',
    SIX: 'six',
    SEVEN: 'seven',
    EIGHT: 'eight',
    NINE: 'nine',
    TEN: 'ten',
    TWELVE: 'twelve',
    FIFTEEN: 'fifteen',
    TWENTY: 'twenty',
    THIRTY: 'thirty',
  },
  MERIDIEM: { AM: 'am', PM: 'pm' },
  HALF: 'half',
  NEXT: 'next',
  THIS: 'this',
  AT: 'at',
  IN: 'in',
  FROM_NOW: 'from now',
  NEXT_YEAR: 'next year',
};

const STRUCTURAL_WORDS = [
  'at',
  'in',
  'next',
  'this',
  'from',
  'now',
  'after',
  'half',
  'same',
  'time',
  'weekend',
  'end',
  'of',
  'the',
  'eod',
  'am',
  'pm',
];

const ENGLISH_VOCAB = new Set([
  ...Object.keys(WEEKDAY_MAP),
  ...Object.keys(MONTH_MAP),
  ...Object.keys(UNIT_MAP),
  ...Object.keys(WORD_NUMBER_MAP),
  ...Object.keys(RELATIVE_DAY_MAP),
  ...Object.keys(TIME_OF_DAY_MAP),
  ...EN_WEEKDAYS_LIST,
  ...EN_MONTHS_LIST,
  ...STRUCTURAL_WORDS,
]);
const ENGLISH_VOCAB_LIST = [...ENGLISH_VOCAB];
const hasVocabPrefix = w => ENGLISH_VOCAB_LIST.some(v => v.startsWith(w));

const safeString = v => (v == null ? '' : String(v));

const MAX_PAIRS_CACHE = 20;
const pairsCache = new Map();
const CACHE_SECTIONS = [
  'UNITS',
  'RELATIVE',
  'TIME_OF_DAY',
  'WORD_NUMBERS',
  'MERIDIEM',
];
const SINGLE_KEYS = [
  'HALF',
  'NEXT',
  'THIS',
  'AT',
  'IN',
  'FROM_NOW',
  'NEXT_YEAR',
];

const translationSignature = translations => {
  if (!translations || typeof translations !== 'object') return 'none';
  return [
    ...CACHE_SECTIONS.flatMap(section => {
      const values = translations[section] || {};
      return Object.keys(values)
        .sort()
        .map(k => `${section}.${k}:${safeString(values[k]).toLowerCase()}`);
    }),
    ...SINGLE_KEYS.map(
      k => `${k}:${safeString(translations[k]).toLowerCase()}`
    ),
  ].join('|');
};

const buildReplacementPairsUncached = (translations, locale) => {
  const pairs = [];
  const seen = new Set();
  const t = translations || {};

  const addPair = (local, en) => {
    const l = sanitize(safeString(local));
    const e = safeString(en).toLowerCase();
    if (l && e && l !== e && !seen.has(l)) {
      seen.add(l);
      pairs.push([l, e]);
    }
  };

  CACHE_SECTIONS.forEach(section => {
    const localSection = t[section] || {};
    const enSection = EN_DEFAULTS[section] || {};
    Object.keys(enSection).forEach(key => {
      addPair(localSection[key], enSection[key]);
    });
  });

  SINGLE_KEYS.forEach(key => addPair(t[key], EN_DEFAULTS[key]));

  try {
    const wdFmt = new Intl.DateTimeFormat(locale, { weekday: 'long' });
    // Jan 1, 2024 is a Monday — aligns with EN_WEEKDAYS_LIST[0]='monday'
    EN_WEEKDAYS_LIST.forEach((en, i) => {
      addPair(wdFmt.format(new Date(2024, 0, i + 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  try {
    const moFmt = new Intl.DateTimeFormat(locale, { month: 'long' });
    EN_MONTHS_LIST.forEach((en, i) => {
      addPair(moFmt.format(new Date(2024, i, 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  pairs.sort((a, b) => b[0].length - a[0].length);
  return pairs;
};

const buildReplacementPairs = (translations, locale) => {
  const cacheKey = `${locale || ''}:${translationSignature(translations)}`;
  if (pairsCache.has(cacheKey)) return pairsCache.get(cacheKey);
  const pairs = buildReplacementPairsUncached(translations, locale);
  if (pairsCache.size >= MAX_PAIRS_CACHE)
    pairsCache.delete(pairsCache.keys().next().value);
  pairsCache.set(cacheKey, pairs);
  return pairs;
};

const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const substituteLocalTokens = (text, pairs) => {
  let r = text;
  pairs.forEach(([local, en]) => {
    const re = new RegExp(`(?<=^|\\s)${escapeRegex(local)}(?=\\s|$)`, 'g');
    r = r.replace(re, en);
  });
  return r;
};

const filterToEnglishVocab = text =>
  normalizeDigits(text)
    .replace(/(\d+)h\b/g, '$1:00')
    .split(/\s+/)
    .filter(w => /[\d:]/.test(w) || ENGLISH_VOCAB.has(w.toLowerCase()))
    .join(' ')
    .replace(/\s+/g, ' ')
    .trim();

const repositionNextYear = text => {
  if (!MONTH_NAME_RE.test(text)) return text;
  let r = text.replace(/\b(?:next\s+)?year\b/i, m =>
    /next/i.test(m) ? m : 'next year'
  );
  if (!/\bnext\s+year\b/i.test(r)) return r;
  const withoutNY = r.replace(/\bnext\s+year\b/i, '').trim();
  const timeRe = /(?:(?:at\s+)?\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*$/i;
  const timePart = withoutNY.match(timeRe);
  if (timePart) {
    const beforeTime = withoutNY.slice(0, timePart.index).trim();
    r = `${beforeTime} next year ${timePart[0].trim()}`;
  } else {
    r = `${withoutNY} next year`;
  }
  return r;
};

const replaceTokens = (text, pairs) => {
  const substituted = substituteLocalTokens(text, pairs);
  const filtered = filterToEnglishVocab(substituted);
  const fixed = filtered.replace(
    NUM_TOD_RE,
    (_, t, tod) => `${t}${TOD_TO_MERIDIEM[tod]}`
  );
  return stripNoise(repositionNextYear(fixed));
};

const reverseTokens = (text, pairs) =>
  pairs.reduce(
    (r, [local, en]) =>
      r.replace(
        new RegExp(`(?<=^|\\s)${escapeRegex(en)}(?=\\s|$)`, 'g'),
        local
      ),
    text
  );

/**
 * Generate smart snooze suggestions for a search prefix.
 * Builds compositional candidates (weekday+tod, next+weekday, etc.)
 * with multi-word fuzzy prefix matching. Supports multilingual input.
 * Deduped by unix timestamp, capped at 5.
 *
 * @param {string} text - Search prefix
 * @param {Date} [referenceDate=new Date()] - Reference date
 * @param {{ translations?: object, locale?: string }} [options={}] - i18n
 * @returns {Array<{ label: string, date: Date, unix: number }>}
 */
export const generateDateSuggestions = (
  text,
  referenceDate = new Date(),
  { translations, locale } = {}
) => {
  if (!text || typeof text !== 'string') return [];
  const normalized = sanitize(text);
  if (!normalized) return [];

  const stripped = stripNoise(normalized);
  const pairs =
    locale && locale !== 'en'
      ? buildReplacementPairs(translations, locale)
      : [];

  // Try English first — if user types English in a non-English locale, skip translation
  const directParse = parseDateFromText(stripped, referenceDate);
  const looksEnglish =
    directParse ||
    stripped
      .split(/\s+/)
      .filter(w => !/^\d/.test(w))
      .some(w => ENGLISH_VOCAB.has(w) || (w.length >= 2 && hasVocabPrefix(w)));
  const useEnglish = !pairs.length || looksEnglish;

  const englishInput = useEnglish ? stripped : replaceTokens(normalized, pairs);

  const seen = new Set();
  const results = [];

  const exact = directParse || parseDateFromText(englishInput, referenceDate);
  if (exact) {
    seen.add(exact.unix);
    results.push({ label: normalized, ...exact });
  }

  buildSuggestionCandidates(englishInput).some(candidate => {
    if (results.length >= MAX_SUGGESTIONS) return true;
    const result = parseDateFromText(candidate, referenceDate);
    if (result && !seen.has(result.unix)) {
      seen.add(result.unix);
      const label =
        !useEnglish && pairs.length
          ? reverseTokens(candidate, pairs)
          : candidate;
      results.push({ label, ...result });
    }
    return false;
  });

  return results;
};
