import {
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

export const month = currentDate => format(currentDate, 'MMMM');
export const year = currentDate => format(currentDate, 'yyyy');

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

export const isToday = (currentDate, date) => {
  return (
    date.getDate() === currentDate.getDate() &&
    date.getMonth() === currentDate.getMonth() &&
    date.getFullYear() === currentDate.getFullYear()
  );
};

export const isCurrentMonth = (day, referenceDate) => {
  return isSameMonth(day, referenceDate);
};

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

// export const isUpcomingDayInRange = (
//   day,
//   startDate,
//   endDate,
//   hoveredEndDate
// ) => {
//   // If a start date is selected, and hovering is active but no end date is yet clicked
//   if (startDate && !endDate && hoveredEndDate) {
//     const nextDay = addDays(day, 1);
//     return isWithinInterval(nextDay, {
//       start: startDate,
//       end: hoveredEndDate,
//     });
//   }
//   // Normal range checking between selected start and end dates
//   if (startDate && endDate) {
//     const nextDay = addDays(day, 1);
//     return isWithinInterval(nextDay, {
//       start: startDate,
//       end: endDate,
//     });
//   }
//   return false;
// };

export const isHoveringDayInRange = (
  day,
  startDate,
  endDate,
  hoveredEndDate
) => {
  if (endDate && hoveredEndDate) {
    // Ensure the start date is not after the hovered end date
    if (startDate <= hoveredEndDate) {
      return isWithinInterval(day, {
        start: startDate,
        end: hoveredEndDate,
      });
    }
  }
  return false;
};

export const getActiveDateRange = (range, currentDate) => {
  let start = currentDate;
  let end = currentDate;

  switch (range) {
    case 'last7days':
      start = startOfDay(subDays(currentDate, 6));
      end = endOfDay(currentDate);
      break;
    case 'last30days':
      start = startOfDay(subDays(currentDate, 29));
      end = endOfDay(currentDate);
      break;
    case 'last3months':
      start = startOfDay(subMonths(currentDate, 3));
      end = endOfDay(currentDate);
      break;
    case 'last6months':
      start = startOfDay(subMonths(currentDate, 6));
      end = endOfDay(currentDate);
      break;
    case 'lastYear':
      start = startOfDay(subMonths(currentDate, 12));
      end = endOfDay(currentDate);
      break;
    case 'custom':
      // Assuming custom range logic is handled elsewhere
      break;
    default:
      break;
  }

  return { start, end };
};
