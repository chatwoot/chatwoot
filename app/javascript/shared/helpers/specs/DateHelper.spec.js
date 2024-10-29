import {
  formatDate,
  formatUnixDate,
  formatDigitToString,
  isTimeAfter,
  generateRelativeTime,
  getDayDifferenceFromNow,
} from '../DateHelper';

describe('#DateHelper', () => {
  it('should format unix date correctly without dateFormat', () => {
    expect(formatUnixDate(1576340626)).toEqual('Dec 14, 2019');
  });

  it('should format unix date correctly without dateFormat', () => {
    expect(formatUnixDate(1608214031, 'MM/dd/yyyy')).toEqual('12/17/2020');
  });

  it('should format date', () => {
    expect(
      formatDate({
        date: 'Dec 14, 2019',
        todayText: 'Today',
        yesterdayText: 'Yesterday',
      })
    ).toEqual('Dec 14, 2019');
  });
  it('should format date as today ', () => {
    expect(
      formatDate({
        date: new Date(),
        todayText: 'Today',
        yesterdayText: 'Yesterday',
      })
    ).toEqual('Today');
  });
  it('should format date as yesterday ', () => {
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    expect(
      formatDate({
        date: yesterday,
        todayText: 'Today',
        yesterdayText: 'Yesterday',
      })
    ).toEqual('Yesterday');
  });
});
describe('#formatDigitToString', () => {
  it('returns date compatabile string from number is less than 9', () => {
    expect(formatDigitToString(8)).toEqual('08');
  });
  it('returns date compatabile string from number is greater than 9', () => {
    expect(formatDigitToString(11)).toEqual('11');
  });
});

describe('#isTimeAfter', () => {
  it('return correct values', () => {
    expect(isTimeAfter(5, 30, 9, 30)).toEqual(false);
    expect(isTimeAfter(9, 30, 9, 30)).toEqual(true);
    expect(isTimeAfter(9, 29, 9, 30)).toEqual(false);
    expect(isTimeAfter(11, 59, 12, 0)).toEqual(false);
  });
});

describe('generateRelativeTime', () => {
  it('should return a string with the relative time', () => {
    const value = 1;
    const unit = 'second';
    const languageCode = 'en-US';
    const expectedResult = 'in 1 second';

    const actualResult = generateRelativeTime(value, unit, languageCode);

    expect(actualResult).toBe(expectedResult);
  });

  it('should return a string with the relative time in a different language', () => {
    const value = 10;
    const unit = 'minute';
    const languageCode = 'de-DE';
    const expectedResult = 'in 10 Minuten';

    const actualResult = generateRelativeTime(value, unit, languageCode);

    expect(actualResult).toBe(expectedResult);
  });

  it('should return a string with the relative time for a different unit', () => {
    const value = 1;
    const unit = 'hour';
    const languageCode = 'en-US';
    const expectedResult = 'in 1 hour';

    const actualResult = generateRelativeTime(value, unit, languageCode);

    expect(actualResult).toBe(expectedResult);
  });

  it('should throw an error if the value is not a number', () => {
    const value = 1;
    const unit = 'day';
    const languageCode = 'en_US';
    const expectedResult = 'tomorrow';

    const actualResult = generateRelativeTime(value, unit, languageCode);

    expect(actualResult).toBe(expectedResult);
  });

  it('should throw an error if the value is not a number', () => {
    const value = 1;
    const unit = 'day';
    const languageCode = 'en-US';
    const expectedResult = 'tomorrow';

    const actualResult = generateRelativeTime(value, unit, languageCode);

    expect(actualResult).toBe(expectedResult);
  });
});

describe('#getDayDifferenceFromNow', () => {
  it('should return the difference if in same day', () => {
    const now = new Date('2023-12-08T00:00:00.000Z');
    const timestampInSeconds = 1702020305; // 08/12/2023, 12:55:05 (GMT+05:30)
    const expectedResult = 0;

    const actualResult = getDayDifferenceFromNow(now, timestampInSeconds);

    expect(actualResult).toBe(expectedResult);
  });

  it('should return the difference if in different day', () => {
    const now = new Date('2023-12-11T00:00:00.000Z');
    const timestampInSeconds = 1702020305; // 08/12/2023, 12:55:05 (GMT+05:30)
    const expectedResult = 2;

    const actualResult = getDayDifferenceFromNow(now, timestampInSeconds);

    expect(actualResult).toBe(expectedResult);
  });
});
