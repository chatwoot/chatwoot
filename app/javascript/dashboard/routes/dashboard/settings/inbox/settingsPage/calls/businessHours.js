// A short summary of an inbox's weekly hours, Monday first, such as "Mon–Fri 09:00–18:00", with
// days that share the same hours grouped together and closed days left out
const WEEK = [1, 2, 3, 4, 5, 6, 0];

const pad = value => String(value ?? 0).padStart(2, '0');

const hoursOf = (day, allDayLabel) => {
  if (day.closed_all_day) return null;
  if (day.open_all_day) return allDayLabel;
  return `${pad(day.open_hour)}:${pad(day.open_minutes)}–${pad(day.close_hour)}:${pad(day.close_minutes)}`;
};

// A Sunday-based week from 2023-01-01 (a Sunday) gives each weekday's short name in the locale
const dayName = (dayOfWeek, locale) =>
  new Intl.DateTimeFormat(locale, { weekday: 'short' }).format(
    new Date(2023, 0, 1 + dayOfWeek)
  );

export const businessHoursSummary = (workingHours, { locale, allDayLabel }) => {
  const byDay = Object.fromEntries(
    (workingHours || []).map(day => [day.day_of_week, day])
  );
  const groups = [];
  WEEK.forEach((dayOfWeek, position) => {
    const day = byDay[dayOfWeek];
    const hours = day && hoursOf(day, allDayLabel);
    if (!hours) return;
    const last = groups[groups.length - 1];
    if (last && last.hours === hours && last.lastPosition === position - 1) {
      last.lastDay = dayOfWeek;
      last.lastPosition = position;
      return;
    }
    groups.push({
      hours,
      firstDay: dayOfWeek,
      lastDay: dayOfWeek,
      lastPosition: position,
    });
  });
  return groups
    .map(({ hours, firstDay, lastDay }) => {
      const days =
        firstDay === lastDay
          ? dayName(firstDay, locale)
          : `${dayName(firstDay, locale)}–${dayName(lastDay, locale)}`;
      return `${days} ${hours}`;
    })
    .join(', ');
};
