import { formatDate, formatUnixDate } from '../DateHelper';

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
