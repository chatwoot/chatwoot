import TimeMixin from '../time';

describe('#messageStamp', () => {
  it('returns correct value', () => {
    expect(TimeMixin.methods.messageStamp(1612971343)).toEqual('9:05 PM');
    expect(TimeMixin.methods.messageStamp(1612971343, 'LLL d, h:mm a')).toEqual(
      'Feb 10, 9:05 PM'
    );
  });
});
