import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  getWorkingHoursInfo,
  getNextAvailableTime,
} from 'widget/helpers/availabilityHelpers';

export function useAvailability(availableAgents = ref([])) {
  const { t } = useI18n();

  // Channel configuration
  const config = computed(() => {
    const channel = window.chatwootWebChannel ?? {};
    return {
      workingHours: channel.workingHours ?? [],
      timezone: channel.timezone ?? 'UTC',
      locale: channel.locale ?? 'en',
      utcOffset: channel.utcOffset ?? channel.timezone ?? 'UTC',
      workingHoursEnabled: channel.workingHoursEnabled ?? false,
      replyTime: channel.replyTime ?? 'in_a_few_hours',
      outOfOfficeMessage: channel.outOfOfficeMessage,
    };
  });

  // Working hours info
  const workingHoursInfo = computed(() =>
    getWorkingHoursInfo(
      config.value.workingHours,
      config.value.utcOffset,
      config.value.workingHoursEnabled
    )
  );

  // Online status
  const anyAgentOnline = computed(() => availableAgents.value?.length > 0);
  const isOnline = computed(() =>
    config.value.workingHoursEnabled
      ? workingHoursInfo.value.isInWorkingHours
      : anyAgentOnline.value
  );

  // Next available time
  const nextAvailableTime = computed(() =>
    getNextAvailableTime(workingHoursInfo.value, config.value.locale)
  );

  // Reply time status
  const replyTimeStatus = computed(() =>
    t(`REPLY_TIME.${config.value.replyTime.toUpperCase()}`)
  );

  // Reply wait message
  const replyWaitMessage = computed(() => {
    if (!config.value.workingHoursEnabled) {
      return isOnline.value
        ? replyTimeStatus.value
        : t('TEAM_AVAILABILITY.OFFLINE');
    }

    if (workingHoursInfo.value.allClosed) {
      return t('TEAM_AVAILABILITY.OFFLINE');
    }

    if (isOnline.value) {
      return replyTimeStatus.value;
    }

    // Handle next available time
    const { type, value } = nextAvailableTime.value;

    return t(`REPLY_TIME.${type}`, { time: value });
  });

  return {
    // Status
    isOnline,
    isInBusinessHours: workingHoursInfo.value.isInWorkingHours,

    // Messages
    replyWaitMessage,
    replyTimeStatus,
    outOfOfficeMessage: config.value.outOfOfficeMessage,

    // Config
    channelConfig: computed(() => window.chatwootWebChannel || {}),
    workingHoursEnabled: config.value.workingHoursEnabled,
    replyTime: config.value.replyTime,
  };
}
