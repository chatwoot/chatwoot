import { computed, unref } from 'vue';
import {
  isOnline as checkIsOnline,
  isInWorkingHours as checkInWorkingHours,
} from 'widget/helpers/availabilityHelpers';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

const DEFAULT_TIMEZONE = 'UTC';
const DEFAULT_REPLY_TIME = 'in_a_few_minutes';

/**
 * Composable for availability-related logic
 * @param {Ref|Array} agents - Available agents (can be ref or raw array)
 * @returns {Object} Availability utilities and computed properties
 */
export function useAvailability(agents = []) {
  // Now receives toRef(props, 'agents') from caller, which maintains reactivity.
  // Use unref() inside computed to unwrap the ref value properly.
  // This ensures availableAgents updates when the parent's agents prop changes
  // (e.g., after API response updates the Vuex store).
  const availableAgents = computed(() => unref(agents));

  const channelConfig = computed(() => window.chatwootWebChannel || {});

  const inboxConfig = computed(() => ({
    workingHours: channelConfig.value.workingHours?.map(useCamelCase) || [],
    workingHoursEnabled: channelConfig.value.workingHoursEnabled || false,
    timezone: channelConfig.value.timezone || DEFAULT_TIMEZONE,
    utcOffset:
      channelConfig.value.utcOffset ||
      channelConfig.value.timezone ||
      DEFAULT_TIMEZONE,
    replyTime: channelConfig.value.replyTime || DEFAULT_REPLY_TIME,
  }));

  const currentTime = computed(() => new Date());

  const hasOnlineAgents = computed(() => {
    const agentList = availableAgents.value || [];
    return Array.isArray(agentList) ? agentList.length > 0 : false;
  });

  const isInWorkingHours = computed(() =>
    checkInWorkingHours(
      currentTime.value,
      inboxConfig.value.utcOffset,
      inboxConfig.value.workingHours
    )
  );

  // Check if online (considering both working hours and agents)
  const isOnline = computed(() =>
    checkIsOnline(
      inboxConfig.value.workingHoursEnabled,
      currentTime.value,
      inboxConfig.value.utcOffset,
      inboxConfig.value.workingHours,
      hasOnlineAgents.value
    )
  );

  return {
    channelConfig,
    inboxConfig,

    currentTime,
    availableAgents,
    hasOnlineAgents,

    isOnline,
    isInWorkingHours,
  };
}
