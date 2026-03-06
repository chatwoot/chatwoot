/**
 * Parses natural language text into a future date.
 *
 * Flow: clean the input → try each matcher in order → return the first future date.
 * The MATCHERS order matters — see the comment above the array.
 */

import {
  add,
  startOfDay,
  getDay,
  isSaturday,
  isSunday,
  nextFriday,
  nextSaturday,
  getUnixTime,
  isValid,
  startOfWeek,
  addWeeks,
  isAfter,
  isBefore,
  endOfMonth,
} from 'date-fns';

import {
  WEEKDAY_MAP,
  MONTH_MAP,
  RELATIVE_DAY_MAP,
  UNIT_MAP,
  WORD_NUMBER_MAP,
  NEXT_WEEKDAY_FN,
  TIME_OF_DAY_MAP,
  TOD_HOUR_RANGE,
  HALF_UNIT_DURATIONS,
  sanitize,
  stripNoise,
  parseNumber,
  parseTimeString,
  applyTimeToDate,
  applyTimeOrDefault,
  strictDate,
  futureOrNextYear,
  ensureFutureOrNextDay,
  inferHoursFromTOD,
  addFractionalSafe,
} from './tokenMaps';

// ─── Regex Fragments (derived from maps) ────────────────────────────────────

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

const ORDINAL_MAP = {
  first: 1,
  second: 2,
  third: 3,
  fourth: 4,
  fifth: 5,
  sixth: 6,
  seventh: 7,
  eighth: 8,
  ninth: 9,
  tenth: 10,
};
const parseOrdinal = str => {
  if (ORDINAL_MAP[str]) return ORDINAL_MAP[str];
  return parseInt(str.replace(/(?:st|nd|rd|th)$/, ''), 10) || null;
};
const ORDINAL_WORDS = Object.keys(ORDINAL_MAP).join('|');
const ORDINAL_RE = `(\\d{1,2}(?:st|nd|rd|th)?|${ORDINAL_WORDS})`;

// ─── Pre-compiled Regexes ───────────────────────────────────────────────────

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
  `^(?:(${RELATIVE_DAYS})\\s+(?:same\\s+time|this\\s+time)|(?:same\\s+time|this\\s+time)\\s+(${RELATIVE_DAYS}))$`
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
// "april first week", "first week of april", "march 2nd day", "5th day of jan"
const MONTH_ORDINAL_RE = new RegExp(
  `^(?:(${MONTH_NAMES})\\s+${ORDINAL_RE}\\s+(week|day)|${ORDINAL_RE}\\s+(week|day)\\s+of\\s+(${MONTH_NAMES}))${TIME_SUFFIX_RE}$`
);
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
const END_OF_NEXT_RE = /^end\s+of\s+(?:the\s+)?next\s+(week|month)$/;
const START_OF_NEXT_RE =
  /^(?:beginning|start)\s+of\s+(?:the\s+)?next\s+(week|month)$/;
const LATER_TODAY_RE = /^later\s+(?:today|this\s+(?:afternoon|evening))$/;
const EARLY_LATE_TOD_RE = new RegExp(
  `^(early|late)\\s+(${TIME_OF_DAY_NAMES})$`
);
const ONE_AND_HALF_RE = new RegExp(
  `^(?:in\\s+)?(?:one\\s+and\\s+(?:a\\s+)?half|an?\\s+hour\\s+and\\s+(?:a\\s+)?half)(?:\\s+${UNIT_RE})?$`
);
const NEXT_BUSINESS_DAY_RE = /^next\s+(?:business|working)\s+day$/;

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

// ─── Pattern Matchers ───────────────────────────────────────────────────────

/** Read amount and unit from a regex match, then add to now. */
const parseDuration = (match, now) => {
  if (!match) return null;
  const amount = parseNumber(match[1]);
  const unit = UNIT_MAP[match[2]];
  if (amount == null || !unit) return null;
  return addFractionalSafe(now, unit, amount);
};

/** Handle "in 2 hours", "half day", "3h30m", "5 min from now". */
const matchDuration = (text, now) => {
  const half = text.match(HALF_UNIT_RE);
  if (half) {
    return HALF_UNIT_DURATIONS[half[1]]
      ? add(now, HALF_UNIT_DURATIONS[half[1]])
      : null;
  }

  // "one and a half hours", "an hour and a half"
  const oneHalf = text.match(ONE_AND_HALF_RE);
  if (oneHalf) {
    const unit = UNIT_MAP[oneHalf[1]] || 'hours';
    return addFractionalSafe(now, unit, 1.5);
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

/** Set time on a day offset. If the result is already past, move to the next day. */
const applyTimeWithRollover = (offset, hours, minutes, now) => {
  const base = add(startOfDay(now), { days: offset });
  const date = applyTimeToDate(base, hours, minutes);
  if (isAfter(date, now)) return date;
  return applyTimeToDate(add(base, { days: 1 }), hours, minutes);
};

/** Handle "today", "tonight", "tomorrow" with optional time. */
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
    const [, dayKey, timeRaw] = dayAtTimeMatch;
    const bare = /^(tonight|tonite)$/.test(dayKey) && !/[ap]m/i.test(timeRaw);
    const time = bare
      ? inferHoursFromTOD('tonight', ...timeRaw.split(':'))
      : parseTimeString(timeRaw);
    if (!time) return null;
    return applyTimeWithRollover(
      RELATIVE_DAY_MAP[dayKey],
      time.hours,
      time.minutes,
      now
    );
  }

  const sameTimeMatch = text.match(RELATIVE_DAY_SAME_TIME_RE);
  if (sameTimeMatch) {
    const offset = RELATIVE_DAY_MAP[sameTimeMatch[1] || sameTimeMatch[2]];
    if (offset <= 0) return null;
    return applyTimeToDate(
      add(startOfDay(now), { days: offset }),
      now.getHours(),
      now.getMinutes()
    );
  }

  return null;
};

/** Find the given weekday in next week (not this week). */
const nextWeekdayInNextWeek = (dayIndex, now) => {
  const fn = NEXT_WEEKDAY_FN[dayIndex];
  if (!fn) return null;
  const date = fn(now);
  const sameWeek =
    startOfWeek(now, { weekStartsOn: 1 }).getTime() ===
    startOfWeek(date, { weekStartsOn: 1 }).getTime();
  return sameWeek ? fn(date) : date;
};

/** Handle "next friday", "next week", "next month", "next january", etc. */
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

/** Find the next occurrence of a weekday, with optional time. */
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

/** Handle "friday", "monday 3pm", "wed morning", "same time friday". */
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

/** Handle a standalone time like "3pm", "14:30", "at 9am". */
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

/** Handle "morning", "evening 6pm", "eod", "this afternoon". */
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

  // "early morning" → 7am, "late evening" → 21:00, "late night" → 23:00
  const earlyLate = text.match(EARLY_LATE_TOD_RE);
  if (earlyLate) {
    const tod = TIME_OF_DAY_MAP[earlyLate[2]];
    if (!tod) return null;
    const shift = earlyLate[1] === 'early' ? -1 : 2;
    return ensureFutureOrNextDay(
      applyTimeToDate(now, tod.hours + shift, 0),
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

/** Turn month + day + optional year into a future date. */
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

/** Handle "jan 15", "15 march", "december 2025". */
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

  // "april first week", "first week of april", "march 2nd day", etc.
  const mo = text.match(MONTH_ORDINAL_RE);
  if (mo) {
    // Groups: (1)month-A (2)ordinal-A (3)unit-A | (4)ordinal-B (5)unit-B (6)month-B (7)time
    const monthIdx = MONTH_MAP[mo[1] || mo[6]];
    const num = parseOrdinal(mo[2] || mo[4]);
    const unit = mo[3] || mo[5];
    const timeStr = mo[7];

    if (!num || num < 1) return null;

    if (unit === 'day') {
      if (num > 31) return null;
      return resolveAbsoluteDate(monthIdx, num, null, timeStr, now);
    }

    // unit === 'week'
    if (num > 5) return null;
    const weekStartDay = (num - 1) * 7 + 1;
    let year = now.getFullYear();
    if (
      monthIdx < now.getMonth() ||
      (monthIdx === now.getMonth() && now.getDate() > weekStartDay)
    ) {
      year += 1;
    }
    // Reject if weekStartDay overflows the month (e.g. feb fifth week = day 29 in non-leap)
    const daysInMonth = new Date(year, monthIdx + 1, 0).getDate();
    if (weekStartDay > daysInMonth) return null;
    const d = new Date(year, monthIdx, weekStartDay);
    if (!isValid(d)) return null;
    const result = applyTimeOrDefault(d, timeStr);
    return result && isAfter(result, now) ? result : null;
  }

  return null;
};

/** Build a date from year/month/day numbers, with optional time. */
const buildDateWithOptionalTime = (year, month, day, timeStr) => {
  const date = strictDate(year, month, day);
  if (!date) return null;
  return applyTimeOrDefault(date, timeStr);
};

// When both values are ≤ 12 (ambiguous), dayFirst controls the fallback:
//   dayFirst=false (slash M/D/Y) → month first
//   dayFirst=true  (dash/dot D-M-Y, D.M.Y) → day first
const disambiguateDayMonth = (a, b, dayFirst = false) => {
  if (a > 12) return { day: a, month: b - 1 };
  if (b > 12) return { month: a - 1, day: b };
  return dayFirst ? { day: a, month: b - 1 } : { month: a - 1, day: b };
};

/** Handle formal dates: "2025-01-15", "1/15/2025", "15.01.2025". */
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

  // Slash = M/D/Y (US), Dash/Dot = D-M-Y / D.M.Y (European)
  const formats = [
    { re: SLASH_DATE_RE, dayFirst: false },
    { re: DASH_DATE_RE, dayFirst: true },
    { re: DOT_DATE_RE, dayFirst: true },
  ];
  let result = null;
  formats.some(({ re, dayFirst }) => {
    const m = text.match(re);
    if (!m) return false;
    const { month, day } = disambiguateDayMonth(
      parseInt(m[1], 10),
      parseInt(m[2], 10),
      dayFirst
    );
    result = ensureFuture(
      buildDateWithOptionalTime(parseInt(m[3], 10), month, day, m[4])
    );
    return true;
  });
  return result;
};

/** Handle "day after tomorrow", "end of week", "this weekend", "later today". */
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

  // "end of next week", "end of next month"
  const eofNext = text.match(END_OF_NEXT_RE);
  if (eofNext) {
    if (eofNext[1] === 'week') {
      const nextWeekStart = startOfWeek(addWeeks(now, 1), { weekStartsOn: 1 });
      return applyTimeToDate(add(nextWeekStart, { days: 4 }), 17, 0);
    }
    if (eofNext[1] === 'month') {
      return applyTimeToDate(endOfMonth(add(now, { months: 1 })), 17, 0);
    }
  }

  // "beginning of next week", "start of next month"
  const sofNext = text.match(START_OF_NEXT_RE);
  if (sofNext) {
    if (sofNext[1] === 'week') {
      return applyTimeToDate(
        startOfWeek(addWeeks(now, 1), { weekStartsOn: 1 }),
        9,
        0
      );
    }
    if (sofNext[1] === 'month') {
      const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
      return applyTimeToDate(nextMonth, 9, 0);
    }
  }

  // "next business day", "next working day"
  if (NEXT_BUSINESS_DAY_RE.test(text)) {
    let d = add(startOfDay(now), { days: 1 });
    while (isSaturday(d) || isSunday(d)) d = add(d, { days: 1 });
    return applyTimeToDate(d, 9, 0);
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

// ─── Main Parser ────────────────────────────────────────────────────────────

// Order matters — first match wins. Common patterns go first.
// Do not reorder without running the spec.
const MATCHERS = [
  matchDuration, //    "in 2 hours", "half day", "3h30m"
  matchSpecial, //     "end of week", "later today", "this weekend"
  matchRelativeDay, // "tomorrow 3pm", "tonight", "today morning"
  matchNextPattern, // "next friday", "next week", "next month"
  matchTimeOfDay, //   "morning", "evening 6pm", "eod"
  matchWeekday, //     "friday", "monday 3pm", "wed morning"
  matchTimeOnly, //    "3pm", "14:30" (must be after weekday to avoid conflicts)
  matchNamedDate, //   "jan 15", "march 20 next year"
  matchFormalDate, //  "2025-01-15", "1/15/2025" (least common, last)
];

/**
 * Parse free-form text into a future date.
 * Returns { date, unix } or null. Only returns dates after referenceDate.
 *
 * @param {string} text - user input like "in 2 hours" or "next friday 3pm"
 * @param {Date} [referenceDate] - treat as "now" (defaults to current time)
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
