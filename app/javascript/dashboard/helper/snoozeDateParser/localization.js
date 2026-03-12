/**
 * Localization module for snooze date suggestions.
 * Translates user input to English for parsing, then converts labels back to locale.
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

const EN_WEEKDAYS = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const EN_MONTHS = [
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
    TODAY: 'today',
    TONIGHT: 'tonight',
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
  ORDINALS: {
    FIRST: 'first',
    SECOND: 'second',
    THIRD: 'third',
    FOURTH: 'fourth',
    FIFTH: 'fifth',
  },
  MERIDIEM: { AM: 'am', PM: 'pm' },
  HALF: 'half',
  NEXT: 'next',
  THIS: 'this',
  AT: 'at',
  IN: 'in',
  OF: 'of',
  AFTER: 'after',
  WEEK: 'week',
  DAY: 'day',
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
  'week',
  'day',
  'first',
  'second',
  'third',
  'fourth',
  'fifth',
];

const ENGLISH_VOCAB = new Set([
  ...Object.keys(WEEKDAY_MAP),
  ...Object.keys(MONTH_MAP),
  ...Object.keys(UNIT_MAP),
  ...Object.keys(WORD_NUMBER_MAP),
  ...Object.keys(RELATIVE_DAY_MAP),
  ...Object.keys(TIME_OF_DAY_MAP),
  ...EN_WEEKDAYS,
  ...EN_MONTHS,
  ...STRUCTURAL_WORDS,
]);

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
const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const MAX_PAIRS_CACHE = 20;
const pairsCache = new Map();

const CACHE_SECTIONS = [
  'UNITS',
  'RELATIVE',
  'TIME_OF_DAY',
  'WORD_NUMBERS',
  'ORDINALS',
  'MERIDIEM',
];

const SINGLE_KEYS = [
  'HALF',
  'NEXT',
  'THIS',
  'AT',
  'IN',
  'OF',
  'AFTER',
  'WEEK',
  'DAY',
  'FROM_NOW',
  'NEXT_YEAR',
];

/** Creates a cache key from translations object. */
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

/** Builds [localWord, englishWord] pairs from translations and Intl.DateTimeFormat. */
const buildReplacementPairsUncached = (translations, locale) => {
  const pairs = [];
  const seen = new Set();
  const t = translations || {};

  const addPair = (local, en) => {
    const l = sanitize(safeString(local));
    const e = safeString(en).toLowerCase();
    const key = `${l}\0${e}`;
    if (l && e && l !== e && !seen.has(key)) {
      seen.add(key);
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
    EN_WEEKDAYS.forEach((en, i) => {
      addPair(wdFmt.format(new Date(2024, 0, i + 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  try {
    const moFmt = new Intl.DateTimeFormat(locale, { month: 'long' });
    EN_MONTHS.forEach((en, i) => {
      addPair(moFmt.format(new Date(2024, i, 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  pairs.sort((a, b) => b[0].length - a[0].length);
  return pairs;
};

/** Returns cached replacement pairs or builds new ones. */
const buildReplacementPairs = (translations, locale) => {
  const cacheKey = `${locale || ''}:${translationSignature(translations)}`;
  if (pairsCache.has(cacheKey)) return pairsCache.get(cacheKey);

  const pairs = buildReplacementPairsUncached(translations, locale);

  if (pairsCache.size >= MAX_PAIRS_CACHE) {
    pairsCache.delete(pairsCache.keys().next().value);
  }
  pairsCache.set(cacheKey, pairs);
  return pairs;
};

// ─── Token Replacement ──────────────────────────────────────────────────────

/** Replaces localized words with English equivalents. */
const substituteLocalTokens = (text, pairs) => {
  let result = text;
  pairs.forEach(([local, en]) => {
    const re = new RegExp(`(?<=^|\\s)${escapeRegex(local)}(?=\\s|$)`, 'g');
    result = result.replace(re, en);
  });
  return result;
};

/** Filters text to only English vocabulary words and numbers. */
const filterToEnglishVocab = text =>
  normalizeDigits(text)
    .replace(/(\d+)h\b/g, '$1:00')
    .split(/\s+/)
    .filter(w => /[\d:]/.test(w) || ENGLISH_VOCAB.has(w.toLowerCase()))
    .join(' ')
    .replace(/\s+/g, ' ')
    .trim();

/** Repositions "next year" after month name for proper parsing. */
const repositionNextYear = text => {
  if (!MONTH_NAME_RE.test(text)) return text;

  let result = text.replace(/\b(?:next\s+)?year\b/i, m =>
    /next/i.test(m) ? m : 'next year'
  );

  if (!/\bnext\s+year\b/i.test(result)) return result;

  const withoutNY = result.replace(/\bnext\s+year\b/i, '').trim();
  const timeRe = /(?:(?:at\s+)?\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*$/i;
  const timePart = withoutNY.match(timeRe);

  if (timePart) {
    const beforeTime = withoutNY.slice(0, timePart.index).trim();
    return `${beforeTime} next year ${timePart[0].trim()}`;
  }
  return `${withoutNY} next year`;
};

/** Translates localized input to English for the parser. */
const replaceTokens = (text, pairs) => {
  const substituted = substituteLocalTokens(text, pairs);
  const filtered = filterToEnglishVocab(substituted);
  const fixed = filtered.replace(
    NUM_TOD_RE,
    (_, t, tod) => `${t}${TOD_TO_MERIDIEM[tod]}`
  );
  return stripNoise(repositionNextYear(fixed));
};

/** Converts English words back to the user's locale for display. */
const reverseTokens = (text, pairs) => {
  const enToLocal = new Map();
  pairs.forEach(([local, en]) => {
    if (!enToLocal.has(en)) {
      enToLocal.set(en, local);
    }
  });

  return text
    .split(/(\s+)/)
    .map(token => {
      const lower = token.toLowerCase();
      return enToLocal.has(lower) ? enToLocal.get(lower) : token;
    })
    .join('');
};

// ─── Localized Suggestions ──────────────────────────────────────────────────

/** Generates localized phrase combinations (weekday + time-of-day, relative + time). */
const buildLocalizedPhrases = pairs => {
  if (!pairs.length) return [];

  const enToLocal = new Map();
  pairs.forEach(([local, en]) => {
    if (!enToLocal.has(en)) enToLocal.set(en, local);
  });

  const getLocal = en => enToLocal.get(en) || en;

  const weekdays = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ]
    .map(en => ({ en, local: getLocal(en) }))
    .filter(w => w.local !== w.en);

  const timesOfDay = ['morning', 'noon', 'afternoon', 'evening', 'night']
    .map(en => ({ en, local: getLocal(en) }))
    .filter(t => t.local !== t.en);

  const relativeDays = ['today', 'tonight', 'tomorrow']
    .map(en => ({ en, local: getLocal(en) }))
    .filter(r => r.local !== r.en);

  const phrases = [];

  weekdays.forEach(w => {
    phrases.push({ local: w.local, en: w.en });
    timesOfDay.forEach(t => {
      phrases.push({ local: `${w.local} ${t.local}`, en: `${w.en} ${t.en}` });
    });
  });

  relativeDays.forEach(r => {
    phrases.push({ local: r.local, en: r.en });
    if (r.en !== 'tonight') {
      timesOfDay
        .filter(t => t.en !== 'noon')
        .forEach(t => {
          phrases.push({
            local: `${r.local} ${t.local}`,
            en: `${r.en} ${t.en}`,
          });
        });
    }
  });

  return phrases;
};

/** Scores how well a candidate matches the search text. Returns -1 for no match. */
const matchesSearch = (candidate, search) => {
  if (candidate.startsWith(search)) return 0;
  const words = candidate.split(' ');
  const searchWords = search.split(' ');
  const allMatch = searchWords.every(sw => words.some(w => w.startsWith(sw)));
  return allMatch ? searchWords.length : -1;
};

/** Finds localized phrases matching user input. */
const buildLocalizedCandidates = (search, pairs) => {
  const phrases = buildLocalizedPhrases(pairs);
  return phrases
    .map(p => ({ ...p, score: matchesSearch(p.local, search) }))
    .filter(p => p.score >= 0)
    .sort((a, b) => a.score - b.score)
    .slice(0, MAX_SUGGESTIONS * 2);
};

// ─── Main Suggestion Generator ──────────────────────────────────────────────

/**
 * Generates snooze date suggestions from user input.
 * Supports any language when translations are provided.
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

  const directParse = parseDateFromText(stripped, referenceDate);
  const translated = pairs.length ? replaceTokens(normalized, pairs) : null;
  const translatedParse =
    translated && translated !== stripped
      ? parseDateFromText(translated, referenceDate)
      : null;

  const useTranslated = !directParse && !!translatedParse;
  const englishInput = useTranslated ? translated : stripped;

  const seen = new Set();
  const results = [];

  const exact = directParse || translatedParse;
  if (exact) {
    seen.add(exact.unix);
    const exactLabel =
      useTranslated && pairs.length
        ? reverseTokens(englishInput, pairs)
        : englishInput;
    results.push({ label: exactLabel, query: englishInput, ...exact });
  }

  if (pairs.length) {
    const localizedCandidates = buildLocalizedCandidates(stripped, pairs);

    localizedCandidates.some(({ local, en }) => {
      if (results.length >= MAX_SUGGESTIONS) return true;
      const result = parseDateFromText(en, referenceDate);
      if (result && !seen.has(result.unix)) {
        seen.add(result.unix);
        results.push({ label: local, query: en, ...result });
      }
      return false;
    });

    if (results.length) return results;
  }

  const englishCandidates = buildSuggestionCandidates(englishInput);

  englishCandidates.some(candidate => {
    if (results.length >= MAX_SUGGESTIONS) return true;
    const result = parseDateFromText(candidate, referenceDate);
    if (result && !seen.has(result.unix)) {
      seen.add(result.unix);
      const label = pairs.length ? reverseTokens(candidate, pairs) : candidate;
      results.push({ label, query: candidate, ...result });
    }
    return false;
  });

  return results;
};
