import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ref } from 'vue';
import { useAvailability } from '../../composables/useAvailability';

vi.mock('dashboard/composables/useI18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

describe('useAvailability', () => {
  beforeEach(() => {
    vi.useFakeTimers();
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
      replyTime: 'in_a_few_minutes',
    };
  });

  it('returns correct replyTimeStatus', () => {
    const availableAgents = ref([]);
    const { replyTimeStatus } = useAvailability(availableAgents);
    expect(replyTimeStatus.value).toBe('REPLY_TIME.IN_A_FEW_MINUTES');
  });

  it('returns correct isInBetweenTheWorkingHours when in working hours', () => {
    vi.setSystemTime(new Date('Wed Apr 13 2022 10:00:00 GMT-0700'));
    const availableAgents = ref([]);
    const { isInBetweenTheWorkingHours } = useAvailability(availableAgents);
    expect(isInBetweenTheWorkingHours.value).toBe(true);
  });

  it('returns correct isInBetweenTheWorkingHours when outside working hours', () => {
    vi.setSystemTime(new Date('Wed Apr 13 2022 18:00:00 GMT-0700'));
    const availableAgents = ref([]);
    const { isInBetweenTheWorkingHours } = useAvailability(availableAgents);
    expect(isInBetweenTheWorkingHours.value).toBe(false);
  });

  it('returns true for isInBetweenTheWorkingHours when open all day', () => {
    global.chatwootWebChannel.workingHours = [
      { day_of_week: 3, open_all_day: true },
    ];
    const availableAgents = ref([]);
    const { isInBetweenTheWorkingHours } = useAvailability(availableAgents);
    expect(isInBetweenTheWorkingHours.value).toBe(true);
  });

  it('returns false for isInBetweenTheWorkingHours when closed all day', () => {
    global.chatwootWebChannel.workingHours = [
      { day_of_week: 3, closed_all_day: true },
    ];
    const availableAgents = ref([]);
    const { isInBetweenTheWorkingHours } = useAvailability(availableAgents);
    expect(isInBetweenTheWorkingHours.value).toBe(false);
  });

  it('returns correct isOnline status when agents are available', () => {
    const availableAgents = ref([{ id: 1 }]);
    const { isOnline } = useAvailability(availableAgents);
    expect(isOnline.value).toBe(true);
  });

  it('returns correct isOnline status when no agents are available and outside working hours', () => {
    vi.setSystemTime(new Date('Wed Apr 13 2022 18:00:00 GMT-0700'));
    const availableAgents = ref([]);
    const { isOnline } = useAvailability(availableAgents);
    expect(isOnline.value).toBe(false);
  });

  it('returns correct replyWaitMessage when online', () => {
    const availableAgents = ref([{ id: 1 }]);
    const { replyWaitMessage } = useAvailability(availableAgents);
    expect(replyWaitMessage.value).toBe('REPLY_TIME.IN_A_FEW_MINUTES');
  });

  it('returns correct replyWaitMessage when offline', () => {
    vi.setSystemTime(new Date('Wed Apr 13 2022 18:00:00 GMT-0700'));
    const availableAgents = ref([]);
    const { replyWaitMessage } = useAvailability(availableAgents);
    expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_IN at 08:30 AM');
  });
});
