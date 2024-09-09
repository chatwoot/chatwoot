import { useNextAvailabilityTime } from '../useNextAvailabilityTime';
import { useI18n } from 'dashboard/composables/useI18n';
import { generateRelativeTime } from 'shared/helpers/DateHelper';
import { utcToZonedTime } from 'date-fns-tz';

vi.mock('dashboard/composables/useI18n');

describe('useNextAvailabilityTime', () => {
  const chatwootWebChannel = {
    workingHoursEnabled: true,
    workingHours: [
      {
        day_of_week: 0,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 1,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 2,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 3,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 4,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 5,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 6,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
    ],
    timezone: 'UTC',
    locale: 'en',
  };

  beforeEach(() => {
    window.chatwootWebChannel = chatwootWebChannel;
    useI18n.mockReturnValue({
      t: vi.fn(key => {
        if (key === 'DAY_NAMES') {
          return [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
          ];
        }
        return key;
      }),
    });
    generateRelativeTime.mockImplementation((value, unit) => {
      if (unit === 'hour') return `in ${value} hour${value > 1 ? 's' : ''}`;
      if (unit === 'minutes')
        return `in ${value} minute${value > 1 ? 's' : ''}`;
      if (unit === 'days') return value === 1 ? 'tomorrow' : `in ${value} days`;
      return `in ${value} ${unit}`;
    });
    utcToZonedTime.mockImplementation(date => new Date(date));
  });

  afterEach(() => {
    delete window.chatwootWebChannel;
    vi.clearAllMocks();
  });

  it('should return day names', () => {
    const { dayNames } = useNextAvailabilityTime();
    expect(dayNames).toEqual([
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ]);
  });

  it('should return channelConfig', () => {
    const { channelConfig } = useNextAvailabilityTime();
    expect(channelConfig.value).toEqual(chatwootWebChannel);
  });

  it('should return workingHours', () => {
    const { workingHours } = useNextAvailabilityTime();
    expect(workingHours.value).toEqual(chatwootWebChannel.workingHours);
  });

  it('should return currentDayWorkingHours', () => {
    const { currentDayWorkingHours } = useNextAvailabilityTime();
    const currentDay = new Date().getDay();
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === currentDay
    );
    expect(currentDayWorkingHours.value).toEqual(expectedWorkingHours);
  });

  it('should return nextDayWorkingHours', () => {
    const { nextDayWorkingHours } = useNextAvailabilityTime();
    const currentDay = new Date().getDay();
    const nextDay = currentDay === 6 ? 0 : currentDay + 1;
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === nextDay
    );
    expect(nextDayWorkingHours.value).toEqual(expectedWorkingHours);
  });

  it('should return presentHour', () => {
    const { presentHour } = useNextAvailabilityTime();
    expect(presentHour.value).toBe(new Date().getUTCHours());
  });

  it('should return presentMinute', () => {
    const { presentMinute } = useNextAvailabilityTime();
    expect(presentMinute.value).toBe(new Date().getUTCMinutes());
  });

  it('should return currentDay', () => {
    const { currentDay } = useNextAvailabilityTime();
    const date = new Date();
    const day = date.getUTCDay();
    expect(currentDay.value).toBe(day);
  });

  it('should return currentDayTimings', () => {
    const { currentDayTimings, currentDayWorkingHours } =
      useNextAvailabilityTime();
    const {
      open_hour: openHour,
      open_minutes: openMinute,
      close_hour: closeHour,
    } = currentDayWorkingHours.value;
    expect(currentDayTimings.value).toEqual({
      openHour,
      openMinute,
      closeHour,
    });
  });

  it('should return nextDayTimings', () => {
    const { nextDayTimings, nextDayWorkingHours } = useNextAvailabilityTime();
    const { open_hour: openHour, open_minutes: openMinute } =
      nextDayWorkingHours.value;
    expect(nextDayTimings.value).toEqual({
      openHour,
      openMinute,
    });
  });

  it('should return dayDiff', () => {
    const { dayDiff, currentDay, nextDayWorkingHours } =
      useNextAvailabilityTime();
    const nextDay = nextDayWorkingHours.value.day_of_week;
    const totalDays = 6;
    const expectedDayDiff =
      nextDay > currentDay.value
        ? nextDay - currentDay.value - 1
        : totalDays - currentDay.value + nextDay;
    expect(dayDiff.value).toEqual(expectedDayDiff);
  });

  it('should return dayNameOfNextWorkingDay', () => {
    const { dayNameOfNextWorkingDay, nextDayWorkingHours, dayNames } =
      useNextAvailabilityTime();
    const nextDay = nextDayWorkingHours.value.day_of_week;
    const expectedDayName = dayNames[nextDay];
    expect(dayNameOfNextWorkingDay.value).toEqual(expectedDayName);
  });

  it('should return hoursAndMinutesBackInOnline', () => {
    const { hoursAndMinutesBackInOnline } = useNextAvailabilityTime();
    expect(hoursAndMinutesBackInOnline.value).toBeDefined();
    expect(typeof hoursAndMinutesBackInOnline.value.hoursLeft).toBe('number');
    expect(typeof hoursAndMinutesBackInOnline.value.minutesLeft).toBe('number');
  });

  // Time-based tests
  describe('time-based tests', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should return in 30 minutes', () => {
      vi.setSystemTime(new Date('2022-04-14T17:30:00.000Z')); // Thursday
      chatwootWebChannel.workingHours[4].open_hour = 18;
      chatwootWebChannel.workingHours[4].open_minutes = 0;
      chatwootWebChannel.workingHours[4].close_hour = 23;

      const { timeLeftToBackInOnline, setTimeSlot } = useNextAvailabilityTime();
      setTimeSlot();
      expect(timeLeftToBackInOnline.value).toBe('in 30 minutes');
    });

    it('should return in 2 hours', () => {
      vi.setSystemTime(new Date('2022-04-14T17:00:00.000Z')); // Thursday
      chatwootWebChannel.workingHours[4].open_hour = 19;
      chatwootWebChannel.workingHours[4].open_minutes = 0;
      chatwootWebChannel.workingHours[4].close_hour = 23;

      const { timeLeftToBackInOnline, setTimeSlot } = useNextAvailabilityTime();
      setTimeSlot();
      expect(timeLeftToBackInOnline.value).toBe('in 2 hours');
    });

    it('should return at 10:00 AM', () => {
      vi.setSystemTime(new Date('2022-04-14T22:00:00.000Z')); // Thursday
      chatwootWebChannel.workingHours[5].open_hour = 10; // Friday
      chatwootWebChannel.workingHours[5].open_minutes = 0;
      chatwootWebChannel.workingHours[5].close_hour = 18;

      const { timeLeftToBackInOnline, setTimeSlot } = useNextAvailabilityTime();
      setTimeSlot();
      expect(timeLeftToBackInOnline.value).toBe('at 10:00 AM');
    });

    it('should return tomorrow', () => {
      vi.setSystemTime(new Date('2022-04-14T22:00:00.000Z')); // Thursday
      chatwootWebChannel.workingHours[5].open_hour = 9; // Friday
      chatwootWebChannel.workingHours[5].open_minutes = 0;
      chatwootWebChannel.workingHours[5].close_hour = 17;

      const { timeLeftToBackInOnline, setTimeSlot } = useNextAvailabilityTime();
      setTimeSlot();
      expect(timeLeftToBackInOnline.value).toBe('tomorrow');
    });

    it('should return on Saturday', () => {
      vi.setSystemTime(new Date('2022-04-14T22:00:00.000Z')); // Thursday
      chatwootWebChannel.workingHours[4].open_hour = 9;
      chatwootWebChannel.workingHours[4].close_hour = 17;
      chatwootWebChannel.workingHours[5].closed_all_day = true; // Friday closed

      const { timeLeftToBackInOnline, setTimeSlot } = useNextAvailabilityTime();
      setTimeSlot();
      expect(timeLeftToBackInOnline.value).toBe('on Saturday');
    });
  });
});
