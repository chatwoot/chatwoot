export function isDate(value: any) {
  return value instanceof Date || Object.prototype.toString.call(value) === '[object Date]';
}

export function toDate(value: any) {
  if (isDate(value)) {
    return new Date(value.getTime());
  }
  if (value == null) {
    return new Date(NaN);
  }
  return new Date(value);
}

export function isValidDate(value: any) {
  return isDate(value) && !isNaN(value.getTime());
}

export function startOfWeek(value: Date, firstDayOfWeek = 0) {
  if (!(firstDayOfWeek >= 0 && firstDayOfWeek <= 6)) {
    throw new RangeError('weekStartsOn must be between 0 and 6');
  }
  const date = toDate(value);
  const day = date.getDay();
  const diff = (day + 7 - firstDayOfWeek) % 7;
  date.setDate(date.getDate() - diff);
  date.setHours(0, 0, 0, 0);
  return date;
}

export function startOfWeekYear(
  value: Date,
  { firstDayOfWeek = 0, firstWeekContainsDate = 1 } = {}
) {
  if (!(firstWeekContainsDate >= 1 && firstWeekContainsDate <= 7)) {
    throw new RangeError('firstWeekContainsDate must be between 1 and 7');
  }
  const date = toDate(value);
  const year = date.getFullYear();
  let firstDateOfFirstWeek = new Date(0);
  for (let i = year + 1; i >= year - 1; i--) {
    firstDateOfFirstWeek.setFullYear(i, 0, firstWeekContainsDate);
    firstDateOfFirstWeek.setHours(0, 0, 0, 0);
    firstDateOfFirstWeek = startOfWeek(firstDateOfFirstWeek, firstDayOfWeek);
    if (date.getTime() >= firstDateOfFirstWeek.getTime()) {
      break;
    }
  }
  return firstDateOfFirstWeek;
}

export function getWeek(value: Date, { firstDayOfWeek = 0, firstWeekContainsDate = 1 } = {}) {
  const date = toDate(value);
  const firstDateOfThisWeek = startOfWeek(date, firstDayOfWeek);
  const firstDateOfFirstWeek = startOfWeekYear(date, { firstDayOfWeek, firstWeekContainsDate });
  const diff = firstDateOfThisWeek.getTime() - firstDateOfFirstWeek.getTime();

  return Math.round(diff / (7 * 24 * 3600 * 1000)) + 1;
}
