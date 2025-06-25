import TimeMixin from '../time';

describe('#messageStamp', () => {
  it('returns correct value', () => {
    expect(TimeMixin.methods.messageStamp(1612971343)).toEqual('3:35 PM');
    expect(TimeMixin.methods.messageStamp(1612971343, 'LLL d, h:mm a')).toEqual(
      'Feb 10, 3:35 PM'
    );
  });
});

describe('#messageTimestamp', () => {
  it('should return the message date in the specified format if the message was sent in the current year', () => {
    expect(TimeMixin.methods.messageTimestamp(1680777464)).toEqual(
      'Apr 6, 2023'
    );
  });
  it('should return the message date and time in a different format if the message was sent in a different year', () => {
    expect(TimeMixin.methods.messageTimestamp(1612971343)).toEqual(
      'Feb 10 2021, 3:35 PM'
    );
  });
});

describe('#dynamicTime', () => {
  it('returns correct value', () => {
    Date.now = jest.fn(() => new Date(Date.UTC(2023, 1, 14)).valueOf());
    expect(TimeMixin.methods.dynamicTime(1612971343)).toEqual(
      'about 2 years ago'
    );
  });
});

describe('#dateFormat', () => {
  it('returns correct value', () => {
    expect(TimeMixin.methods.dateFormat(1612971343)).toEqual('Feb 10, 2021');
    expect(TimeMixin.methods.dateFormat(1612971343, 'LLL d, yyyy')).toEqual(
      'Feb 10, 2021'
    );
  });
});

describe('#shortTimestamp', () => {
  it('returns correct value', () => {
    expect(TimeMixin.methods.shortTimestamp('less than a minute ago')).toEqual(
      'now'
    );
    expect(TimeMixin.methods.shortTimestamp(' minute ago')).toEqual('m');
    expect(TimeMixin.methods.shortTimestamp(' minutes ago')).toEqual('m');
    expect(TimeMixin.methods.shortTimestamp(' hour ago')).toEqual('h');
    expect(TimeMixin.methods.shortTimestamp(' hours ago')).toEqual('h');
    expect(TimeMixin.methods.shortTimestamp(' day ago')).toEqual('d');
    expect(TimeMixin.methods.shortTimestamp(' days ago')).toEqual('d');
    expect(TimeMixin.methods.shortTimestamp(' month ago')).toEqual('mo');
    expect(TimeMixin.methods.shortTimestamp(' months ago')).toEqual('mo');
    expect(TimeMixin.methods.shortTimestamp(' year ago')).toEqual('y');
    expect(TimeMixin.methods.shortTimestamp(' years ago')).toEqual('y');
  });
});
