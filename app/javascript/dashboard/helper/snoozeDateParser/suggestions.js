/**
 * Builds autocomplete suggestions as the user types a snooze date.
 * Matches partial input against known phrases and ranks them by closeness.
 */

import {
  UNIT_MAP,
  WEEKDAY_MAP,
  TIME_OF_DAY_MAP,
  RELATIVE_DAY_MAP,
  WORD_NUMBER_MAP,
  MONTH_MAP,
  HALF_UNIT_DURATIONS,
} from './tokenMaps';

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
  ...['morning', 'afternoon', 'evening'].map(tod => `tomorrow ${tod}`),
  ...FULL_WEEKDAYS.map(wd => `next ${wd}`),
  ...FULL_WEEKDAYS.map(wd => `this ${wd}`),
  ...FULL_WEEKDAYS.flatMap(wd => TOD_NAMES.map(tod => `${wd} ${tod}`)),
  ...FULL_WEEKDAYS.flatMap(wd => TOD_NAMES.map(tod => `next ${wd} ${tod}`)),
  ...MONTH_NAMES_LONG.map(m => `${m} 1`),
];

/** Check how closely the input matches a candidate. -1 = no match, 0 = exact prefix, N = extra words needed. */
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

export const MAX_SUGGESTIONS = 5;

/** Turn user input into a ranked list of suggestion strings to try parsing. */
export const buildSuggestionCandidates = text => {
  if (!text) return [];

  if (/^\d/.test(text)) {
    const num = text.match(/^\d+(?:\.5)?/)[0];
    const candidates = SUGGESTION_UNITS.map(u => `${num} ${u}`);
    const trimmed = text.replace(/\s+/g, ' ').trim();
    const spaced = trimmed.replace(/(\d)([a-z])/i, '$1 $2');
    return spaced.length > num.length
      ? candidates.filter(c => c.startsWith(spaced))
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
