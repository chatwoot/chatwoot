// Every date and time shown to a person goes through this module, so it reads in
// the app language (the dashboard UI language, the widget locale) instead of in
// English or in the browser language. The bundles bind their vue-i18n instance
// with `bindDateLocale`; reading the bound locale inside these functions makes
// any `computed` that calls them recompute when the user switches languages.
//
// English keeps the exact date-fns output it always had. Other languages go
// through Intl, which picks the field order, the separators and the 12/24-hour
// clock from the locale: a date-fns pattern is read as the list of fields to
// show, not as a layout.
import { computed, shallowRef } from 'vue';
import {
  format,
  formatDistanceStrict,
  formatDistanceToNow,
  isSameYear,
} from 'date-fns';
import { formatTime } from '@chatwoot/utils';

const ENGLISH = 'en';

const boundLocale = shallowRef(null);

const isSupported = tag => {
  try {
    return Intl.DateTimeFormat.supportedLocalesOf([tag]).length > 0;
  } catch (error) {
    // A malformed tag ("xx_YY!") throws RangeError instead of returning [].
    return false;
  }
};

/**
 * Turns a vue-i18n locale (`pt_BR`) into a tag Intl accepts (`pt-BR`), falling
 * back to the base language and then to English when Intl does not know it.
 * @param {string} locale
 * @returns {string}
 */
export const normalizeLocale = locale => {
  if (!locale) return ENGLISH;
  const tag = String(locale).replace(/_/g, '-');
  if (isSupported(tag)) return tag;
  const base = tag.split('-')[0];
  return isSupported(base) ? base : ENGLISH;
};

const dateLocale = computed(() => normalizeLocale(boundLocale.value?.value));

/**
 * Makes this module follow the locale of a vue-i18n instance created with
 * `legacy: false`.
 * @param {import('vue-i18n').I18n} i18n
 */
export const bindDateLocale = i18n => {
  boundLocale.value = i18n.global.locale;
};

/** @returns {string} The Intl tag the formatters use right now. */
export const currentDateLocale = () => dateLocale.value;

// American English is the only locale whose output must stay byte-identical to
// the date-fns patterns. `en-GB` and friends follow their own conventions.
const isEnglish = locale => locale === ENGLISH || locale === 'en-US';

/** @returns {boolean} Whether formatting follows the English date-fns patterns. */
export const isEnglishDateLocale = () => isEnglish(dateLocale.value);

const formatters = new Map();
const cached = (key, build) => {
  if (!formatters.has(key)) formatters.set(key, build());
  return formatters.get(key);
};

/**
 * `new Intl.DateTimeFormat` in the Gregorian calendar. Every date the app
 * shows uses it: `fa` and `th` would otherwise switch to the Solar Hijri and
 * Buddhist calendars, and a month name from one calendar next to a day number
 * from the other names a day that does not exist.
 * @param {string} locale
 * @param {Intl.DateTimeFormatOptions} [options]
 * @returns {Intl.DateTimeFormat}
 */
export const dateTimeFormat = (locale, options = {}) =>
  // eslint-disable-next-line no-restricted-syntax
  new Intl.DateTimeFormat(locale, { calendar: 'gregory', ...options });

// A 24-hour locale writes midnight as 00:05, but `hour: 'numeric'` gives 0:05.
const usesTwentyFourHours = locale =>
  cached(`h24|${locale}`, () =>
    ['h23', 'h24'].includes(
      dateTimeFormat(locale, { hour: 'numeric' }).resolvedOptions().hourCycle
    )
  );

const dateTimeFormatter = (locale, options) =>
  cached(`dt|${locale}|${JSON.stringify(options)}`, () => {
    const hour =
      options.hour === 'numeric' && usesTwentyFourHours(locale)
        ? { hour: '2-digit' }
        : {};
    return dateTimeFormat(locale, { ...options, ...hour });
  });

// date-fns tokens, longest first, mapped to the Intl option they ask for. A
// pattern made of anything else (week numbers, quarters, timestamps, ISO
// offsets) is a machine format and falls back to date-fns untouched.
const TOKEN_OPTIONS = [
  [/^(yyyy|yyy|y|YYYY|Y)$/, { year: 'numeric' }],
  [/^(yy|YY)$/, { year: '2-digit' }],
  [/^(MMMMM|LLLLL)$/, { month: 'narrow' }],
  [/^(MMMM|LLLL)$/, { month: 'long' }],
  [/^(MMM|LLL)$/, { month: 'short' }],
  [/^(MM|LL)$/, { month: '2-digit' }],
  [/^(M|L)$/, { month: 'numeric' }],
  [/^dd$/, { day: '2-digit' }],
  [/^d$/, { day: 'numeric' }],
  [/^(EEEE|eeee|cccc)$/, { weekday: 'long' }],
  [/^(EEEEE|eeeee|ccccc)$/, { weekday: 'narrow' }],
  // Intl has no two-letter weekday; the short one is the closest.
  [/^(EEEEEE|eeeeee|cccccc)$/, { weekday: 'short' }],
  [/^(E|EE|EEE|eee|ccc)$/, { weekday: 'short' }],
  [/^(h|hh|H|HH|k|kk|K|KK)$/, { hour: 'numeric' }],
  [/^(m|mm)$/, { minute: '2-digit' }],
  [/^(s|ss)$/, { second: '2-digit' }],
  [/^p$/, { hour: 'numeric', minute: '2-digit' }],
  [/^P$/, { year: 'numeric', month: '2-digit', day: '2-digit' }],
  [/^PP$/, { year: 'numeric', month: 'short', day: 'numeric' }],
  [/^PPP$/, { year: 'numeric', month: 'long', day: 'numeric' }],
  [
    /^PPPP$/,
    { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' },
  ],
];
// Day period markers: the locale decides whether there is one.
const IGNORED_TOKEN = /^(a+|b+|B+)$/;

const patternOptions = new Map();

/**
 * Reads a date-fns pattern as a set of Intl options, or `null` when the
 * pattern holds a token Intl cannot express.
 * @param {string} pattern
 * @returns {Intl.DateTimeFormatOptions|null}
 */
export const intlOptionsFor = pattern => {
  if (patternOptions.has(pattern)) return patternOptions.get(pattern);
  // Quoted literals ('at') and punctuation carry no field.
  const tokens = pattern.replace(/'[^']*'/g, ' ').match(/([A-Za-z])\1*/g);
  let options = null;
  if (tokens) {
    options = {};
    const known = tokens.every(token => {
      if (IGNORED_TOKEN.test(token)) return true;
      const match = TOKEN_OPTIONS.find(([regex]) => regex.test(token));
      if (!match) return false;
      Object.assign(options, match[1]);
      return true;
    });
    if (!known || !Object.keys(options).length) options = null;
  }
  patternOptions.set(pattern, options);
  return options;
};

/**
 * Formats a date for display in the app language.
 * @param {Date|number} date - A Date or epoch milliseconds.
 * @param {string} pattern - The date-fns pattern English has always used.
 * @returns {string}
 */
export const formatLocalized = (date, pattern) => {
  const locale = dateLocale.value;
  const options = isEnglish(locale) ? null : intlOptionsFor(pattern);
  if (!options) return format(date, pattern);
  return dateTimeFormatter(locale, options).format(date);
};

/**
 * The full name of a weekday in the app language, written as a label: Intl
 * gives "domingo" in Portuguese, and a label starts with a capital.
 * @param {number} day - 0 for Sunday through 6 for Saturday, as Date#getDay.
 * @returns {string}
 */
export const weekdayName = day => {
  // Jan 7, 2024 is a Sunday, so the day number lines up with Date#getDay.
  const name = formatLocalized(new Date(2024, 0, 7 + day), 'EEEE');
  return name.charAt(0).toLocaleUpperCase(dateLocale.value) + name.slice(1);
};

/**
 * Formats a date with a fixed, language-independent pattern: API parameters,
 * file names, protocol text. Saying so here keeps machine formats apart from
 * the display ones, which the lint rule sends through `formatLocalized`.
 * @param {Date|number} date
 * @param {string} pattern
 * @returns {string}
 */
export const formatFixed = (date, pattern) => format(date, pattern);

/**
 * `formatLocalized` with the year added when the date is not in the current
 * year, so an old message still says which year it is from.
 * @param {Date} date
 * @param {string} pattern - Pattern for a date in the current year.
 * @param {string} otherYearPattern - English pattern for another year.
 * @returns {string}
 */
export const formatWithYear = (date, pattern, otherYearPattern) => {
  if (isSameYear(date, new Date())) return formatLocalized(date, pattern);
  const locale = dateLocale.value;
  if (isEnglish(locale)) return format(date, otherYearPattern);
  // The other-year pattern names every field an old date needs; a time-only
  // current-year pattern ('h:mm a') plus a year would drop the day and month.
  const options = intlOptionsFor(otherYearPattern);
  if (!options) return format(date, otherYearPattern);
  return dateTimeFormatter(locale, options).format(date);
};

/**
 * The calendar day a date custom attribute holds, as local midnight. The two
 * editors save it differently: the contact page saves UTC midnight of the day
 * (and the API accepts a bare `yyyy-MM-dd`, which parses the same way), the
 * conversation sidebar saves local midnight. Local midnight is UTC midnight
 * only at UTC+0, where both readings agree, so an instant at UTC midnight is
 * read as its UTC day and any other instant as its local day.
 * @param {string|Date} value
 * @returns {Date}
 */
export const attributeCalendarDate = value => {
  const date = new Date(value);
  const atUtcMidnight =
    date.getUTCHours() === 0 &&
    date.getUTCMinutes() === 0 &&
    date.getUTCSeconds() === 0 &&
    date.getUTCMilliseconds() === 0;
  if (!atUtcMidnight) return date;
  return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
};

/**
 * Formats the time of day on its own, with the locale's clock.
 * @param {Date|number} date
 * @returns {string}
 */
export const formatTimeOfDay = date => formatLocalized(date, 'h:mm a');

/**
 * A wall-clock time with no date (a business-hours slot), in the locale's
 * clock. Formatted at UTC so no daylight-saving gap can shift the hour.
 * @param {number} hours
 * @param {number} minutes
 * @returns {string}
 */
export const formatClockTime = (hours, minutes) =>
  dateTimeFormatter(dateLocale.value, {
    hour: 'numeric',
    minute: '2-digit',
    timeZone: 'UTC',
  }).format(Date.UTC(2000, 0, 1, hours, minutes));

// Relative times. date-fns words them in English only, and the short form the
// lists show ("5m") was derived by parsing that English. Each relative string
// produced in another language is remembered with the value and unit behind
// it, so the short form can be built from numbers instead of from words.
const MINUTE = 60;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const MONTH = 30 * DAY;
const YEAR = 365 * DAY;

/**
 * Picks the unit date-fns would use for a distance, rounding the same way.
 * @param {number} seconds - Signed distance from now, negative in the past.
 * @returns {{value: number, unit: Intl.RelativeTimeFormatUnit}}
 */
export const relativeParts = seconds => {
  const distance = Math.abs(seconds);
  const sign = seconds < 0 ? -1 : 1;
  const pick = (size, unit) => ({
    value: sign * Math.max(1, Math.round(distance / size)),
    unit,
  });
  if (distance < 45) return { value: 0, unit: 'second' };
  if (distance < 45 * MINUTE) return pick(MINUTE, 'minute');
  if (distance < DAY) return pick(HOUR, 'hour');
  if (distance < MONTH) return pick(DAY, 'day');
  if (distance < YEAR) return pick(MONTH, 'month');
  return pick(YEAR, 'year');
};

/**
 * The unit `formatDistanceStrict` picks: the largest one the distance fills,
 * never an approximation (30 seconds stays seconds, 50 minutes stays minutes).
 * @param {number} seconds
 * @returns {{value: number, unit: string}}
 */
export const strictParts = seconds => {
  const distance = Math.abs(seconds);
  const pick = (size, unit) => ({ value: Math.round(distance / size), unit });
  if (distance < MINUTE) return pick(1, 'second');
  if (distance < HOUR) return pick(MINUTE, 'minute');
  if (distance < DAY) return pick(HOUR, 'hour');
  if (distance < MONTH) return pick(DAY, 'day');
  if (distance < YEAR) return pick(MONTH, 'month');
  return pick(YEAR, 'year');
};

const relativeByText = new Map();
const MAX_REMEMBERED = 500;

const relativeFormatter = (locale, style) =>
  cached(
    `rt|${locale}|${style}`,
    () => new Intl.RelativeTimeFormat(locale, { numeric: 'auto', style })
  );

/**
 * "5 minutes ago" / "há 5 minutos", relative to now.
 * @param {Date} date
 * @returns {string}
 */
export const formatRelative = date => {
  const locale = dateLocale.value;
  if (isEnglish(locale)) return formatDistanceToNow(date, { addSuffix: true });
  const parts = relativeParts((date.getTime() - Date.now()) / 1000);
  const text = relativeFormatter(locale, 'long').format(
    parts.value,
    parts.unit
  );
  if (relativeByText.size >= MAX_REMEMBERED) relativeByText.clear();
  relativeByText.set(text, parts);
  return text;
};

/**
 * The short form of a relative time produced by `formatRelative` in a
 * language other than English: "5 min", or "há 5 min." with `withAgo`.
 * @param {string} text - What `formatRelative` returned.
 * @param {boolean} withAgo
 * @returns {string|null} `null` when the text did not come from there.
 */
export const shortRelative = (text, withAgo) => {
  const locale = dateLocale.value;
  const parts = relativeByText.get(text);
  if (isEnglish(locale) || !parts) return null;
  if (parts.value === 0 || withAgo) {
    return relativeFormatter(locale, 'narrow').format(parts.value, parts.unit);
  }
  return cached(
    `nf|${locale}|${parts.unit}`,
    () =>
      new Intl.NumberFormat(locale, {
        style: 'unit',
        unit: parts.unit,
        unitDisplay: 'narrow',
      })
  ).format(Math.abs(parts.value));
};

/**
 * Length of time between two dates ("3 minutes" / "3 minutos").
 * @param {Date} start
 * @param {Date} end
 * @returns {string}
 */
export const formatElapsed = (start, end) => {
  const locale = dateLocale.value;
  if (isEnglish(locale)) return formatDistanceStrict(start, end);
  const { value, unit } = strictParts((end - start) / 1000);
  return cached(
    `nfl|${locale}|${unit}`,
    () =>
      new Intl.NumberFormat(locale, {
        style: 'unit',
        unit,
        unitDisplay: 'long',
      })
  ).format(Math.abs(value));
};

// The two largest units of a duration, cut where @chatwoot/utils' formatTime
// cuts them, so a translated report says what the English one says.
const durationParts = seconds => {
  if (seconds >= DAY) {
    const days = Math.floor(seconds / DAY);
    const hours =
      seconds % DAY < HOUR || days >= 364
        ? 0
        : Math.floor((seconds % DAY) / HOUR);
    return [
      [days, 'day'],
      [hours, 'hour'],
    ];
  }
  if (seconds >= HOUR) {
    const hours = Math.floor(seconds / HOUR);
    const minutes =
      seconds % HOUR < MINUTE || hours === 24
        ? 0
        : Math.floor((seconds % HOUR) / MINUTE);
    return [
      [hours, 'hour'],
      [minutes, 'minute'],
    ];
  }
  if (seconds >= MINUTE) {
    const minutes = Math.floor(seconds / MINUTE);
    return [
      [minutes, 'minute'],
      [minutes === 60 ? 0 : Math.floor(seconds % MINUTE), 'second'],
    ];
  }
  return [[Math.floor(seconds), 'second']];
};

/**
 * A duration in seconds for a report ("28 Min 40 Sec" / "28 min 40 s").
 * English keeps @chatwoot/utils' formatTime output as it was.
 * @param {number} seconds
 * @returns {string}
 */
export const formatDuration = seconds => {
  const locale = dateLocale.value;
  if (isEnglish(locale)) return formatTime(seconds);
  return durationParts(seconds)
    .filter(([value], index) => index === 0 || value > 0)
    .map(([value, unit]) =>
      cached(
        `nfs|${locale}|${unit}`,
        () =>
          new Intl.NumberFormat(locale, {
            style: 'unit',
            unit,
            unitDisplay: 'short',
          })
      ).format(value)
    )
    .join(' ');
};
