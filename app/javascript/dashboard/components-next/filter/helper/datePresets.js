import {
  format,
  startOfMonth,
  startOfWeek,
  startOfYear,
  subDays,
  subMonths,
  subWeeks,
} from 'date-fns';

const DATE_FORMAT = 'yyyy-MM-dd';
const WEEK_OPTIONS = { weekStartsOn: 1 };

const formatDate = date => format(date, DATE_FORMAT);

// The filter API reads `is_greater_than D` as "on or after the day after D"
// and `is_less_than D` as "before D", in the viewer's timezone.
const onOrAfter = date => ({
  filterOperator: 'is_greater_than',
  values: formatDate(subDays(date, 1)),
});
const before = date => ({
  filterOperator: 'is_less_than',
  values: formatDate(date),
});

const PRESET_CONDITIONS = {
  today: today => [onOrAfter(today)],
  yesterday: today => [onOrAfter(subDays(today, 1)), before(today)],
  this_week: today => [onOrAfter(startOfWeek(today, WEEK_OPTIONS))],
  last_week: today => [
    onOrAfter(startOfWeek(subWeeks(today, 1), WEEK_OPTIONS)),
    before(startOfWeek(today, WEEK_OPTIONS)),
  ],
  this_month: today => [onOrAfter(startOfMonth(today))],
  last_month: today => [
    onOrAfter(startOfMonth(subMonths(today, 1))),
    before(startOfMonth(today)),
  ],
  this_year: today => [onOrAfter(startOfYear(today))],
  last_n_days: (today, days) => [
    {
      filterOperator: 'is_greater_than',
      values: days ? formatDate(subDays(today, days)) : '',
    },
  ],
  older_than_n_days: (_today, days) => [
    { filterOperator: 'days_before', values: days ? String(days) : '' },
  ],
};

/**
 * Turns a recommended date preset into filter row conditions for the date field.
 * A closed period such as "last week" needs two rows. Weeks start on Monday.
 * @param {string} preset - A preset name from the filter recommendations API
 * @param {number} [days] - The number of days for the counted presets
 * @param {Date} [today] - The reference date, in the viewer's timezone
 * @returns {Array<{filterOperator: string, values: string}>} Empty for an unknown preset
 */
export const buildDatePresetConditions = (preset, days, today = new Date()) =>
  PRESET_CONDITIONS[preset]?.(today, days) ?? [];
