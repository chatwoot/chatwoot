import {
  formatDate,
  formatUnixDate,
  formatDigitToString,
  isTimeAfter,
  generateRelativeTime,
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

describe('#generateRelativeTime', () => {
  it('should return correct relative time', () => {
    expect(generateRelativeTime(-1, 'day', 'en')).toEqual('yesterday');
    expect(generateRelativeTime(1, 'day', 'en')).toEqual('tomorrow');
    expect(generateRelativeTime(1, 'hour', 'en')).toEqual('in 1 hour');
    expect(generateRelativeTime(-1, 'hour', 'en')).toEqual('1 hour ago');
    expect(generateRelativeTime(1, 'minute', 'en')).toEqual('in 1 minute');
    expect(generateRelativeTime(-1, 'minute', 'en')).toEqual('1 minute ago');
    expect(generateRelativeTime(1, 'second', 'en')).toEqual('in 1 second');
    expect(generateRelativeTime(-1, 'second', 'en')).toEqual('1 second ago');
  });
});
