import { ref } from 'vue';
import { useAvailability } from '../useAvailability';
import * as useNextAvailabilityTime from '../useNextAvailabilityTime';
import * as useI18n from 'dashboard/composables/useI18n';
import * as useMapGetter from 'dashboard/composables/store';

vi.mock('../useNextAvailabilityTime');
vi.mock('dashboard/composables/useI18n');
vi.mock('dashboard/composables/store');

describe('useAvailability', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    useNextAvailabilityTime.useNextAvailabilityTime.mockReturnValue({
      timeLeftToBackInOnline: ref('2 hours'),
    });
    useI18n.useI18n.mockReturnValue({
      t: vi.fn(key => key),
    });
    useMapGetter.useMapGetter.mockReturnValue(ref([]));

    global.chatwootWebChannel = {
      workingHoursEnabled: true,
      workingHours: [
        {
          day_of_week: 3,
          closed_all_day: false,
          open_hour: 8,
          open_minutes: 30,
          close_hour: 17,
          close_minutes: 35,
          open_all_day: false,
        },
        {
          day_of_week: 4,
          closed_all_day: false,
          open_hour: 8,
          open_minutes: 30,
          close_hour: 17,
          close_minutes: 30,
          open_all_day: false,
        },
      ],
      utcOffset: '-07:00',
      replyTime: 'in_a_few_hours',
    };
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns valid isInBetweenTheWorkingHours if in different timezone', () => {
    vi.setSystemTime(new Date('Thu Apr 14 2022 06:04:46 GMT+0530'));
    const { isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(true);
  });

  it('returns valid isInBetweenTheWorkingHours if in same timezone', () => {
    global.chatwootWebChannel.utcOffset = '+05:30';
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(true);
  });

  it('returns false if closed all day', () => {
    global.chatwootWebChannel.utcOffset = '-07:00';
    global.chatwootWebChannel.workingHours = [
      { day_of_week: 3, closed_all_day: true },
    ];
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(false);
  });

  it('returns true if open all day', () => {
    global.chatwootWebChannel.utcOffset = '-07:00';
    global.chatwootWebChannel.workingHours = [
      { day_of_week: 3, open_all_day: true },
    ];
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(true);
  });

  it('returns correct replyTimeStatus', () => {
    const { replyTimeStatus } = useAvailability();
    expect(replyTimeStatus.value).toBe('REPLY_TIME.IN_A_FEW_HOURS');
  });

  it('returns correct replyWaitMessage when online', () => {
    global.chatwootWebChannel.workingHoursEnabled = true;
    global.chatwootWebChannel.utcOffset = '+05:30';
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { replyWaitMessage, isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(true);
    expect(replyWaitMessage.value).toBe('REPLY_TIME.IN_A_FEW_HOURS');
  });

  it('returns correct replyWaitMessage when offline', () => {
    global.chatwootWebChannel.workingHoursEnabled = true;
    global.chatwootWebChannel.workingHours = [
      { day_of_week: 3, closed_all_day: true },
    ];
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { replyWaitMessage } = useAvailability();
    expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_IN 2 hours');
  });

  it('returns correct isInBusinessHours', () => {
    global.chatwootWebChannel.workingHoursEnabled = true;
    global.chatwootWebChannel.utcOffset = '+05:30';
    vi.setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const { isInBusinessHours, isInBetweenTheWorkingHours } = useAvailability();
    expect(isInBetweenTheWorkingHours.value).toBe(true);
    expect(isInBusinessHours.value).toBe(true);
  });
});
