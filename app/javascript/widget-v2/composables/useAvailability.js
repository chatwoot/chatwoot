import { computed } from 'vue';
import {
  isOnline as checkIsOnline,
  isInWorkingHours as checkInWorkingHours,
} from 'widget/helpers/availabilityHelpers';
import { useConfigStore } from 'widget-v2/stores/config';
import { useAgentsStore } from 'widget-v2/stores/agents';

// availabilityHelpers expects camelCase working-hour keys; the API is snake_case.
const camelizeWorkingHour = hour => ({
  dayOfWeek: hour.day_of_week,
  openHour: hour.open_hour,
  openMinutes: hour.open_minutes,
  closeHour: hour.close_hour,
  closeMinutes: hour.close_minutes,
  openAllDay: hour.open_all_day,
  closedAllDay: hour.closed_all_day,
});

export function useAvailability() {
  const configStore = useConfigStore();
  const agentsStore = useAgentsStore();

  const workingHours = computed(() =>
    (configStore.channel.working_hours || []).map(camelizeWorkingHour)
  );

  const utcOffset = computed(
    () =>
      configStore.channel.utc_offset || configStore.channel.timezone || 'UTC'
  );

  const isInWorkingHours = computed(() =>
    checkInWorkingHours(new Date(), utcOffset.value, workingHours.value)
  );

  const isOnline = computed(() =>
    checkIsOnline(
      configStore.channel.working_hours_enabled || false,
      new Date(),
      utcOffset.value,
      workingHours.value,
      agentsStore.hasOnlineAgents
    )
  );

  const replyTimeKey = computed(
    () => configStore.channel.reply_time || 'in_a_few_minutes'
  );

  return { isOnline, isInWorkingHours, replyTimeKey };
}
