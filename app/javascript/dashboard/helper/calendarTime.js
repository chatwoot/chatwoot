export const TIMEZONE = 'America/Guayaquil';
export const HOUR_START = 8;
export const HOUR_END = 20;
export const SLOT_MINUTES = 30;
export const OFFSET = '-05:00';

export function guayaquilParts(date = new Date()) {
  const stamp = date.toLocaleString('sv-SE', { timeZone: TIMEZONE });
  const [dateKey, time] = stamp.split(' ');
  const [year, month, day] = dateKey.split('-').map(Number);
  const [hour, minute] = time.split(':').map(Number);
  return { year, month, day, hour, minute, dateKey };
}

export function addDaysKey(dateKey, amount) {
  const [year, month, day] = dateKey.split('-').map(Number);
  const next = new Date(Date.UTC(year, month - 1, day + amount));
  return next.toISOString().slice(0, 10);
}

export function startOfWeekKey(date = new Date()) {
  const { dateKey } = guayaquilParts(date);
  const [year, month, day] = dateKey.split('-').map(Number);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  const diff = weekday === 0 ? -6 : 1 - weekday;
  return addDaysKey(dateKey, diff);
}

export function weekDays(weekStartKey) {
  return Array.from({ length: 7 }, (_, index) =>
    addDaysKey(weekStartKey, index)
  );
}

export function weekBoundsIso(weekStartKey) {
  return {
    timeMin: `${weekStartKey}T00:00:00${OFFSET}`,
    timeMax: `${addDaysKey(weekStartKey, 7)}T00:00:00${OFFSET}`,
  };
}

export function zonedDateTime(dateKey, hours, minutes) {
  const hh = String(hours).padStart(2, '0');
  const mm = String(minutes).padStart(2, '0');
  return `${dateKey}T${hh}:${mm}:00${OFFSET}`;
}

export function eventDateKey(value) {
  if (!value) return '';
  if (value.length <= 10) return value;
  return guayaquilParts(new Date(value)).dateKey;
}

export function formatTime(value) {
  if (!value || value.length <= 10) return '';
  const { hour, minute } = guayaquilParts(new Date(value));
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
}

export function formatDayLabel(dateKey, locale) {
  const date = new Date(`${dateKey}T12:00:00${OFFSET}`);
  return date.toLocaleDateString(locale, {
    timeZone: TIMEZONE,
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });
}

export function eventLayout(
  startIso,
  endIso,
  hourStart = HOUR_START,
  hourEnd = HOUR_END
) {
  const gridStart = hourStart * 60;
  const gridSpan = Math.max((hourEnd - hourStart) * 60, 60);
  const start =
    startIso && startIso.length > 10
      ? guayaquilParts(new Date(startIso))
      : { hour: hourStart, minute: 0 };
  const end =
    endIso && endIso.length > 10
      ? guayaquilParts(new Date(endIso))
      : { hour: start.hour + 1, minute: start.minute };
  const startMin = start.hour * 60 + start.minute;
  const endMin = end.hour * 60 + end.minute;
  const clampedStart = Math.min(
    Math.max(startMin, gridStart),
    gridStart + gridSpan
  );
  const clampedEnd = Math.min(
    Math.max(endMin, clampedStart + 15),
    gridStart + gridSpan
  );
  return {
    top: ((clampedStart - gridStart) / gridSpan) * 100,
    height: ((clampedEnd - clampedStart) / gridSpan) * 100,
  };
}

export function slotFromClick(
  clientY,
  columnTop,
  columnHeight,
  hourStart = HOUR_START,
  hourEnd = HOUR_END
) {
  const ratio = Math.min(
    Math.max((clientY - columnTop) / columnHeight, 0),
    0.999
  );
  const totalMinutes = Math.floor(ratio * (hourEnd - hourStart) * 60);
  const snapped = Math.floor(totalMinutes / SLOT_MINUTES) * SLOT_MINUTES;
  const hours = hourStart + Math.floor(snapped / 60);
  const minutes = snapped % 60;
  return { hours, minutes };
}

export function dateAndTimeParts(iso) {
  if (!iso) {
    const now = guayaquilParts();
    return {
      date: now.dateKey,
      time: `${String(now.hour).padStart(2, '0')}:${String(now.minute).padStart(2, '0')}`,
    };
  }
  if (iso.length <= 10) return { date: iso, time: '09:00' };
  const parts = guayaquilParts(new Date(iso));
  return {
    date: parts.dateKey,
    time: `${String(parts.hour).padStart(2, '0')}:${String(parts.minute).padStart(2, '0')}`,
  };
}

export function durationMinutes(startIso, endIso) {
  if (!startIso || !endIso) return SLOT_MINUTES;
  const diff =
    (new Date(endIso).getTime() - new Date(startIso).getTime()) / 60000;
  return diff > 0 ? diff : SLOT_MINUTES;
}

export function addMinutesToTime(time, minutesToAdd) {
  const [hours, minutes] = (time || '09:00').split(':').map(Number);
  const total = hours * 60 + minutes + minutesToAdd;
  const wrapped = ((total % (24 * 60)) + 24 * 60) % (24 * 60);
  return `${String(Math.floor(wrapped / 60)).padStart(2, '0')}:${String(wrapped % 60).padStart(2, '0')}`;
}

export function rangeFromStartEnd(date, startTime, endTime) {
  const [startHours, startMinutes] = startTime.split(':').map(Number);
  const [endHours, endMinutes] = endTime.split(':').map(Number);
  return {
    start: zonedDateTime(date, startHours, startMinutes),
    end: zonedDateTime(date, endHours, endMinutes),
  };
}

export function rangeFromParts(date, time, duration) {
  return rangeFromStartEnd(date, time, addMinutesToTime(time, duration));
}
