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
import { dateTimeFormat } from 'shared/helpers/localizedDate';

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
  ...EN_WEEKDAYS_LIST,
  ...EN_MONTHS_LIST,
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
const CJK_CHAR_RE =
  /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/u;

// ─── Translation Cache ──────────────────────────────────────────────────────

const safeString = v => (v == null ? '' : String(v));
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

const LATIN_RE = /^[\p{Script=Latin}\s'-]+$/u;
const stripAccents = s =>
  s.normalize('NFD').replace(/\p{M}/gu, '').normalize('NFC');

// Intl gives the formal long name ("sexta-feira", "dezembro"), but people type
// the short one ("sex", "dez") and, where the long name is a compound, its
// first part ("sexta"). Short forms under three letters are left out: they
// collide with ordinary words ("do", "so").
const MIN_NAME_FORM = 3;
const nameForms = (longFmt, shortFmt, date) => {
  const long = sanitize(longFmt.format(date));
  const short = sanitize(shortFmt.format(date)).replace(/\.$/, '');
  const extra = [short];
  if (long.includes('-')) extra.push(long.split('-')[0]);
  return [long, ...extra.filter(f => f.length >= MIN_NAME_FORM)];
};

// A translation names one gender of a word ("próximo", "este"), and the other
// one ("próxima sexta", "esta semana") is just as common.
const INFLECTIONS = { o: 'a', a: 'o', e: 'a' };
const MIN_INFLECTED = 4;

/** Build the [localWord, englishWord] pairs from the translations and browser locale, plus every localized day and month form. */
const buildReplacementPairsUncached = (translations, locale) => {
  const pairs = [];
  const seen = new Set();
  const dateForms = new Set();
  const t = translations || {};

  const addPair = (local, en) => {
    const l = sanitize(safeString(local));
    const e = safeString(en).toLowerCase();
    [l, LATIN_RE.test(l) ? stripAccents(l) : l].forEach(form => {
      const key = `${form}\0${e}`;
      if (form && e && form !== e && !seen.has(key)) {
        seen.add(key);
        pairs.push([form, e]);
      }
    });
  };

  const addDateName = (forms, en) =>
    forms.forEach(form => {
      addPair(form, en);
      dateForms.add(stripAccents(form));
    });

  CACHE_SECTIONS.forEach(section => {
    const localSection = t[section] || {};
    const enSection = EN_DEFAULTS[section] || {};
    Object.keys(enSection).forEach(key => {
      addPair(localSection[key], enSection[key]);
    });
  });

  SINGLE_KEYS.forEach(key => addPair(t[key], EN_DEFAULTS[key]));

  try {
    const longFmt = dateTimeFormat(locale, { weekday: 'long' });
    const shortFmt = dateTimeFormat(locale, { weekday: 'short' });
    // Jan 1, 2024 is a Monday — aligns with EN_WEEKDAYS_LIST[0]='monday'
    EN_WEEKDAYS_LIST.forEach((en, i) => {
      addDateName(nameForms(longFmt, shortFmt, new Date(2024, 0, i + 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  try {
    const longFmt = dateTimeFormat(locale, { month: 'long' });
    const shortFmt = dateTimeFormat(locale, { month: 'short' });
    EN_MONTHS_LIST.forEach((en, i) => {
      addDateName(nameForms(longFmt, shortFmt, new Date(2024, i, 1)), en);
    });
  } catch {
    /* locale not supported */
  }

  // Added last, so a word that already means something else ("segunda" is a
  // weekday before it is the feminine of "segundo") keeps that meaning.
  const locals = new Set(pairs.map(([l]) => l));
  [...pairs].forEach(([local, en]) => {
    const swap = INFLECTIONS[local.slice(-1)];
    if (!swap || local.length < MIN_INFLECTED || !LATIN_RE.test(local)) return;
    if (local.includes(' ')) return;
    const variant = local.slice(0, -1) + swap;
    if (!locals.has(variant)) {
      locals.add(variant);
      pairs.push([variant, en]);
    }
  });

  pairs.sort((a, b) => b[0].length - a[0].length);

  // One local word can name two things ("mar" is Tuesday and March in
  // Spanish, "dez" is ten and December in Portuguese); the reading that parses
  // is chosen per input, in `translations` below.
  const meanings = new Map();
  pairs.forEach(([local, en]) => {
    if (!local.includes(' '))
      meanings.set(local, [...(meanings.get(local) || []), en]);
  });
  const ambiguous = new Map([...meanings].filter(([, ens]) => ens.length > 1));
  return { pairs, dateForms: [...dateForms], ambiguous };
};

/** Same as above but cached. Keeps up to 20 entries to avoid rebuilding every call. */
const buildReplacementPairs = (translations, locale) => {
  const cacheKey = `${locale || ''}:${translationSignature(translations)}`;
  if (pairsCache.has(cacheKey)) return pairsCache.get(cacheKey);
  const built = buildReplacementPairsUncached(translations, locale);
  if (pairsCache.size >= MAX_PAIRS_CACHE)
    pairsCache.delete(pairsCache.keys().next().value);
  pairsCache.set(cacheKey, built);
  return built;
};

// ─── Token Replacement ──────────────────────────────────────────────────────

const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Swap localized words for their English versions in the text. */
const substituteLocalTokens = (text, pairs) => {
  let r = text;
  pairs.forEach(([local, en]) => {
    if (CJK_CHAR_RE.test(local)) {
      const re = new RegExp(escapeRegex(local), 'g');
      r = r.replace(re, ` ${en} `);
    } else {
      const re = new RegExp(`(?<=^|\\s)${escapeRegex(local)}(?=\\s|$)`, 'g');
      r = r.replace(re, en);
    }
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

/**
 * A leftover word that starts like a day or month name ("sextaa", "dezembroo")
 * is a date the user wrote and we could not read. Dropping it would quietly
 * turn "sextaa 9h" into tomorrow at 9.
 */
// A three-letter short form is the start of ordinary words too ("marcar" starts
// like "mar", March in Spanish), so only a longer name counts as the stem of a
// misspelled one.
const MIN_TYPO_STEM = 4;
const dropsDateWord = (text, dateForms) =>
  text
    .split(/\s+/)
    .filter(w => w && !/[\d:]/.test(w) && !ENGLISH_VOCAB.has(w))
    .map(stripAccents)
    .some(w =>
      dateForms.some(
        form =>
          (form.length >= MIN_TYPO_STEM && w.startsWith(form)) ||
          (w.length >= MIN_NAME_FORM && form.startsWith(w))
      )
    );

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
const replaceTokens = (text, { pairs, dateForms }) => {
  const substituted = substituteLocalTokens(text, pairs);
  if (dropsDateWord(substituted, dateForms)) return null;
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
  const replacements =
    locale && locale !== 'en'
      ? buildReplacementPairs(translations, locale)
      : { pairs: [], dateForms: [], ambiguous: new Map() };

  // Try English parse first, then translated parse if we have locale pairs.
  // This avoids the problem where a single overlapping word (e.g. "in" in German)
  // would skip token translation entirely.
  const directParse = parseDateFromText(stripped, referenceDate);

  // Every reading of the ambiguous words the input holds, in the order the
  // pairs list them (translations, then weekdays, then months); the first one
  // that parses wins, and the first one stands in when none does.
  const words = new Set(normalized.split(/\s+/));
  const readings = [...replacements.ambiguous]
    .filter(([local]) => words.has(local))
    .reduce(
      (options, [local, ens]) =>
        options.flatMap(option =>
          ens.map(en => option.filter(([l, e]) => l !== local || e === en))
        ),
      [replacements.pairs]
    );
  const attempts = replacements.pairs.length
    ? readings.map(option => {
        const reading = replaceTokens(normalized, {
          ...replacements,
          pairs: option,
        });
        const parsed =
          reading && reading !== stripped
            ? parseDateFromText(reading, referenceDate)
            : null;
        return { pairs: option, text: reading, parsed };
      })
    : [];
  const chosen = attempts.find(attempt => attempt.parsed) || attempts[0];
  const pairs = chosen?.pairs || [];
  const translated = chosen?.text ?? null;
  const translatedParse = chosen?.parsed ?? null;

  // Prefer direct English parse; fall back to translated parse
  const useTranslated = !directParse && !!translatedParse;
  const englishInput = useTranslated ? translated : stripped;

  const seen = new Set();
  const results = [];

  const exact = directParse || translatedParse;
  if (exact) {
    seen.add(exact.unix);
    // What the user typed is already in their language and agrees with
    // itself; rebuilding it from the English tokens gives "próximo sexta-feira".
    const exactLabel = useTranslated ? normalized : englishInput;
    results.push({ label: exactLabel, query: englishInput, ...exact });
  }

  buildSuggestionCandidates(englishInput).some(candidate => {
    if (results.length >= MAX_SUGGESTIONS) return true;
    const result = parseDateFromText(candidate, referenceDate);
    if (result && !seen.has(result.unix)) {
      seen.add(result.unix);
      const label =
        useTranslated && pairs.length
          ? reverseTokens(candidate, pairs)
          : candidate;
      results.push({ label, query: candidate, ...result });
    }
    return false;
  });

  return results;
};
