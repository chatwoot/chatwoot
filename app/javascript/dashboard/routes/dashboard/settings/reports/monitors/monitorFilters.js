import { addDays, format, parseISO } from 'date-fns';

export const CUSTOM_RANGE = 'custom';
export const MIN_RANGE_DAYS = 7;
export const MAX_RANGE_DAYS = 30;
export const INTERVALS = ['hour', 'six_hours', 'day'];
export const DEFAULT_FILTERS = { range: MIN_RANGE_DAYS, interval: 'day' };

export const shiftDate = (date, days) =>
  date ? format(addDays(parseISO(date), days), 'yyyy-MM-dd') : '';
