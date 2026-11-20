import {
  generateTimeSlots,
  getTime,
  timeSlotParse,
  timeSlotTransform,
  timeZoneOptions,
} from '../businessHour';

describe('#generateTimeSlots', () => {
  it('returns correct number of time slots for 15-minute intervals', () => {
    const slots = generateTimeSlots(15);
    // 24 hours * 4 slots per hour + 1 for 11:59 PM = 97 slots
    expect(slots.length).toStrictEqual(97);
  });

  it('returns correct number of time slots for 30-minute intervals', () => {
    const slots = generateTimeSlots(30);
    // 24 hours * 2 slots per hour + 1 for 11:59 PM = 49 slots
    expect(slots.length).toStrictEqual(49);
  });

  it('returns correct time slots for 4-hour intervals', () => {
    expect(generateTimeSlots(240)).toStrictEqual([
      '12:00 AM',
      '04:00 AM',
      '08:00 AM',
      '12:00 PM',
      '04:00 PM',
      '08:00 PM',
      '11:59 PM',
    ]);
  });

  it('always starts with 12:00 AM', () => {
    expect(generateTimeSlots(15)[0]).toStrictEqual('12:00 AM');
    expect(generateTimeSlots(30)[0]).toStrictEqual('12:00 AM');
    expect(generateTimeSlots(60)[0]).toStrictEqual('12:00 AM');
  });

  it('always ends with 11:59 PM', () => {
    const slots15 = generateTimeSlots(15);
    const slots30 = generateTimeSlots(30);
    const slots60 = generateTimeSlots(60);

    expect(slots15[slots15.length - 1]).toStrictEqual('11:59 PM');
    expect(slots30[slots30.length - 1]).toStrictEqual('11:59 PM');
    expect(slots60[slots60.length - 1]).toStrictEqual('11:59 PM');
  });

  it('includes 11:59 PM even when it would not be in regular intervals', () => {
    const slots = generateTimeSlots(30);
    expect(slots).toContain('11:59 PM');
    expect(slots).toContain('11:30 PM'); // Regular interval
  });

  it('does not duplicate 11:59 PM if it already exists in regular intervals', () => {
    // Test with a step that would naturally include 11:59 PM
    const slots = generateTimeSlots(1); // 1-minute intervals
    const count11_59 = slots.filter(slot => slot === '11:59 PM').length;
    expect(count11_59).toStrictEqual(1);
  });

  it('generates correct time format', () => {
    const slots = generateTimeSlots(60);
    expect(slots).toContain('01:00 AM');
    expect(slots).toContain('12:00 PM');
    expect(slots).toContain('01:00 PM');
    expect(slots).toContain('11:00 PM');
  });

  it('handles edge case with very large step', () => {
    const slots = generateTimeSlots(1440); // 24 hours
    expect(slots).toStrictEqual(['12:00 AM', '11:59 PM']);
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
      open_all_day: false,
    };

    expect(timeSlotParse([slot])).toStrictEqual([
      {
        day: 1,
        from: '01:30 AM',
        to: '04:30 AM',
        valid: true,
        openAllDay: false,
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
      openAllDay: false,
    };

    expect(timeSlotTransform([slot])).toStrictEqual([
      {
        day_of_week: 1,
        open_hour: 1,
        open_minutes: 30,
        close_hour: 4,
        close_minutes: 30,
        closed_all_day: false,
        open_all_day: false,
      },
    ]);
  });
});

describe('#timeZoneOptions', () => {
  // Labels carry the daylight offset where a zone keeps one, so an option is
  // only wrong when it matches neither half of the year.
  const offsetAt = (timeZone, instant) => {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone,
      timeZoneName: 'longOffset',
    }).formatToParts(instant);
    const offset = parts
      .find(part => part.type === 'timeZoneName')
      .value.replace('GMT', '');
    return offset === '' ? '+00:00' : offset;
  };

  const hourAt = (timeZone, instant) =>
    new Intl.DateTimeFormat('en-GB', {
      timeZone,
      hour: '2-digit',
      hour12: false,
    }).format(instant);

  it('returns transforms correctly', () => {
    expect(timeZoneOptions()[0]).toStrictEqual({
      value: 'Etc/GMT+12',
      label: 'International Date Line West (GMT−12:00)',
    });
  });

  it('only offers zones the Intl API accepts', () => {
    const rejected = timeZoneOptions()
      .map(option => option.value)
      .filter(value => {
        try {
          // Called without `new` so eslint's no-new rule stays happy; it
          // validates the zone either way.
          Intl.DateTimeFormat('en-US', { timeZone: value });
          return false;
        } catch {
          return true;
        }
      });

    expect(rejected).toStrictEqual([]);
  });

  it('labels every option with an offset its zone observes', () => {
    const january = new Date('2026-01-15T12:00:00Z');
    const july = new Date('2026-07-15T12:00:00Z');

    const mismatched = timeZoneOptions()
      .filter(({ label, value }) => {
        const labelled = label.match(/\(GMT([+\u2212-]\d{2}:\d{2})\)/)?.[1];
        if (!labelled) return false;
        const normalised = labelled.replace('\u2212', '-');
        return ![offsetAt(value, january), offsetAt(value, july)].includes(
          normalised
        );
      })
      .map(({ label, value }) => `${label} -> ${value}`);

    expect(mismatched).toStrictEqual([]);
  });

  it('resolves a saved zone to the city that names it', () => {
    // Several cities share one zone, and the editor resolves a saved value
    // with find(), so whichever option comes first is the one an admin sees.
    const resolved = value =>
      timeZoneOptions().find(option => option.value === value).label;

    expect(resolved('Asia/Almaty')).toMatch(/^Almaty/);
    expect(resolved('Asia/Dhaka')).toMatch(/^Dhaka/);
  });

  it('puts Astana on Kazakhstan time, not Dhaka', () => {
    // Kazakhstan left UTC+6 on 2024-03-01, so an Astana option pointing at
    // Asia/Dhaka now reads an hour ahead of the city it names.
    const instant = new Date('2026-07-15T12:00:00Z');
    const astana = timeZoneOptions().find(option =>
      option.label.startsWith('Astana')
    );

    expect(hourAt(astana.value, instant)).toStrictEqual(
      hourAt('Asia/Almaty', instant)
    );
  });
});
