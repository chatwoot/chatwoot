import {
  getUnixTime,
  format,
  add,
  startOfWeek,
  addWeeks,
  startOfMonth,
  isMonday,
  isToday,
  isSameYear,
  setHours,
  setMinutes,
  setSeconds,
} from 'date-fns';
import wootConstants from 'dashboard/constants/globals';
import {
  generateDateSuggestions,
  parseDateFromText,
} from 'dashboard/helper/snoozeDateParser';
import { UNIT_MAP } from 'dashboard/helper/snoozeDateParser/tokenMaps';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const findStartOfNextWeek = currentDate => {
  const startOfNextWeek = startOfWeek(addWeeks(currentDate, 1));
  return isMonday(startOfNextWeek)
    ? startOfNextWeek
    : add(startOfNextWeek, {
        days: (8 - startOfNextWeek.getDay()) % 7,
      });
};

export const findStartOfNextMonth = currentDate => {
  const startOfNextMonth = startOfMonth(add(currentDate, { months: 1 }));
  return isMonday(startOfNextMonth)
    ? startOfNextMonth
    : add(startOfNextMonth, {
        days: (8 - startOfNextMonth.getDay()) % 7,
      });
};

export const findNextDay = currentDate => add(currentDate, { days: 1 });

export const setHoursToNine = date =>
  setSeconds(setMinutes(setHours(date, 9), 0), 0);

const SNOOZE_RESOLVERS = {
  [SNOOZE_OPTIONS.AN_HOUR_FROM_NOW]: d => add(d, { hours: 1 }),
  [SNOOZE_OPTIONS.UNTIL_TOMORROW]: d => setHoursToNine(findNextDay(d)),
  [SNOOZE_OPTIONS.UNTIL_NEXT_WEEK]: d => setHoursToNine(findStartOfNextWeek(d)),
  [SNOOZE_OPTIONS.UNTIL_NEXT_MONTH]: d =>
    setHoursToNine(findStartOfNextMonth(d)),
};

export const findSnoozeTime = (snoozeType, currentDate = new Date()) => {
  const resolve = SNOOZE_RESOLVERS[snoozeType];
  return resolve ? getUnixTime(resolve(currentDate)) : null;
};

export const snoozedReopenTime = snoozedUntil => {
  if (!snoozedUntil) return null;
  const date = new Date(snoozedUntil);
  if (isToday(date)) return format(date, 'h.mmaaa');
  if (!isSameYear(date, new Date())) return format(date, 'd MMM yyyy, h.mmaaa');
  return format(date, 'd MMM, h.mmaaa');
};

export const snoozedReopenTimeToTimestamp = snoozedUntil =>
  snoozedUntil ? getUnixTime(new Date(snoozedUntil)) : null;

const formatSnoozeDate = (snoozeDate, currentDate, locale = 'en') => {
  const sameYear = isSameYear(snoozeDate, currentDate);
  try {
    const opts = {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
      ...(sameYear ? {} : { year: 'numeric' }),
    };
    return new Intl.DateTimeFormat(locale, opts).format(snoozeDate);
  } catch {
    return sameYear
      ? format(snoozeDate, 'EEE, d MMM, h:mm a')
      : format(snoozeDate, 'EEE, d MMM yyyy, h:mm a');
  }
};

const expandUnit = (num, abbr) => {
  const full = UNIT_MAP[abbr];
  if (!full) return `${num} ${abbr}`;
  return parseFloat(num) === 1
    ? `${num} ${full.replace(/s$/, '')}`
    : `${num} ${full}`;
};

const capitalizeLabel = text => {
  const expanded = text
    .replace(
      /^(\d+)h(\d+)m(?:in)?$/i,
      (_, h, m) => `${expandUnit(h, 'h')} ${expandUnit(m, 'm')}`
    )
    .replace(/^(\d+(?:\.5)?)\s*([a-z]+)$/i, (_, n, u) =>
      UNIT_MAP[u.toLowerCase()] ? expandUnit(n, u.toLowerCase()) : `${n} ${u}`
    );
  return expanded.replace(/^\w/, c => c.toUpperCase());
};

export const generateSnoozeSuggestions = (
  searchText,
  currentDate = new Date(),
  { translations, locale } = {}
) => {
  const suggestions = generateDateSuggestions(searchText, currentDate, {
    translations,
    locale,
  });
  return suggestions.map(s => ({
    date: s.date,
    unixTime: s.unix,
    query: s.query,
    label: capitalizeLabel(s.label),
    formattedDate: formatSnoozeDate(s.date, currentDate, locale),
    resolve: () => parseDateFromText(s.query)?.unix ?? s.unix,
  }));
};

const UNIT_SHORT = {
  minute: 'm',
  minutes: 'm',
  hour: 'h',
  hours: 'h',
  day: 'd',
  days: 'd',
  month: 'mo',
  months: 'mo',
  year: 'y',
  years: 'y',
};

export const shortenSnoozeTime = snoozedUntil => {
  if (!snoozedUntil) return null;
  return snoozedUntil
    .replace(/^in\s+/i, '')
    .replace(
      /\s(minute|hour|day|month|year)s?\b/gi,
      (match, unit) => UNIT_SHORT[unit.toLowerCase()] || match
    );
};
