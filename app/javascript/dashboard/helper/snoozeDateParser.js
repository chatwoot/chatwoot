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
} from 'date-fns';

// ─── Token Definitions ───────────────────────────────────────────────────────

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
  fifteen: 15,
  twenty: 20,
  thirty: 30,
  forty: 40,
  fifty: 50,
  sixty: 60,
  ninety: 90,
  half: 0.5,
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

const NUM_RE = `(\\d+|${WORD_NUMBERS})`;
const UNIT_RE = `(${UNIT_NAMES})`;
const TIME_SUFFIX_RE =
  '(?:\\s+(?:at\\s+)?(\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.?|p\\.m\\.?)?|\\d{1,2}:\\d{2}))?';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const NOISE_RE =
  /^(?:(?:please|pls|plz|kindly)\s+)?(?:(?:snooze|remind(?:\s+me)?|set(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze|timer))?|add(?:\s+(?:a|the))?(?:\s+(?:reminder|deadline|snooze))?|schedule|postpone|defer|delay|push(?:\s+(?:it|this))?)\s+)?(?:(?:on|to|for|at|until|till|by)\s+)?/;

const APPROX_RE = /^(?:approx(?:imately)?|around|about|roughly|~)\s+/;

const normalize = text => {
  let t = text
    .toLowerCase()
    .replace(/[,!?;]+/g, ' ')
    .replace(/\.+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  t = t.replace(NOISE_RE, '').trim();
  t = t.replace(APPROX_RE, '').trim();
  return t;
};

const parseNumber = str => {
  if (!str) return null;
  const lower = str.toLowerCase().trim();
  if (WORD_NUMBER_MAP[lower] !== undefined) return WORD_NUMBER_MAP[lower];
  const num = Number(lower);
  return Number.isNaN(num) ? null : num;
};

const applyTimeToDate = (date, hours, minutes = 0) =>
  set(date, { hours, minutes, seconds: 0, milliseconds: 0 });

const parseTimeString = timeStr => {
  if (!timeStr) return null;
  const cleaned = timeStr.toLowerCase().replace(/\s+/g, '').trim();

  const match = cleaned.match(
    /^(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.?|p\.m\.?)?$/
  );
  if (!match) return null;

  let hours = parseInt(match[1], 10);
  const minutes = match[2] ? parseInt(match[2], 10) : 0;
  const meridiem = match[3]?.replace(/\./g, '');

  if (meridiem) {
    if (hours < 1 || hours > 12) return null;
  }
  if (meridiem === 'pm' && hours < 12) hours += 12;
  if (meridiem === 'am' && hours === 12) hours = 0;
  if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return null;

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

const futureOrNextYear = (year, month, day, timeStr, now) => {
  // Scan up to 8 years ahead to find the next valid future date.
  // Handles feb 29 in non-leap years (leap years repeat every 4 years).
  const years = Array.from({ length: 9 }, (_, i) => year + i);
  let result = null;
  years.some(y => {
    const base = strictDate(y, month, day);
    if (!base) return false;
    const date = applyTimeOrDefault(base, timeStr);
    if (date && isAfter(date, now)) {
      result = date;
      return true;
    }
    return !date;
  });
  return result;
};

const resolveTimeOfDay = (text, now) => {
  const tod = TIME_OF_DAY_MAP[text];
  if (!tod) return null;
  let date = applyTimeToDate(now, tod.hours, tod.minutes);
  if (!isAfter(date, now)) date = add(date, { days: 1 });
  return date;
};

// ─── Pattern Matchers ────────────────────────────────────────────────────────

const matchRelativeDuration = (text, now) => {
  if (text.match(/^(?:in\s+)?half\s+(?:an?\s+)?hour$/)) {
    return add(now, { minutes: 30 });
  }
  if (text.match(/^(?:in\s+)?half\s+(?:an?\s+)?day$/)) {
    return add(now, { hours: 12 });
  }

  const match = text.match(new RegExp(`^(?:in\\s+)?${NUM_RE}\\s+${UNIT_RE}$`));
  if (!match) return null;

  const amount = parseNumber(match[1]);
  const unit = UNIT_MAP[match[2]];
  if (amount == null || !unit) return null;

  return add(now, { [unit]: amount });
};

const matchDurationFromNow = (text, now) => {
  const match = text.match(
    new RegExp(`^${NUM_RE}\\s+${UNIT_RE}\\s+from\\s+now$`)
  );
  if (!match) return null;

  const amount = parseNumber(match[1]);
  const unit = UNIT_MAP[match[2]];
  if (amount == null || !unit) return null;

  return add(now, { [unit]: amount });
};

const matchRelativeDay = (text, now) => {
  const dayOnlyMatch = text.match(new RegExp(`^(${RELATIVE_DAYS})$`));
  if (dayOnlyMatch) {
    const key = dayOnlyMatch[1];
    const offset = RELATIVE_DAY_MAP[key];
    let date = add(startOfDay(now), { days: offset });
    if (key === 'tonight') {
      date = applyTimeToDate(date, 20, 0);
      if (!isAfter(date, now)) date = add(date, { days: 1 });
    } else if (offset === 1) {
      date = applyTimeToDate(date, 9, 0);
    } else {
      date = add(now, { hours: 1 });
    }
    return date;
  }

  const dayTodMatch = text.match(
    new RegExp(`^(${RELATIVE_DAYS})\\s+(${TIME_OF_DAY_NAMES})$`)
  );
  if (dayTodMatch) {
    const offset = RELATIVE_DAY_MAP[dayTodMatch[1]];
    const tod = TIME_OF_DAY_MAP[dayTodMatch[2]];
    let base = add(startOfDay(now), { days: offset });
    let date = applyTimeToDate(base, tod.hours, tod.minutes);
    if (!isAfter(date, now)) {
      base = add(base, { days: 1 });
      date = applyTimeToDate(base, tod.hours, tod.minutes);
    }
    return date;
  }

  const dayAtTimeMatch = text.match(
    new RegExp(
      `^(${RELATIVE_DAYS})\\s+(?:at\\s+)?(\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.?|p\\.m\\.?)?|\\d{1,2}:\\d{2})$`
    )
  );
  if (dayAtTimeMatch) {
    const offset = RELATIVE_DAY_MAP[dayAtTimeMatch[1]];
    const time = parseTimeString(dayAtTimeMatch[2]);
    if (!time) return null;
    let base = add(startOfDay(now), { days: offset });
    let date = applyTimeToDate(base, time.hours, time.minutes);
    if (!isAfter(date, now)) {
      base = add(base, { days: 1 });
      date = applyTimeToDate(base, time.hours, time.minutes);
    }
    return date;
  }

  const sameTimeMatch = text.match(
    new RegExp(`^(${RELATIVE_DAYS})\\s+(?:same\\s+time|this\\s+time)$`)
  );
  if (sameTimeMatch) {
    const offset = RELATIVE_DAY_MAP[sameTimeMatch[1]];
    if (offset <= 0) return null;
    const base = add(startOfDay(now), { days: offset });
    return applyTimeToDate(base, now.getHours(), now.getMinutes());
  }

  return null;
};

const matchNextPattern = (text, now) => {
  const nextUnitMatch = text.match(/^next\s+(hour|minute|week|month|year)$/);
  if (nextUnitMatch) {
    const unit = nextUnitMatch[1];
    if (unit === 'hour') return add(now, { hours: 1 });
    if (unit === 'minute') return add(now, { minutes: 1 });
    if (unit === 'week') {
      const base = startOfWeek(addWeeks(now, 1), { weekStartsOn: 1 });
      return applyTimeToDate(base, 9, 0);
    }
    const base = add(startOfDay(now), { [`${unit}s`]: 1 });
    return applyTimeToDate(base, 9, 0);
  }

  const weekdayOfNextMatch = text.match(
    new RegExp(
      `^(${WEEKDAY_NAMES})\\s+(?:of\\s+)?next\\s+week${TIME_SUFFIX_RE}$`
    )
  );
  if (weekdayOfNextMatch) {
    const dayIndex = WEEKDAY_MAP[weekdayOfNextMatch[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    let date = fn(now);
    const nowWeekStart = startOfWeek(now, { weekStartsOn: 1 });
    const dateWeekStart = startOfWeek(date, { weekStartsOn: 1 });
    if (nowWeekStart.getTime() === dateWeekStart.getTime()) {
      date = fn(date);
    }
    return applyTimeOrDefault(date, weekdayOfNextMatch[2]);
  }

  const nextWeekDayMatch = text.match(
    new RegExp(`^next\\s+week\\s+(${WEEKDAY_NAMES})${TIME_SUFFIX_RE}$`)
  );
  if (nextWeekDayMatch) {
    const dayIndex = WEEKDAY_MAP[nextWeekDayMatch[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    let date = fn(now);
    const nowWeekStart = startOfWeek(now, { weekStartsOn: 1 });
    const dateWeekStart = startOfWeek(date, { weekStartsOn: 1 });
    if (nowWeekStart.getTime() === dateWeekStart.getTime()) {
      date = fn(date);
    }
    return applyTimeOrDefault(date, nextWeekDayMatch[2]);
  }

  const nextDayMatch = text.match(
    new RegExp(`^next\\s+(${WEEKDAY_NAMES})${TIME_SUFFIX_RE}$`)
  );
  if (nextDayMatch) {
    const dayIndex = WEEKDAY_MAP[nextDayMatch[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;

    let date = fn(now);
    const nowWeekStart = startOfWeek(now, { weekStartsOn: 1 });
    const dateWeekStart = startOfWeek(date, { weekStartsOn: 1 });
    if (nowWeekStart.getTime() === dateWeekStart.getTime()) {
      date = fn(date);
    }

    return applyTimeOrDefault(date, nextDayMatch[2]);
  }

  return null;
};

const matchWeekday = (text, now) => {
  const sameTimeWeekday = text.match(
    new RegExp(`^(?:same\\s+time|this\\s+time)\\s+(${WEEKDAY_NAMES})$`)
  );
  if (sameTimeWeekday) {
    const dayIndex = WEEKDAY_MAP[sameTimeWeekday[1]];
    const fn = NEXT_WEEKDAY_FN[dayIndex];
    if (!fn) return null;
    const target = fn(now);
    return applyTimeToDate(target, now.getHours(), now.getMinutes());
  }

  const match = text.match(
    new RegExp(
      `^(?:(?:this|upcoming|coming)\\s+)?(${WEEKDAY_NAMES})${TIME_SUFFIX_RE}$`
    )
  );
  if (!match) return null;

  const dayIndex = WEEKDAY_MAP[match[1]];
  const fn = NEXT_WEEKDAY_FN[dayIndex];
  if (!fn) return null;

  if (getDay(now) === dayIndex) {
    const todayDate = applyTimeOrDefault(now, match[2]);
    if (todayDate && isAfter(todayDate, now)) return todayDate;
  }

  return applyTimeOrDefault(fn(now), match[2]);
};

const matchTimeOnly = (text, now) => {
  let match = text.match(
    /^(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.?|p\.m\.?))$/
  );
  if (!match) match = text.match(/^(?:at\s+)?(\d{1,2}:\d{2})$/);
  if (!match) return null;

  const time = parseTimeString(match[1]);
  if (!time) return null;

  let date = applyTimeToDate(now, time.hours, time.minutes);
  if (!isAfter(date, now)) date = add(date, { days: 1 });
  return date;
};

const isTimeConsistentWithTOD = (todLabel, hours) => {
  const range = TOD_HOUR_RANGE[todLabel];
  if (!range) return true;
  const h = hours === 0 ? 24 : hours;
  return h >= range[0] && h < range[1];
};

const matchTimeOfDay = (text, now) => {
  const todWithTime = text.match(
    new RegExp(
      `^(?:(?:this|the)\\s+)?(${TIME_OF_DAY_NAMES})\\s+(?:at\\s+)?(\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.?|p\\.m\\.?))$`
    )
  );
  if (todWithTime) {
    const todLabel = todWithTime[1];
    const time = parseTimeString(todWithTime[2]);
    if (!time) return null;
    if (!isTimeConsistentWithTOD(todLabel, time.hours)) return null;
    let date = applyTimeToDate(now, time.hours, time.minutes);
    if (!isAfter(date, now)) date = add(date, { days: 1 });
    return date;
  }

  const match = text.match(
    new RegExp(
      `^(?:(?:later|in)\\s+)?(?:(?:this|the)\\s+)?(?:${TIME_OF_DAY_NAMES}|eod|end of day|end of the day)$`
    )
  );
  if (!match) return null;

  const key = text
    .replace(/^(?:later|in)\s+/, '')
    .replace(/^(?:this|the)\s+/, '')
    .trim();
  return resolveTimeOfDay(key, now);
};

const matchAbsoluteDate = (text, now) => {
  const match = text.match(
    new RegExp(
      `^(${MONTH_NAMES})\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:[,\\s]+(\\d{4}|next\\s+year))?${TIME_SUFFIX_RE}$`
    )
  );
  if (!match) return null;

  const month = MONTH_MAP[match[1]];
  const day = parseInt(match[2], 10);
  let year = now.getFullYear();
  if (match[3] && /next\s+year/i.test(match[3])) {
    year = now.getFullYear() + 1;
  } else if (match[3]) {
    year = parseInt(match[3], 10);
  }

  if (match[3]) {
    const base = strictDate(year, month, day);
    if (!base) return null;
    const date = applyTimeOrDefault(base, match[4]);
    if (!date || !isAfter(date, now)) return null;
    return date;
  }
  return futureOrNextYear(year, month, day, match[4], now);
};

const matchAbsoluteDateReversed = (text, now) => {
  const match = text.match(
    new RegExp(
      `^(\\d{1,2})(?:st|nd|rd|th)?\\s+(${MONTH_NAMES})(?:[,\\s]+(\\d{4}|next\\s+year))?${TIME_SUFFIX_RE}$`
    )
  );
  if (!match) return null;

  const day = parseInt(match[1], 10);
  const month = MONTH_MAP[match[2]];
  let year = now.getFullYear();
  if (match[3] && /next\s+year/i.test(match[3])) {
    year = now.getFullYear() + 1;
  } else if (match[3]) {
    year = parseInt(match[3], 10);
  }

  if (match[3]) {
    const base = strictDate(year, month, day);
    if (!base) return null;
    const date = applyTimeOrDefault(base, match[4]);
    if (!date || !isAfter(date, now)) return null;
    return date;
  }
  return futureOrNextYear(year, month, day, match[4], now);
};

const matchMonthYear = (text, now) => {
  const match = text.match(new RegExp(`^(${MONTH_NAMES})\\s+(\\d{4})$`));
  if (!match) return null;

  const month = MONTH_MAP[match[1]];
  const year = parseInt(match[2], 10);
  const date = new Date(year, month, 1);
  if (!isValid(date)) return null;
  if (!isAfter(applyTimeToDate(date, 9, 0), now)) return null;
  return applyTimeToDate(date, 9, 0);
};

const buildDateWithOptionalTime = (year, month, day, timeStr) => {
  const date = strictDate(year, month, day);
  if (!date) return null;
  return applyTimeOrDefault(date, timeStr);
};

const TIME_SUFFIX =
  /(?:\s+(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.?|p\.m\.?)?))?$/;

const ISO_DATE_RE = new RegExp(
  `^(\\d{4})-(\\d{1,2})-(\\d{1,2})${TIME_SUFFIX.source}`
);
const SLASH_DATE_RE = new RegExp(
  `^(\\d{1,2})/(\\d{1,2})/(\\d{4})${TIME_SUFFIX.source}`
);
const DASH_DATE_RE = new RegExp(
  `^(\\d{1,2})-(\\d{1,2})-(\\d{4})${TIME_SUFFIX.source}`
);

const disambiguateDayMonth = (a, b) => {
  if (a > 12) return { day: a, month: b - 1 };
  if (b > 12) return { month: a - 1, day: b };
  return { month: a - 1, day: b };
};

const matchFormalDate = (text, now) => {
  const ensureFuture = date => {
    if (!date || !isAfter(date, now)) return null;
    return date;
  };

  let match = text.match(ISO_DATE_RE);
  if (match) {
    return ensureFuture(
      buildDateWithOptionalTime(
        parseInt(match[1], 10),
        parseInt(match[2], 10) - 1,
        parseInt(match[3], 10),
        match[4]
      )
    );
  }

  const parseAmbiguous = m => {
    const { month, day } = disambiguateDayMonth(
      parseInt(m[1], 10),
      parseInt(m[2], 10)
    );
    return ensureFuture(
      buildDateWithOptionalTime(parseInt(m[3], 10), month, day, m[4])
    );
  };

  match = text.match(SLASH_DATE_RE);
  if (match) return parseAmbiguous(match);

  match = text.match(DASH_DATE_RE);
  if (match) return parseAmbiguous(match);

  return null;
};

const matchDayAfterTomorrow = (text, now) => {
  const match = text.match(
    new RegExp(`^day\\s+after\\s+tomorrow${TIME_SUFFIX_RE}$`)
  );
  if (!match) return null;
  return applyTimeOrDefault(add(startOfDay(now), { days: 2 }), match[1]);
};

const matchThisWeekend = (text, now) => {
  if (text !== 'this weekend' && text !== 'weekend') return null;

  if (isSaturday(now)) {
    if (now.getHours() < 10) return applyTimeToDate(now, 10, 0);
    if (now.getHours() < 18) return add(now, { hours: 2 });
    return applyTimeToDate(add(startOfDay(now), { days: 1 }), 10, 0);
  }

  if (isSunday(now)) {
    if (now.getHours() < 10) return applyTimeToDate(now, 10, 0);
    return add(now, { hours: 2 });
  }

  return applyTimeToDate(nextSaturday(now), 10, 0);
};

const matchNextWeekend = (text, now) => {
  if (text !== 'next weekend') return null;
  const sat = nextSaturday(now);
  const date = isSaturday(now) || isSunday(now) ? sat : add(sat, { weeks: 1 });
  return applyTimeToDate(date, 10, 0);
};

// ─── Main Parser ─────────────────────────────────────────────────────────────

const MATCHERS = [
  matchRelativeDuration,
  matchDurationFromNow,
  matchDayAfterTomorrow,
  matchRelativeDay,
  matchNextPattern,
  matchThisWeekend,
  matchNextWeekend,
  matchTimeOfDay,
  matchWeekday,
  matchTimeOnly,
  matchAbsoluteDate,
  matchAbsoluteDateReversed,
  matchMonthYear,
  matchFormalDate,
];

/**
 * Parse a natural language English date/time string into a Date object.
 *
 * Supported patterns:
 * - Relative durations: "in 30 minutes", "in 2 hours", "in half an hour"
 * - Duration from now: "5 minutes from now", "a week from now"
 * - Relative days: "today", "tomorrow", "tomorrow morning", "tomorrow at 3pm"
 * - Day after tomorrow: "day after tomorrow", "day after tomorrow at 9am"
 * - Next patterns: "next monday", "next week", "next friday at 2pm"
 * - Weekdays: "monday", "friday at 3pm", "this wednesday"
 * - Time of day: "morning", "this afternoon", "later this evening", "eod"
 * - Time only: "at 3pm", "9:30am", "at 14:00"
 * - Weekend: "this weekend", "next weekend"
 * - Absolute dates: "jan 15", "march 5 2025", "dec 25 at 9am"
 * - Reversed dates: "15 jan", "5th march 2025"
 * - Formal dates: "01/15/2025", "2025-01-15"
 * - Month + year: "jan 2028", "december 2025"
 * - Same time: "tomorrow same time", "same time friday"
 * - Time-of-day + time: "morning 6am", "evening 7pm"
 * - Noise stripping: "remind me tomorrow", "snooze for 3 days", "approx 2 hours"
 *
 * Future-only: All matchers return dates strictly after referenceDate.
 * If a relative expression like "today at 3pm" is already past, it rolls
 * forward to the next valid occurrence (tomorrow at 3pm). This is intentional
 * for snooze/reminder use cases where past times are meaningless.
 * Zero durations ("0 days", "0 minutes") are also rejected.
 * Invalid time expressions ("at 99", "at 25", "13pm") return null.
 *
 * Timezone: All operations use the runtime's local timezone via native Date.
 * "tomorrow at 9am" means 9am in the user's browser timezone. The returned
 * unix timestamp (via getUnixTime) is UTC-correct regardless of timezone.
 *
 * @param {string} text - Natural language date/time string
 * @param {Date} [referenceDate=new Date()] - Reference date for relative calculations
 * @returns {{ date: Date, unix: number } | null} Parsed date or null if unrecognized
 */
export const parseDateFromText = (text, referenceDate = new Date()) => {
  if (!text || typeof text !== 'string') return null;

  const normalized = normalize(text);
  if (!normalized) return null;

  const maxDate = add(referenceDate, { years: 999 });

  let parsed = null;
  MATCHERS.some(matcher => {
    const result = matcher(normalized, referenceDate);
    if (
      result &&
      isValid(result) &&
      isAfter(result, referenceDate) &&
      !isBefore(maxDate, result)
    ) {
      parsed = { date: result, unix: getUnixTime(result) };
      return true;
    }
    return false;
  });

  return parsed;
};

// ─── Suggestion Candidates (uses maps already defined above) ─────────────────

const CANONICAL_UNITS = [...new Set(Object.values(UNIT_MAP))];

const MONTH_NAMES_LONG = Object.keys(MONTH_MAP).filter(k => k.length > 3);

const PHRASE_CANDIDATES = [
  ...Object.keys(RELATIVE_DAY_MAP),
  ...Object.keys(WEEKDAY_MAP).filter(k => k.length > 3),
  ...Object.keys(TIME_OF_DAY_MAP).filter(k => !k.includes(' ')),
  ...MONTH_NAMES_LONG.map(m => `${m} 1`),
  'next monday',
  'next tuesday',
  'next wednesday',
  'next thursday',
  'next friday',
  'next saturday',
  'next sunday',
  'next week',
  'next month',
  'this friday',
  'this saturday',
  'this sunday',
  'this weekend',
  'next weekend',
  'day after tomorrow',
];

const matchesPrefix = (candidate, text) => {
  if (candidate === text) return false;
  if (candidate.startsWith(text)) return true;
  const words = candidate.split(' ');
  return words.length > 1 && words.some(w => w.startsWith(text) && w !== text);
};

const buildSuggestionCandidates = text => {
  if (/^\d/.test(text)) {
    const num = text.match(/^\d+/)[0];
    return CANONICAL_UNITS.map(u => `${num} ${u}`);
  }
  return PHRASE_CANDIDATES.filter(c => matchesPrefix(c, text));
};

const MAX_SUGGESTIONS = 5;

/**
 * Generate multiple snooze date suggestions for a search prefix.
 *
 * For numeric input (e.g. "100", "2 h"), generates duration candidates
 * by appending units (minutes, hours, days, weeks, months).
 * For text input (e.g. "t", "next"), matches known phrases from the
 * parser's own maps (weekdays, relative days, time-of-day, next patterns).
 *
 * Each candidate is validated through parseDateFromText. Results are
 * deduplicated by unix timestamp and capped at 5.
 *
 * @param {string} text - Search prefix
 * @param {Date} [referenceDate=new Date()] - Reference date
 * @returns {Array<{ label: string, date: Date, unix: number }>}
 */
export const generateDateSuggestions = (text, referenceDate = new Date()) => {
  if (!text || typeof text !== 'string') return [];
  const normalized = text.trim().toLowerCase();
  if (!normalized) return [];

  const seen = new Set();
  const results = [];

  const exact = parseDateFromText(normalized, referenceDate);
  if (exact) {
    seen.add(exact.unix);
    results.push({ label: normalized, ...exact });
  }

  buildSuggestionCandidates(normalized).some(candidate => {
    if (results.length >= MAX_SUGGESTIONS) return true;

    const result = parseDateFromText(candidate, referenceDate);
    if (result && !seen.has(result.unix)) {
      seen.add(result.unix);
      results.push({ label: candidate, ...result });
    }
    return false;
  });

  return results;
};
