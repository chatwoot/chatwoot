import { getNextAvailabilityMessage } from '../availabilityHelper';

const workingHoursCommon = [
  { id: 8, inbox_id: 2, account_id: 1, day_of_week: 0, closed_all_day: true },
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
  },
  { id: 11, inbox_id: 2, account_id: 1, day_of_week: 3, closed_all_day: true },
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
  },
];

describe('getNextAvailabilityMessage without timezone', () => {
  let workingHours;

  beforeEach(() => {
    workingHours = JSON.parse(JSON.stringify(workingHoursCommon));
  });

  test('less than a minute', () =>
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T14:59:59'))
    ).toBe('We will be back online in less than a minute.'));
  test('less than 10 minutes', () =>
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T14:50:00'))
    ).toBe('We will be back online in 10 minutes.'));
  test('minutes message for less than an hour', () =>
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T14:45:00'))
    ).toBe('We will be back online in 15 minutes.'));
  test('greater than 2 hours', () =>
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T12:30:00'))
    ).toBe('We will be back online in 2 hours'));
  test('next day', () => {
    workingHours[4].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T00:00:00'))
    ).toBe('We will be back online tomorrow');
  });
  test('specific day', () => {
    workingHours[4].closed_all_day = true;
    workingHours[5].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-14T00:00:00'))
    ).toBe('We will be back online on Saturday');
  });
  test('next week', () => {
    workingHours[5].closed_all_day = true;
    workingHours[6].closed_all_day = true;
    workingHours[0].closed_all_day = true;
    workingHours[1].closed_all_day = true;
    workingHours[2].closed_all_day = true;
    workingHours[3].closed_all_day = true;
    workingHours[4].closed_all_day = false;
    expect(
      getNextAvailabilityMessage(workingHours, new Date('2024-03-21T21:00:00'))
    ).toBe('We will be back online on Thursday');
  });
});

describe('getNextAvailabilityMessage with timezone', () => {
  let workingHours;

  beforeEach(() => {
    workingHours = JSON.parse(JSON.stringify(workingHoursCommon));
    jest.useFakeTimers('modern');
    jest.setSystemTime(new Date('2024-03-14T19:50:00'));
  });

  afterEach(() => jest.useRealTimers());

  test('less than a minute', () =>
    expect(
      getNextAvailabilityMessage(
        workingHours,
        new Date('2024-03-14T19:50:00'),
        'America/New_York'
      )
    ).toBe('We will be back online in less than a minute.'));
  test('less than 10 minutes', () =>
    expect(
      getNextAvailabilityMessage(
        workingHours,
        new Date('2024-03-14T19:50:00'),
        'America/New_York'
      )
    ).toBe('We will be back online in less than a minute.'));
  test('greater than 2 hours', () =>
    expect(
      getNextAvailabilityMessage(
        workingHours,
        new Date('2024-03-14T14:59:59'),
        'America/New_York'
      )
    ).toBe('We will be back online in 4 hours'));
  test('next day', () => {
    workingHours[4].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(
        workingHours,
        new Date('2024-03-15T00:00:00'),
        'America/New_York'
      )
    ).toBe('We will be back online tomorrow');
  });
  test('specific day', () => {
    workingHours[4].closed_all_day = true;
    workingHours[5].closed_all_day = true;
    expect(
      getNextAvailabilityMessage(
        workingHours,
        new Date('2024-03-17T00:00:00'),
        'America/New_York'
      )
    ).toBe('We will be back online on Monday');
  });
});
