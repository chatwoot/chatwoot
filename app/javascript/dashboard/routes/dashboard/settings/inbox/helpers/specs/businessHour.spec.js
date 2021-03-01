import { generateTimeSlots } from '../businessHour';

describe('#generateTimeSlots', () => {
  it('returns correct number of time slots', () => {
    expect(generateTimeSlots(15).length).toStrictEqual((60 / 15) * 24);
  });
  it('returns correct time slots', () => {
    expect(generateTimeSlots(240)).toStrictEqual([
      '12:00 AM',
      '04:00 AM',
      '08:00 AM',
      '12:00 PM',
      '04:00 PM',
      '08:00 PM',
    ]);
  });
});
