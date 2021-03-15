import {
  generateTimeSlots,
  getTime,
  timeSlotParse,
  timeSlotTransform,
  timeZoneOptions,
} from '../businessHour';

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

describe('#getTime', () => {
  it('returns parses 24 hour time correctly', () => {
    expect(getTime(15, 30)).toStrictEqual('03:30 PM');
  });
  it('returns parses 12 hour time correctly', () => {
    expect(getTime(12, 30)).toStrictEqual('12:30 PM');
  });
});

describe('#timeSlotParse', () => {
  it('returns parses correctly', () => {
    const slot = {
      day_of_week: 1,
      open_hour: 1,
      open_minutes: 30,
      close_hour: 4,
      close_minutes: 30,
      closed_all_day: false,
    };

    expect(timeSlotParse([slot])).toStrictEqual([
      {
        day: 1,
        from: '01:30 AM',
        to: '04:30 AM',
        valid: true,
      },
    ]);
  });
});

describe('#timeSlotTransform', () => {
  it('returns transforms correctly', () => {
    const slot = {
      day: 1,
      from: '01:30 AM',
      to: '04:30 AM',
      valid: true,
    };

    expect(timeSlotTransform([slot])).toStrictEqual([
      {
        day_of_week: 1,
        open_hour: 1,
        open_minutes: 30,
        close_hour: 4,
        close_minutes: 30,
        closed_all_day: false,
      },
    ]);
  });
});

describe('#timeZoneOptions', () => {
  it('returns transforms correctly', () => {
    expect(timeZoneOptions()[0]).toStrictEqual({
      value: 'Etc/GMT+12',
      label: 'International Date Line West',
    });
  });
});
