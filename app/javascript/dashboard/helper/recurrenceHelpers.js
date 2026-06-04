const WEEKDAY_NAMES_EN = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const WEEKDAY_NAMES_PT = [
  'domingo',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
];

const WEEKDAY_NAMES_SHORT_EN = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

const WEEKDAY_NAMES_SHORT_PT = [
  'dom',
  'seg',
  'ter',
  'qua',
  'qui',
  'sex',
  'sáb',
];

const ORDINALS_EN = {
  1: 'first',
  2: 'second',
  3: 'third',
  4: 'fourth',
  5: 'fifth',
  '-1': 'last',
};

const ORDINALS_PT = {
  1: '1º',
  2: '2º',
  3: '3º',
  4: '4º',
  5: '5º',
  '-1': 'último(a)',
};

const MONTH_NAMES_EN = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const MONTH_NAMES_PT = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

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
  return locale?.startsWith('pt') ? WEEKDAY_NAMES_PT : WEEKDAY_NAMES_EN;
}

function getWeekdayShortNames(locale) {
  return locale?.startsWith('pt')
    ? WEEKDAY_NAMES_SHORT_PT
    : WEEKDAY_NAMES_SHORT_EN;
}

function getOrdinals(locale) {
  return locale?.startsWith('pt') ? ORDINALS_PT : ORDINALS_EN;
}

function getMonthNames(locale) {
  return locale?.startsWith('pt') ? MONTH_NAMES_PT : MONTH_NAMES_EN;
}

/**
 * Build a human-readable description of a recurrence rule.
 */
export function buildRecurrenceDescription(rule, t, locale = 'en') {
  if (!rule || !rule.frequency) return '';

  const weekdayShortNames = getWeekdayShortNames(locale);
  const weekdayNames = getWeekdayNames(locale);
  const ordinals = getOrdinals(locale);
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
        const ordinal =
          ordinals[String(rule.monthly_week)] || rule.monthly_week;
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
    description += ` · ${t(descKey('UNTIL_DATE'), { date: rule.end_date })}`;
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
  const ordinals = getOrdinals(locale);
  const monthNames = getMonthNames(locale);

  if (!labelParams) return t(`SCHEDULED_MESSAGES.RECURRENCE.${label}`);

  const params = {};
  if (labelParams.day !== undefined) {
    params.day = weekdayNames[labelParams.day];
  }
  if (labelParams.nth !== undefined) {
    params.nth = ordinals[String(labelParams.nth)] || labelParams.nth;
  }
  if (labelParams.month !== undefined) {
    params.month = monthNames[labelParams.month];
  }
  if (labelParams.dayNum !== undefined) {
    params.dayNum = labelParams.dayNum;
  }

  return t(`SCHEDULED_MESSAGES.RECURRENCE.${label}`, params);
}
