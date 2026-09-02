import format from 'date-fns/format';
import fromUnixTime from 'date-fns/fromUnixTime';
import startOfDay from 'date-fns/startOfDay';

export const buildIntervalMatrix = intervalData => {
  const datesByDay = new Map();
  const values = {};
  let maxValue = 0;

  intervalData.forEach(({ timestamp, value }) => {
    const date = fromUnixTime(timestamp);
    const dayKey = format(date, 'yyyy-MM-dd');

    datesByDay.set(dayKey, startOfDay(date));
    values[dayKey] ||= {};
    values[dayKey][date.getHours()] = value;
    maxValue = Math.max(maxValue, value);
  });

  const days = [...datesByDay.entries()]
    .sort(([firstKey], [secondKey]) => firstKey.localeCompare(secondKey))
    .map(([key, date]) => ({ key, date }));

  return { days, values, maxValue };
};
