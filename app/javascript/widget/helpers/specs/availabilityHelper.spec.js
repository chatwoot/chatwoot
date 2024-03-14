import { getNextAvailabilityMessage } from '../availabilityHelper';

describe('getNextAvailabilityMessage with out timezone', () => {
  const working_hours = [
    {
      id: 8,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 0,
      closed_all_day: true,
      open_hour: null,
      open_minutes: null,
      close_hour: null,
      close_minutes: null,
      created_at: '2024-01-08T06:12:53.980Z',
      updated_at: '2024-01-08T06:12:53.980Z',
      open_all_day: false,
    },
    {
      id: 9,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 1,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 17,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.982Z',
      updated_at: '2024-01-08T06:12:53.982Z',
      open_all_day: false,
    },
    {
      id: 10,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 2,
      closed_all_day: true,
      open_hour: 15,
      open_minutes: 0,
      close_hour: 23,
      close_minutes: 30,
      created_at: '2024-01-08T06:12:53.983Z',
      updated_at: '2024-03-12T06:54:00.313Z',
      open_all_day: false,
    },
    {
      id: 11,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 3,
      closed_all_day: true,
      open_hour: null,
      open_minutes: null,
      close_hour: null,
      close_minutes: null,
      created_at: '2024-01-08T06:12:53.984Z',
      updated_at: '2024-03-13T07:15:41.249Z',
      open_all_day: false,
    },
    {
      id: 12,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 4,
      closed_all_day: false,
      open_hour: 15,
      open_minutes: 0,
      close_hour: 20,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.985Z',
      updated_at: '2024-03-13T07:21:31.430Z',
      open_all_day: false,
    },
    {
      id: 13,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 5,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 17,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.986Z',
      updated_at: '2024-01-08T06:12:53.986Z',
      open_all_day: false,
    },
    {
      id: 14,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 6,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 7,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.987Z',
      updated_at: '2024-01-08T06:12:53.987Z',
      open_all_day: false,
    },
  ];
  test('returns correct message for less than a minute', () => {
    const lessThanMinute = new Date('2024-03-14T14:59:59'); // Current time + 59 seconds
    expect(getNextAvailabilityMessage(working_hours, lessThanMinute)).toBe(
      'We will be back online in less than a minute.'
    );
  });

  test('returns correct message for less than 10 minutes', () => {
    const lessThan10Minutes = new Date('2024-03-14T14:50:00'); // Current time + 9 minutes
    expect(getNextAvailabilityMessage(working_hours, lessThan10Minutes)).toBe(
      'We will be back online in 10 minutes.'
    );
  });

  test('returns minutes message for less than an hour', () => {
    const lessThanHour = new Date('2024-03-14T14:45:00'); // Current time + 30 minutes
    expect(getNextAvailabilityMessage(working_hours, lessThanHour)).toBe(
      'We will be back online in 15 minutes.'
    );
  });

  test('returns correct message for greater than 2 hours', () => {
    const lessThanHour = new Date('2024-03-14T12:30:00'); // Current time + 30 minutes
    expect(getNextAvailabilityMessage(working_hours, lessThanHour)).toBe(
      'We will be back online in 2 hours'
    );
  });

  test('returns correct message for next day', () => {
    const nextDay = new Date('2024-03-14T00:00:00'); // Next day
    working_hours[4].closed_all_day = true;
    expect(getNextAvailabilityMessage(working_hours, nextDay)).toBe(
      'We will be back online tomorrow'
    );
  });

  test('returns correct message for specific day', () => {
    const specificDay = new Date('2024-03-14T00:00:00'); // Next day
    working_hours[4].closed_all_day = true;
    working_hours[5].closed_all_day = true;
    expect(getNextAvailabilityMessage(working_hours, specificDay)).toBe(
      'We will be back online on Saturday'
    );
  });

  test('returns correct message for next week', () => {
    const nextWeek = new Date('2024-03-21T21:00:00'); // Next day
    working_hours[5].closed_all_day = true;
    working_hours[6].closed_all_day = true;
    working_hours[0].closed_all_day = true;
    working_hours[1].closed_all_day = true;
    working_hours[2].closed_all_day = true;
    working_hours[3].closed_all_day = true;
    working_hours[4].closed_all_day = false;
    expect(getNextAvailabilityMessage(working_hours, nextWeek)).toBe(
      'We will be back online on Thursday'
    );
  });
  afterEach(() => {
    jest.useRealTimers();
  });
});

describe('getNextAvailabilityMessage with timezone', () => {
  const working_hours = [
    {
      id: 8,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 0,
      closed_all_day: true,
      open_hour: null,
      open_minutes: null,
      close_hour: null,
      close_minutes: null,
      created_at: '2024-01-08T06:12:53.980Z',
      updated_at: '2024-01-08T06:12:53.980Z',
      open_all_day: false,
    },
    {
      id: 9,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 1,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 17,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.982Z',
      updated_at: '2024-01-08T06:12:53.982Z',
      open_all_day: false,
    },
    {
      id: 10,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 2,
      closed_all_day: true,
      open_hour: 15,
      open_minutes: 0,
      close_hour: 23,
      close_minutes: 30,
      created_at: '2024-01-08T06:12:53.983Z',
      updated_at: '2024-03-12T06:54:00.313Z',
      open_all_day: false,
    },
    {
      id: 11,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 3,
      closed_all_day: true,
      open_hour: null,
      open_minutes: null,
      close_hour: null,
      close_minutes: null,
      created_at: '2024-01-08T06:12:53.984Z',
      updated_at: '2024-03-13T07:15:41.249Z',
      open_all_day: false,
    },
    {
      id: 12,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 4,
      closed_all_day: false,
      open_hour: 15,
      open_minutes: 0,
      close_hour: 20,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.985Z',
      updated_at: '2024-03-13T07:21:31.430Z',
      open_all_day: false,
    },
    {
      id: 13,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 5,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 17,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.986Z',
      updated_at: '2024-01-08T06:12:53.986Z',
      open_all_day: false,
    },
    {
      id: 14,
      inbox_id: 2,
      account_id: 1,
      day_of_week: 6,
      closed_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 7,
      close_minutes: 0,
      created_at: '2024-01-08T06:12:53.987Z',
      updated_at: '2024-01-08T06:12:53.987Z',
      open_all_day: false,
    },
  ];

  test('returns correct message for less than a minute', () => {
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T19:50:00'));
    const lessThan10Minutes = new Date('2024-03-14T19:50:00');
    expect(
      getNextAvailabilityMessage(
        working_hours,
        lessThan10Minutes,
        'America/New_York'
      )
    ).toBe('We will be back online in less than a minute.');
  });

  test('returns correct message for less than 10 minutes', () => {
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T19:50:00'));
    const lessThan10Minutes = new Date('2024-03-14T19:50:00');
    expect(
      getNextAvailabilityMessage(
        working_hours,
        lessThan10Minutes,
        'America/New_York'
      )
    ).toBe('We will be back online in less than a minute.');
  });

  test('returns correct message for greater than 2 hours', () => {
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T14:59:59'));
    const lessThanMinute = new Date('2024-03-14T14:59:59');
    expect(
      getNextAvailabilityMessage(
        working_hours,
        lessThanMinute,
        'America/New_York'
      )
    ).toBe('We will be back online in 4 hours');
  });

  test('returns correct message for next day', () => {
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T14:59:59'));
    const nextDay = new Date('2024-03-15T00:00:00'); // Next day
    working_hours[4].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(working_hours, nextDay, 'America/New_York')
    ).toBe('We will be back online tomorrow');
  });

  test('returns correct message for specific day', () => {
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T14:59:59'));
    const specificDay = new Date('2024-03-17T00:00:00'); // Next day
    working_hours[4].closed_all_day = true;
    working_hours[5].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(working_hours, specificDay, 'America/New_York')
    ).toBe('We will be back online on Monday');
  });
});
