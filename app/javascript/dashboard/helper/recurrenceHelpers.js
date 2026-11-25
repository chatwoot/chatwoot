import {
  dateTimeFormat,
  formatLocalized,
  normalizeLocale,
} from 'shared/helpers/localizedDate';

// Day and month names come from Intl in the language being shown, so every
// language gets them, not only the two that once had a table here. The
// trailing dot of a short name ("sáb.") is dropped, as the labels always had.
const intlNames = (locale, options, dates) => {
  const fmt = dateTimeFormat(normalizeLocale(locale), options);
  return dates.map(date => fmt.format(date).replace(/\.$/, ''));
};

// Jan 7, 2024 is a Sunday, so index 0 to 6 lines up with Date#getDay.
const WEEK = [0, 1, 2, 3, 4, 5, 6].map(day => new Date(2024, 0, 7 + day));
const YEAR = [...Array(12).keys()].map(month => new Date(2024, month, 1));

const ORDINAL_KEYS = {
  1: 'FIRST',
  2: 'SECOND',
  3: 'THIRD',
  4: 'FOURTH',
  5: 'FIFTH',
  '-1': 'LAST',
};

export const FREQUENCY_OPTIONS = ['daily', 'weekly', 'monthly', 'yearly'];

/**
 * Get which week occurrence of a weekday a date falls on in its month,
 * and whether it is the last occurrence of that weekday in the month.
 */
export function getWeekOccurrence(date) {
  const dayOfMonth = date.getDate();
  const week = Math.ceil(dayOfMonth / 7);

  const nextWeek = new Date(date);
  nextWeek.setDate(dayOfMonth + 7);
  const isLast = nextWeek.getMonth() !== date.getMonth();

  return { week, isLast };
}

/**
 * Generate contextual recurrence shortcut options based on a selected date.
 */
export function getRecurrenceShortcuts(date) {
  if (!date) return [];

  const dayOfWeek = date.getDay();
  const { week, isLast } = getWeekOccurrence(date);

  return [
    {
      label: 'NO_REPEAT',
      value: null,
    },
    {
      label: 'DAILY',
      value: {
        frequency: 'daily',
        interval: 1,
        end_type: 'never',
      },
    },
    {
      label: 'WEEKLY',
      labelParams: { day: dayOfWeek },
      value: {
        frequency: 'weekly',
        interval: 1,
        week_days: [dayOfWeek],
        end_type: 'never',
      },
    },
    {
      label: isLast ? 'MONTHLY_LAST' : 'MONTHLY_NTH',
      labelParams: {
        nth: isLast ? -1 : week,
        day: dayOfWeek,
      },
      value: {
        frequency: 'monthly',
        interval: 1,
        monthly_type: 'day_of_week',
        monthly_week: isLast ? -1 : week,
        monthly_weekday: dayOfWeek,
        end_type: 'never',
      },
    },
    {
      label: 'YEARLY',
      labelParams: {
        month: date.getMonth(),
        dayNum: date.getDate(),
      },
      value: {
        frequency: 'yearly',
        interval: 1,
        year_day: date.getDate(),
        year_month: date.getMonth() + 1,
        end_type: 'never',
      },
    },
    {
      label: 'WEEKDAYS',
      value: {
        frequency: 'weekly',
        interval: 1,
        week_days: [1, 2, 3, 4, 5],
        end_type: 'never',
      },
    },
    {
      label: 'CUSTOM',
      value: 'custom',
    },
  ];
}

function getWeekdayNames(locale) {
  return intlNames(locale, { weekday: 'long' }, WEEK);
}

function getWeekdayShortNames(locale) {
  return intlNames(locale, { weekday: 'short' }, WEEK);
}

function getOrdinal(nth, t) {
  const key = ORDINAL_KEYS[String(nth)];
  return key ? t(`SCHEDULED_MESSAGES.RECURRENCE.ORDINALS.${key}`) : nth;
}

function getMonthNames(locale) {
  return intlNames(locale, { month: 'long' }, YEAR);
}

// The end date is a calendar day ("2026-12-20"); read it as local midnight.
function formatEndDate(endDate) {
  const [year, month, day] = endDate.split('-').map(Number);
  return formatLocalized(new Date(year, month - 1, day), 'MMM d, yyyy');
}

/**
 * Build a human-readable description of a recurrence rule.
 */
export function buildRecurrenceDescription(rule, t, locale = 'en') {
  if (!rule || !rule.frequency) return '';

  const weekdayShortNames = getWeekdayShortNames(locale);
  const weekdayNames = getWeekdayNames(locale);
  const descKey = key => `SCHEDULED_MESSAGES.RECURRENCE.DESCRIPTION.${key}`;

  const intervalDesc = (interval, oneKey, otherKey) => {
    if (interval === 1) return t(descKey(oneKey));
    return t(descKey(otherKey), { count: interval });
  };

  let description = '';

  switch (rule.frequency) {
    case 'daily':
      description = intervalDesc(
        rule.interval || 1,
        'DAILY_ONE',
        'DAILY_OTHER'
      );
      break;

    case 'weekly': {
      const days = (rule.week_days || [])
        .sort((a, b) => a - b)
        .map(d => weekdayShortNames[d]);
      const prefix = intervalDesc(
        rule.interval || 1,
        'WEEKLY_ONE',
        'WEEKLY_OTHER'
      );
      description = days.length
        ? t(descKey('WEEKLY_ON'), { prefix, days: days.join(', ') })
        : prefix;
      break;
    }

    case 'monthly': {
      const prefix = intervalDesc(
        rule.interval || 1,
        'MONTHLY_ONE',
        'MONTHLY_OTHER'
      );
      if (rule.monthly_type === 'day_of_week') {
        const ordinal = getOrdinal(rule.monthly_week, t);
        const weekday = weekdayNames[rule.monthly_weekday] || '';
        description = t(descKey('MONTHLY_ON_WEEKDAY'), {
          prefix,
          ordinal,
          weekday,
        });
      } else {
        description = prefix;
      }
      break;
    }

    case 'yearly':
      description = intervalDesc(
        rule.interval || 1,
        'YEARLY_ONE',
        'YEARLY_OTHER'
      );
      break;

    default:
      return '';
  }

  if (rule.end_type === 'on_date' && rule.end_date) {
    description += ` · ${t(descKey('UNTIL_DATE'), {
      date: formatEndDate(rule.end_date),
    })}`;
  } else if (rule.end_type === 'after_count' && rule.end_count) {
    description += ` · ${t(descKey('AFTER_COUNT'), { count: rule.end_count })}`;
  }

  return description;
}

/**
 * Format a shortcut label with its parameters for display.
 */
export function formatShortcutLabel(shortcut, t, locale = 'en') {
  const { label, labelParams } = shortcut;
  const weekdayNames = getWeekdayNames(locale);
  const monthNames = getMonthNames(locale);

  if (!labelParams) return t(`SCHEDULED_MESSAGES.RECURRENCE.${label}`);

  const params = {};
  if (labelParams.day !== undefined) {
    params.day = weekdayNames[labelParams.day];
  }
  if (labelParams.nth !== undefined) {
    params.nth = getOrdinal(labelParams.nth, t);
  }
  if (labelParams.month !== undefined) {
    params.month = monthNames[labelParams.month];
  }
  if (labelParams.dayNum !== undefined) {
    params.dayNum = labelParams.dayNum;
  }

  return t(`SCHEDULED_MESSAGES.RECURRENCE.${label}`, params);
}
