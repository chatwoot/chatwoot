import TimeMixin from '../time';

describe('#messageStamp', () => {
  it('returns correct value', () => {
    expect(TimeMixin.methods.messageStamp(1612971343)).toEqual('3:35 PM');
    expect(TimeMixin.methods.messageStamp(1612971343, 'LLL d, h:mm a')).toEqual(
      'Feb 10, 3:35 PM'
    );
  });
});
