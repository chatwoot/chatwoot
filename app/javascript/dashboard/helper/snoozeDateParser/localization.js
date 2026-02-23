/**
 * Handles non-English input and generates the final suggestion list.
 * Translates localized words to English before parsing, then converts
 * suggestion labels back to the user's language for display.
 */

import {
  WEEKDAY_MAP,
  MONTH_MAP,
  UNIT_MAP,
  WORD_NUMBER_MAP,
  RELATIVE_DAY_MAP,
  TIME_OF_DAY_MAP,
  sanitize,
  stripNoise,
  normalizeDigits,
} from './tokenMaps';

import { parseDateFromText } from './parser';
import { buildSuggestionCandidates, MAX_SUGGESTIONS } from './suggestions';

// ─── English Reference Data ─────────────────────────────────────────────────

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

// ─── Regex for token replacement ────────────────────────────────────────────

const MONTH_NAMES = Object.keys(MONTH_MAP).join('|');
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

// ─── Translation Cache ──────────────────────────────────────────────────────

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

/** Create a string key from translations so we can cache results. */
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

/** Build a list of [localWord, englishWord] pairs from the translations and browser locale. */
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

/** Same as above but cached. Keeps up to 20 entries to avoid rebuilding every call. */
const buildReplacementPairs = (translations, locale) => {
  const cacheKey = `${locale || ''}:${translationSignature(translations)}`;
  if (pairsCache.has(cacheKey)) return pairsCache.get(cacheKey);
  const pairs = buildReplacementPairsUncached(translations, locale);
  if (pairsCache.size >= MAX_PAIRS_CACHE)
    pairsCache.delete(pairsCache.keys().next().value);
  pairsCache.set(cacheKey, pairs);
  return pairs;
};

// ─── Token Replacement ──────────────────────────────────────────────────────

const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Swap localized words for their English versions in the text. */
const substituteLocalTokens = (text, pairs) => {
  let r = text;
  pairs.forEach(([local, en]) => {
    const re = new RegExp(`(?<=^|\\s)${escapeRegex(local)}(?=\\s|$)`, 'g');
    r = r.replace(re, en);
  });
  return r;
};

/** Drop any words the parser wouldn't understand (keeps English words and numbers). */
const filterToEnglishVocab = text =>
  normalizeDigits(text)
    .replace(/(\d+)h\b/g, '$1:00')
    .split(/\s+/)
    .filter(w => /[\d:]/.test(w) || ENGLISH_VOCAB.has(w.toLowerCase()))
    .join(' ')
    .replace(/\s+/g, ' ')
    .trim();

/** Move "next year" to the right spot so the parser can read it (after the month, before time). */
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

/** Run the full translation pipeline: swap tokens, filter, fix am/pm, reposition "next year". */
const replaceTokens = (text, pairs) => {
  const substituted = substituteLocalTokens(text, pairs);
  const filtered = filterToEnglishVocab(substituted);
  const fixed = filtered.replace(
    NUM_TOD_RE,
    (_, t, tod) => `${t}${TOD_TO_MERIDIEM[tod]}`
  );
  return stripNoise(repositionNextYear(fixed));
};

/** Convert English words back to the user's language for display. */
const reverseTokens = (text, pairs) =>
  pairs.reduce(
    (r, [local, en]) =>
      r.replace(
        new RegExp(`(?<=^|\\s)${escapeRegex(en)}(?=\\s|$)`, 'g'),
        local
      ),
    text
  );

// ─── Main Suggestion Generator ──────────────────────────────────────────────

/**
 * Generate snooze suggestions from what the user has typed so far.
 * Works with any language if translations are provided. Returns up to 5
 * unique results, each with a label, date, and unix timestamp.
 *
 * @param {string} text - what the user typed
 * @param {Date} [referenceDate] - treat as "now" (defaults to current time)
 * @param {{ translations?: object, locale?: string }} [options] - i18n config
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
