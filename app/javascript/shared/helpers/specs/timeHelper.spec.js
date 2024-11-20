import {
  messageStamp,
  messageTimestamp,
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

beforeEach(() => {
  process.env.TZ = 'UTC';
  vi.useFakeTimers('modern');
  const mockDate = new Date(Date.UTC(2023, 4, 5));
  vi.setSystemTime(mockDate);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('#messageStamp', () => {
  it('returns correct value', () => {
    expect(messageStamp(1612971343)).toEqual('3:35 PM');
    expect(messageStamp(1612971343, 'LLL d, h:mm a')).toEqual(
      'Feb 10, 3:35 PM'
    );
  });
});

describe('#messageTimestamp', () => {
  it('should return the message date in the specified format if the message was sent in the current year', () => {
    expect(messageTimestamp(1680777464)).toEqual('Apr 6, 2023');
  });
  it('should return the message date and time in a different format if the message was sent in a different year', () => {
    expect(messageTimestamp(1612971343)).toEqual('Feb 10 2021, 3:35 PM');
  });
});

describe('#dynamicTime', () => {
  it('returns correct value', () => {
    Date.now = vi.fn(() => new Date(Date.UTC(2023, 1, 14)).valueOf());
    expect(dynamicTime(1612971343)).toEqual('about 2 years ago');
  });
});

describe('#dateFormat', () => {
  it('returns correct value', () => {
    expect(dateFormat(1612971343)).toEqual('Feb 10, 2021');
    expect(dateFormat(1612971343, 'LLL d, yyyy')).toEqual('Feb 10, 2021');
  });
});

describe('#shortTimestamp', () => {
  // Test cases when withAgo is false or not provided
  it('returns correct value without ago', () => {
    expect(shortTimestamp('less than a minute ago')).toEqual('now');
    expect(shortTimestamp('1 minute ago')).toEqual('1m');
    expect(shortTimestamp('12 minutes ago')).toEqual('12m');
    expect(shortTimestamp('a minute ago')).toEqual('1m');
    expect(shortTimestamp('an hour ago')).toEqual('1h');
    expect(shortTimestamp('1 hour ago')).toEqual('1h');
    expect(shortTimestamp('2 hours ago')).toEqual('2h');
    expect(shortTimestamp('1 day ago')).toEqual('1d');
    expect(shortTimestamp('a day ago')).toEqual('1d');
    expect(shortTimestamp('3 days ago')).toEqual('3d');
    expect(shortTimestamp('a month ago')).toEqual('1mo');
    expect(shortTimestamp('1 month ago')).toEqual('1mo');
    expect(shortTimestamp('2 months ago')).toEqual('2mo');
    expect(shortTimestamp('a year ago')).toEqual('1y');
    expect(shortTimestamp('1 year ago')).toEqual('1y');
    expect(shortTimestamp('4 years ago')).toEqual('4y');
  });

  // Test cases when withAgo is true
  it('returns correct value with ago', () => {
    expect(shortTimestamp('less than a minute ago', true)).toEqual('now');
    expect(shortTimestamp('1 minute ago', true)).toEqual('1m ago');
    expect(shortTimestamp('12 minutes ago', true)).toEqual('12m ago');
    expect(shortTimestamp('a minute ago', true)).toEqual('1m ago');
    expect(shortTimestamp('an hour ago', true)).toEqual('1h ago');
    expect(shortTimestamp('1 hour ago', true)).toEqual('1h ago');
    expect(shortTimestamp('2 hours ago', true)).toEqual('2h ago');
    expect(shortTimestamp('1 day ago', true)).toEqual('1d ago');
    expect(shortTimestamp('a day ago', true)).toEqual('1d ago');
    expect(shortTimestamp('3 days ago', true)).toEqual('3d ago');
    expect(shortTimestamp('a month ago', true)).toEqual('1mo ago');
    expect(shortTimestamp('1 month ago', true)).toEqual('1mo ago');
    expect(shortTimestamp('2 months ago', true)).toEqual('2mo ago');
    expect(shortTimestamp('a year ago', true)).toEqual('1y ago');
    expect(shortTimestamp('1 year ago', true)).toEqual('1y ago');
    expect(shortTimestamp('4 years ago', true)).toEqual('4y ago');
  });
});
