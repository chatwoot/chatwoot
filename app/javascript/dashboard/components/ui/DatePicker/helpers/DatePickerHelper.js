import {
  parse,
  startOfDay,
  subDays,
  endOfDay,
  subMonths,
  startOfMonth,
  isSameMonth,
  format,
  startOfWeek,
  addDays,
  eachDayOfInterval,
  endOfMonth,
  isWithinInterval,
} from 'date-fns';

// Constants for calendar and date ranges
export const calendarWeeks = [
  { id: 1, label: 'M' },
  { id: 2, label: 'T' },
  { id: 3, label: 'W' },
  { id: 4, label: 'T' },
  { id: 5, label: 'F' },
  { id: 6, label: 'S' },
  { id: 7, label: 'S' },
];

export const dateRanges = [
  { label: 'Last 7 days', value: 'last7days' },
  { label: 'Last 30 days', value: 'last30days' },
  { label: 'Last 3 months', value: 'last3months' },
  { label: 'Last 6 months', value: 'last6months' },
  { label: 'Last year', value: 'lastYear' },
  { label: 'Custom date range', value: 'custom' },
];

export const parseDateFromDMY = dateString => {
  const [day, month, year] = dateString.split('/');
  return parse(`${year}-${month}-${day}`, 'yyyy-MM-dd', new Date());
};

export const month = currentDate => format(currentDate, 'MMMM');
export const year = currentDate => format(currentDate, 'yyyy');

// Utility functions for calendar operations
export const chunk = (array, size) =>
  Array.from({ length: Math.ceil(array.length / size) }, (_, index) =>
    array.slice(index * size, index * size + size)
  );

export const getWeeksForMonth = (date, weekStartsOn = 1) => {
  const startOfTheMonth = startOfMonth(date);
  const startOfTheFirstWeek = startOfWeek(startOfTheMonth, { weekStartsOn });
  const endOfTheLastWeek = addDays(startOfTheFirstWeek, 41); // Covering six weeks to fill the calendar
  return chunk(
    eachDayOfInterval({ start: startOfTheFirstWeek, end: endOfTheLastWeek }),
    7
  );
};

// Date comparison functions
export const isToday = (currentDate, date) =>
  date.getDate() === currentDate.getDate() &&
  date.getMonth() === currentDate.getMonth() &&
  date.getFullYear() === currentDate.getFullYear();

export const isCurrentMonth = (day, referenceDate) =>
  isSameMonth(day, referenceDate);

export const isLastDayOfMonth = day => {
  const lastDay = endOfMonth(day);
  return day.getDate() === lastDay.getDate();
};

export const isStartOrEndDate = (day, startDate, endDate) => {
  const startMatch =
    startDate && day.toDateString() === startDate.toDateString();
  const endMatch = endDate && day.toDateString() === endDate.toDateString();
  return startMatch || endMatch;
};

export const dayIsInRange = (date, startDate, endDate) => {
  if (startDate && endDate && startDate > endDate) {
    // Swap if start is greater than end
    [startDate, endDate] = [endDate, startDate];
  }
  return (
    startDate &&
    endDate &&
    isWithinInterval(date, { start: startDate, end: endDate })
  );
};

// Handling hovering states in date range pickers
export const isHoveringDayInRange = (
  day,
  startDate,
  endDate,
  hoveredEndDate
) => {
  if (endDate && hoveredEndDate && startDate <= hoveredEndDate) {
    // Ensure the start date is not after the hovered end date
    return isWithinInterval(day, { start: startDate, end: hoveredEndDate });
  }
  return false;
};

export const isHoveringNextDayInRange = (
  day,
  startDate,
  endDate,
  hoveredEndDate
) => {
  if (startDate && !endDate && hoveredEndDate) {
    // If a start date is selected, and we're hovering (but haven't clicked an end date yet)
    const nextDay = addDays(day, 1);
    return isWithinInterval(nextDay, { start: startDate, end: hoveredEndDate });
  }
  if (startDate && endDate) {
    // Normal range checking between selected start and end dates
    const nextDay = addDays(day, 1);
    return isWithinInterval(nextDay, { start: startDate, end: endDate });
  }
  return false;
};

// Helper func to determine active date ranges based on user selection
export const getActiveDateRange = (range, currentDate) => {
  const ranges = {
    last7days: () => ({
      start: startOfDay(subDays(currentDate, 6)),
      end: endOfDay(currentDate),
    }),
    last30days: () => ({
      start: startOfDay(subDays(currentDate, 29)),
      end: endOfDay(currentDate),
    }),
    last3months: () => ({
      start: startOfDay(subMonths(currentDate, 3)),
      end: endOfDay(currentDate),
    }),
    last6months: () => ({
      start: startOfDay(subMonths(currentDate, 6)),
      end: endOfDay(currentDate),
    }),
    lastYear: () => ({
      start: startOfDay(subMonths(currentDate, 12)),
      end: endOfDay(currentDate),
    }),
    custom: () => ({ start: currentDate, end: currentDate }),
  };

  return (
    ranges[range] || (() => ({ start: currentDate, end: currentDate }))
  )();
};
