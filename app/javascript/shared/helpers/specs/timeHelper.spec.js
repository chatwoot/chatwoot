import {
  messageDateFormat,
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

beforeEach(() => {
  process.env.TZ = 'UTC';
  vi.useFakeTimers('modern');
  const mockDate = new Date(Date.UTC(2024, 10, 5, 11, 30));
  vi.setSystemTime(mockDate);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('#dynamicTime', () => {
  it('returns correct value', () => {
    expect(dynamicTime(1667646000, 'en')).toEqual('about 2 years ago');
  });
});

describe('#messageDateFormat', () => {
  it('should return the message date in the specified format if the message was sent in the current year', () => {
    expect(messageDateFormat(1730806200, 'en')).toEqual('11:30 AM');
  });
  it('should return the message date and time in a different format if the message was sent in a different year', () => {
    expect(messageDateFormat(1730633400, 'en')).toEqual(
      'Nov 3, 2024, 11:30 AM'
    );
  });
  it('should return the message date and time in a different format if the message was sent in a different year', () => {
    expect(messageDateFormat(1612971343, 'en')).toEqual('Feb 10, 2021');
  });
});

describe('#dateFormat', () => {
  it('returns correct value', () => {
    expect(dateFormat(1612971343, 'dateS')).toEqual('2/10/21');
    expect(dateFormat(1612971343, 'dateM')).toEqual('Feb 10, 2021');
    expect(dateFormat(1612971343, 'dateM_timeS')).toEqual(
      'Feb 10, 2021, 3:35 PM'
    );
    expect(dateFormat(1612971343, 'dateM_timeM')).toEqual(
      'Feb 10, 2021, 3:35:43 PM'
    );
    expect(dateFormat(1612971343)).toEqual('Feb 10, 2021');
  });
});

describe('#shortTimestamp', () => {
  // Test cases when withAgo is false or not provided
  it('returns correct value without ago', () => {
    expect(shortTimestamp(1730806200)).toEqual('less than a minute');
    expect(shortTimestamp(1730806140)).toEqual('1 minute');
    expect(shortTimestamp(1730805480)).toEqual('12 minutes');
    expect(shortTimestamp(1730802600)).toEqual('1 hour');
    expect(shortTimestamp(1730799000)).toEqual('2 hours');
    expect(shortTimestamp(1730719800)).toEqual('1 day');
    expect(shortTimestamp(1730547000)).toEqual('3 days');
    expect(shortTimestamp(1728127800)).toEqual('1 month');
    expect(shortTimestamp(1725535800)).toEqual('2 months');
    expect(shortTimestamp(1699183800)).toEqual('1 year');
    expect(shortTimestamp(1604575800)).toEqual('4 years');
  });

  // Test cases when withAgo is true
  it('returns correct value with ago', () => {
    expect(shortTimestamp(1730806200, true)).toEqual('less than a minute ago');
    expect(shortTimestamp(1730806140, true)).toEqual('1 minute ago');
    expect(shortTimestamp(1730805480, true)).toEqual('12 minutes ago');
    expect(shortTimestamp(1730802600, true)).toEqual('1 hour ago');
    expect(shortTimestamp(1730799000, true)).toEqual('2 hours ago');
    expect(shortTimestamp(1730719800, true)).toEqual('1 day ago');
    expect(shortTimestamp(1730547000, true)).toEqual('3 days ago');
    expect(shortTimestamp(1728127800, true)).toEqual('1 month ago');
    expect(shortTimestamp(1725535800, true)).toEqual('2 months ago');
    expect(shortTimestamp(1699183800, true)).toEqual('1 year ago');
    expect(shortTimestamp(1604575800, true)).toEqual('4 years ago');
  });
});
