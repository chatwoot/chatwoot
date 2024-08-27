import {
  monthName,
  yearName,
  getIntlDateFormatForLocale,
  getWeeksForMonth,
  isToday,
  isCurrentMonth,
  isLastDayOfMonth,
  dayIsInRange,
  getActiveDateRange,
  isHoveringDayInRange,
  isHoveringNextDayInRange,
  moveCalendarDate,
  chunk,
} from '../DatePickerHelper';

describe('Date formatting functions', () => {
  const testDate = new Date(2020, 4, 15); // May 15, 2020

  beforeEach(() => {
    vi.spyOn(navigator, 'language', 'get').mockReturnValue('en-US');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns the correct month name from a date', () => {
    expect(monthName(testDate)).toBe('May');
  });

  it('returns the correct year from a date', () => {
    expect(yearName(testDate)).toBe('2020');
  });

  it('returns the correct date format for the current locale en-US', () => {
    const expected = 'MM/dd/yyyy';
    expect(getIntlDateFormatForLocale()).toBe(expected);
  });

  it('returns the correct date format for the current locale en-IN', () => {
    vi.spyOn(navigator, 'language', 'get').mockReturnValue('en-IN');
    const expected = 'dd/MM/yyyy';
    expect(getIntlDateFormatForLocale()).toBe(expected);
  });
});

describe('chunk', () => {
  const array = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  it('correctly chunks an array into smaller arrays of given size', () => {
    const expected = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];
    expect(chunk(array, 3)).toEqual(expected);
  });

  it('handles arrays that do not divide evenly by the chunk size', () => {
    const expected = [[1, 2], [3, 4], [5, 6], [7, 8], [9]];
    expect(chunk(array, 2)).toEqual(expected);
  });
});

describe('getWeeksForMonth', () => {
  it('returns the correct weeks array for a month starting on Monday', () => {
    const date = new Date(2020, 3, 1); // April 2020
    const weeks = getWeeksForMonth(date, 1);
    expect(weeks.length).toBe(6);
    expect(weeks[0][0]).toEqual(new Date(2020, 2, 30)); // Check if first day of the first week is correct
  });
});

describe('moveCalendarDate', () => {
  it('handles the year transition when moving the start date backward by one month from January', () => {
    const startDate = new Date(2021, 0, 1);
    const endDate = new Date(2021, 0, 31);
    const result = moveCalendarDate(
      'start',
      startDate,
      endDate,
      'prev',
      'month'
    );
    const expectedStartDate = new Date(2020, 11, 1);
    expect(result.start.toISOString()).toEqual(expectedStartDate.toISOString());
    expect(result.end.toISOString()).toEqual(endDate.toISOString());
  });

  it('handles the year transition when moving the start date forward by one month from January', () => {
    const startDate = new Date(2020, 0, 1);
    const endDate = new Date(2020, 1, 31);
    const result = moveCalendarDate(
      'start',
      startDate,
      endDate,
      'next',
      'month'
    );
    const expectedStartDate = new Date(2020, 1, 1);
    expect(result.start.toISOString()).toEqual(expectedStartDate.toISOString());
    expect(result.end.toISOString()).toEqual(endDate.toISOString());
  });

  it('handles the year transition when moving the end date forward by one month from December', () => {
    const startDate = new Date(2021, 11, 1);
    const endDate = new Date(2021, 11, 31);
    const result = moveCalendarDate('end', startDate, endDate, 'next', 'month');
    const expectedEndDate = new Date(2022, 0, 31);
    expect(result.start).toEqual(startDate);
    expect(result.end.toISOString()).toEqual(expectedEndDate.toISOString());
  });
  it('handles the year transition when moving the end date backward by one month from December', () => {
    const startDate = new Date(2021, 11, 1);
    const endDate = new Date(2021, 11, 31);
    const result = moveCalendarDate('end', startDate, endDate, 'prev', 'month');
    const expectedEndDate = new Date(2021, 10, 30);

    expect(result.start).toEqual(startDate);
    expect(result.end.toISOString()).toEqual(expectedEndDate.toISOString());
  });
});

describe('isToday', () => {
  it('returns true if the dates are the same', () => {
    const today = new Date();
    const alsoToday = new Date(today);
    expect(isToday(today, alsoToday)).toBeTruthy();
  });

  it('returns false if the dates are not the same', () => {
    const today = new Date();
    const notToday = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() - 1
    );
    expect(isToday(today, notToday)).toBeFalsy();
  });
});

describe('isCurrentMonth', () => {
  const referenceDate = new Date(2020, 6, 15); // July 15, 2020

  it('returns true if the day is in the same month as the reference date', () => {
    const testDay = new Date(2020, 6, 1);
    expect(isCurrentMonth(testDay, referenceDate)).toBeTruthy();
  });

  it('returns false if the day is not in the same month as the reference date', () => {
    const testDay = new Date(2020, 5, 30);
    expect(isCurrentMonth(testDay, referenceDate)).toBeFalsy();
  });
});

describe('isLastDayOfMonth', () => {
  it('returns true if the day is the last day of the month', () => {
    const testDay = new Date(2020, 6, 31); // July 31, 2020
    expect(isLastDayOfMonth(testDay)).toBeTruthy();
  });

  it('returns false if the day is not the last day of the month', () => {
    const testDay = new Date(2020, 6, 30); // July 30, 2020
    expect(isLastDayOfMonth(testDay)).toBeFalsy();
  });
});

describe('dayIsInRange', () => {
  it('returns true if the date is within the range', () => {
    const start = new Date(2020, 1, 10);
    const end = new Date(2020, 1, 20);
    const testDate = new Date(2020, 1, 15);
    expect(dayIsInRange(testDate, start, end)).toBeTruthy();
  });

  it('returns true if the date is the same as the start date', () => {
    const start = new Date(2020, 1, 10);
    const end = new Date(2020, 1, 20);
    const testDate = new Date(2020, 1, 10);
    expect(dayIsInRange(testDate, start, end)).toBeTruthy();
  });

  it('returns false if the date is outside the range', () => {
    const start = new Date(2020, 1, 10);
    const end = new Date(2020, 1, 20);
    const testDate = new Date(2020, 1, 9);
    expect(dayIsInRange(testDate, start, end)).toBeFalsy();
  });
});

describe('isHoveringDayInRange', () => {
  const startDate = new Date(2020, 6, 10);
  const endDate = new Date(2020, 6, 20);
  const hoveredEndDate = new Date(2020, 6, 15);

  it('returns true if the day is within the start and hovered end dates', () => {
    const testDay = new Date(2020, 6, 12);
    expect(
      isHoveringDayInRange(testDay, startDate, endDate, hoveredEndDate)
    ).toBeTruthy();
  });

  it('returns false if the day is outside the hovered date range', () => {
    const testDay = new Date(2020, 6, 16);
    expect(
      isHoveringDayInRange(testDay, startDate, endDate, hoveredEndDate)
    ).toBeFalsy();
  });
});

describe('isHoveringNextDayInRange', () => {
  const startDate = new Date(2020, 6, 10);
  const hoveredEndDate = new Date(2020, 6, 15);

  it('returns true if the next day after the given day is within the start and hovered end dates', () => {
    const testDay = new Date(2020, 6, 14);
    expect(
      isHoveringNextDayInRange(testDay, startDate, null, hoveredEndDate)
    ).toBeTruthy();
  });

  it('returns false if the next day is outside the start and hovered end dates', () => {
    const testDay = new Date(2020, 6, 15);
    expect(
      isHoveringNextDayInRange(testDay, startDate, null, hoveredEndDate)
    ).toBeFalsy();
  });
});

describe('getActiveDateRange', () => {
  const currentDate = new Date(2020, 5, 15, 12, 0); // May 15, 2020, at noon

  beforeEach(() => {
    // Mocking the current date to ensure consistency in tests
    vi.useFakeTimers().setSystemTime(currentDate.getTime());
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns the correct range for "last7days"', () => {
    const range = getActiveDateRange('last7days', new Date());
    const expectedStart = new Date(2020, 5, 9);
    expectedStart.setHours(0, 0, 0, 0);
    const expectedEnd = new Date();
    expectedEnd.setHours(23, 59, 59, 999);

    expect(range.start).toEqual(expectedStart);
    expect(range.end).toEqual(expectedEnd);
  });

  it('returns the correct range for "last30days"', () => {
    const range = getActiveDateRange('last30days', new Date());
    const expectedStart = new Date(2020, 4, 17);
    expectedStart.setHours(0, 0, 0, 0);
    const expectedEnd = new Date();
    expectedEnd.setHours(23, 59, 59, 999);

    expect(range.start).toEqual(expectedStart);
    expect(range.end).toEqual(expectedEnd);
  });

  it('returns the correct range for "last3months"', () => {
    const range = getActiveDateRange('last3months', new Date());
    const expectedStart = new Date(2020, 2, 15);
    expectedStart.setHours(0, 0, 0, 0);
    const expectedEnd = new Date();
    expectedEnd.setHours(23, 59, 59, 999);

    expect(range.start).toEqual(expectedStart);
    expect(range.end).toEqual(expectedEnd);
  });

  it('returns the correct range for "last6months"', () => {
    const range = getActiveDateRange('last6months', new Date());
    const expectedStart = new Date(2019, 11, 15);
    expectedStart.setHours(0, 0, 0, 0);
    const expectedEnd = new Date();
    expectedEnd.setHours(23, 59, 59, 999);

    expect(range.start).toEqual(expectedStart);
    expect(range.end).toEqual(expectedEnd);
  });

  it('returns the correct range for "lastYear"', () => {
    const range = getActiveDateRange('lastYear', new Date());
    const expectedStart = new Date(2019, 5, 15);
    expectedStart.setHours(0, 0, 0, 0);
    const expectedEnd = new Date();
    expectedEnd.setHours(23, 59, 59, 999);

    expect(range.start).toEqual(expectedStart);
    expect(range.end).toEqual(expectedEnd);
  });

  it('returns the correct range for "custom date range"', () => {
    const range = getActiveDateRange('custom', new Date());
    expect(range.start).toEqual(new Date(currentDate));
    expect(range.end).toEqual(new Date(currentDate));
  });

  it('handles an unknown range label gracefully', () => {
    const range = getActiveDateRange('unknown', new Date());
    expect(range.start).toEqual(new Date(currentDate));
    expect(range.end).toEqual(new Date(currentDate));
  });
});
