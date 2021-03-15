import {
  formatDate,
  formatUnixDate,
  buildDateFromTime,
  formatDigitToString,
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

  describe('#buildDate', () => {
    it('returns correctly parsed date', () => {
      const date = new Date();
      date.setFullYear(2021);
      date.setMonth(2);
      date.setDate(5);

      const result = buildDateFromTime(12, 15, '.465Z', date);
      expect(result + '').toEqual(
        'Fri Mar 05 2021 12:15:00 GMT+0000 (Coordinated Universal Time)'
      );
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
});
