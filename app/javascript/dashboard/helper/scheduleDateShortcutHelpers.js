import {
  getDay,
  addDays,
  setHours,
  setMinutes,
  setSeconds,
  isBefore,
} from 'date-fns';
import * as chrono from 'chrono-node';

export const SHORTCUT_KEYS = {
  TOMORROW_MORNING: 'tomorrow_morning',
  TOMORROW_AFTERNOON: 'tomorrow_afternoon',
  MONDAY_MORNING: 'monday_morning',
  CUSTOM: 'custom',
};

/**
 * Normalize a locale tag to BCP 47 format (e.g. 'pt_BR' → 'pt-BR').
 */
const toBcp47 = locale => (locale || 'en').replace('_', '-');

/**
 * Get the date for "tomorrow" (always the next calendar day).
 */
export const getTomorrowDate = (now = new Date()) => {
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);
  return addDays(today, 1);
};

/**
 * Get the date for the "Monday" shortcut.
 * On Sunday, tomorrow is already Monday, so this returns next week's Monday.
 * On all other days, returns the upcoming Monday.
 */
export const getMondayDate = (now = new Date()) => {
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);
  const dayOfWeek = getDay(now); // 0=Sun, 6=Sat

  if (dayOfWeek === 0) return addDays(today, 8);
  return addDays(today, 8 - dayOfWeek);
};

/**
 * Apply an hour to a date, returning a new Date with that hour set (minutes/seconds zeroed).
 */
export const applyHour = (date, hour) =>
  setSeconds(setMinutes(setHours(new Date(date), hour), 0), 0);

/**
 * Format an hour (0-23) as a locale-aware time string (e.g. '18:00' or '6:00 PM').
 */
export const formatHour = (hour, locale = 'en') => {
  const date = new Date(2023, 0, 1, hour, 0, 0);
  return new Intl.DateTimeFormat(toBcp47(locale), {
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
};

/**
 * Format a date as a locale-aware short date with month name (e.g. '11 de mar.' / 'Mar 11').
 */
export const formatShortDate = (date, locale = 'en') =>
  new Intl.DateTimeFormat(toBcp47(locale), {
    day: 'numeric',
    month: 'short',
  }).format(date);

/**
 * Build the 3 predefined schedule shortcuts with pre-computed dates.
 * Shortcuts whose datetime is already in the past are excluded.
 */
export const getScheduleShortcuts = (now = new Date(), locale = 'en') => {
  const tomorrow = getTomorrowDate(now);
  const monday = getMondayDate(now);

  const shortcuts = [
    {
      key: SHORTCUT_KEYS.TOMORROW_MORNING,
      labelI18nKey: 'SCHEDULED_MESSAGES.MODAL.SHORTCUTS.TOMORROW_MORNING',
      date: tomorrow,
      hour: 8,
    },
    {
      key: SHORTCUT_KEYS.TOMORROW_AFTERNOON,
      labelI18nKey: 'SCHEDULED_MESSAGES.MODAL.SHORTCUTS.TOMORROW_AFTERNOON',
      date: tomorrow,
      hour: 13,
    },
    {
      key: SHORTCUT_KEYS.MONDAY_MORNING,
      labelI18nKey: 'SCHEDULED_MESSAGES.MODAL.SHORTCUTS.MONDAY_MORNING',
      date: monday,
      hour: 8,
    },
  ];

  return shortcuts
    .map(s => {
      const dateTime = applyHour(s.date, s.hour);
      const formattedDate = formatShortDate(s.date, locale);
      const formattedTime = formatHour(s.hour, locale);
      return {
        ...s,
        dateTime,
        formattedDate,
        formattedTime,
        detail: `${formattedDate}, ${formattedTime}`,
      };
    })
    .filter(s => !isBefore(s.dateTime, now));
};

/**
 * Pre-process natural language input to normalize PT/EN time expressions
 * before passing to chrono-node.
 */
export const preProcessDateInput = text => {
  let result = text;
  // PT: normalize common words typed without accents
  result = result.replace(/\bamanha\b/gi, 'amanhã');
  result = result.replace(/\bsabado\b/gi, 'sábado');
  result = result.replace(/\bproxim([ao])\b/gi, 'próxim$1');
  // PT: normalize 'as' → 'às' before digits or time-of-day words
  result = result.replace(/\bas\s+(\d)/gi, 'às $1');
  result = result.replace(/\bas\s+(manh|tard|noit)/gi, 'às $1');
  // PT: insert 'às' connector between weekday name and bare number/time
  // chrono.pt needs 'às' to link weekday + time (e.g. "quarta 10" → "quarta às 10")
  const ptWeekdays =
    '(?:segunda(?:-feira)?|ter[çc]a(?:-feira)?|quarta(?:-feira)?|quinta(?:-feira)?|sexta(?:-feira)?|s[áa]bado|domingo)';
  result = result.replace(
    new RegExp(`(${ptWeekdays})\\s+(?!às|as)(\\d)`, 'gi'),
    '$1 às $2'
  );
  // PT: 'Xh' or 'XhMM' → 'X:00' or 'X:MM' (e.g. '14h' → '14:00', '14h30' → '14:30')
  result = result.replace(
    /(\d{1,2})h(\d{2})?(?=\s|$|,)/gi,
    (_, h, min) => `${h}:${min || '00'}`
  );
  // PT: time-of-day expressions (de manhã, pela tarde, no período da noite, etc.)
  result = result.replace(
    /(?:no per[ií]odo da|pela|de|à|às)\s+manh[ãa]/gi,
    '8:00'
  );
  result = result.replace(
    /(?:no per[ií]odo da|pela|de|à|às)\s+tarde/gi,
    '13:00'
  );
  result = result.replace(
    /(?:no per[ií]odo da|pela|de|à|às)\s+noite/gi,
    '18:00'
  );
  return result;
};

/**
 * Parse a natural language date/time string using chrono-node.
 * Supports both PT and EN locales.
 * Returns a Date object if successfully parsed, otherwise null.
 */
export const parseNaturalDate = (text, locale = 'en', now = new Date()) => {
  if (!text || !text.trim()) return null;
  const processed = preProcessDateInput(text.trim());
  const opts = { forwardDate: true };
  const isPt = locale.startsWith('pt');
  const primaryResults = (isPt ? chrono.pt : chrono).parse(
    processed,
    now,
    opts
  );
  const fallbackResults = (isPt ? chrono : chrono.pt).parse(
    processed,
    now,
    opts
  );
  const matchLen = results => results.reduce((s, r) => s + r.text.length, 0);
  // Pick the parser that matched more of the input text
  const best =
    matchLen(primaryResults) >= matchLen(fallbackResults)
      ? primaryResults
      : fallbackResults;
  return best.length ? best[0].start.date() : null;
};

/**
 * Format a Date as a full locale-aware date-time string for preview display.
 * e.g. '17 de mar. de 2026, 08:00' (pt-BR) or 'Mar 17, 2026, 8:00 AM' (en)
 */
export const formatFullDateTime = (date, locale = 'en') =>
  new Intl.DateTimeFormat(toBcp47(locale), {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
