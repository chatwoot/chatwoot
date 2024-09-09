import { computed, ref } from 'vue';
import { utcToZonedTime } from 'date-fns-tz';
import { isTimeAfter } from 'shared/helpers/DateHelper';
import { useI18n } from 'dashboard/composables/useI18n';
import { useNextAvailabilityTime } from './useNextAvailabilityTime';
import { useMapGetter } from 'dashboard/composables/store';

export const useAvailability = () => {
  const availableAgents = useMapGetter('agent/availableAgents');

  const { t } = useI18n();
  const { timeLeftToBackInOnline } = useNextAvailabilityTime();
  const channelConfig = ref(window.chatwootWebChannel);

  const replyTimeStatus = computed(() => {
    switch (channelConfig.value.replyTime) {
      case 'in_a_few_minutes':
        return t('REPLY_TIME.IN_A_FEW_MINUTES');
      case 'in_a_few_hours':
        return t('REPLY_TIME.IN_A_FEW_HOURS');
      case 'in_a_day':
        return t('REPLY_TIME.IN_A_DAY');
      default:
        return t('REPLY_TIME.IN_A_FEW_HOURS');
    }
  });

  function getDateWithOffset(utcOffset) {
    return utcToZonedTime(new Date().toISOString(), utcOffset);
  }

  const currentDayAvailability = computed(() => {
    const { utcOffset, workingHours } = channelConfig.value;
    const dayOfTheWeek = getDateWithOffset(utcOffset).getDay();
    const [workingHourConfig = {}] = workingHours.filter(
      workingHour => workingHour.day_of_week === dayOfTheWeek
    );
    return {
      closedAllDay: workingHourConfig.closed_all_day,
      openHour: workingHourConfig.open_hour,
      openMinute: workingHourConfig.open_minutes,
      closeHour: workingHourConfig.close_hour,
      closeMinute: workingHourConfig.close_minutes,
      openAllDay: workingHourConfig.open_all_day,
    };
  });

  const isInBetweenTheWorkingHours = computed(() => {
    const {
      openHour,
      openMinute,
      closeHour,
      closeMinute,
      closedAllDay,
      openAllDay,
    } = currentDayAvailability.value;

    if (openAllDay) return true;
    if (closedAllDay) return false;

    const { utcOffset } = channelConfig.value;
    const today = getDateWithOffset(utcOffset);
    const currentHours = today.getHours();
    const currentMinutes = today.getMinutes();

    const isAfterStartTime = isTimeAfter(
      currentHours,
      currentMinutes,
      openHour,
      openMinute
    );
    const isBeforeEndTime = isTimeAfter(
      closeHour,
      closeMinute,
      currentHours,
      currentMinutes
    );
    return isAfterStartTime && isBeforeEndTime;
  });

  const isOnline = computed(() => {
    const { workingHoursEnabled } = channelConfig.value;
    const anyAgentOnline = availableAgents.value.length > 0;

    if (workingHoursEnabled) {
      return isInBetweenTheWorkingHours.value;
    }
    return anyAgentOnline;
  });

  const replyWaitMessage = computed(() => {
    const { workingHoursEnabled } = channelConfig.value;
    if (workingHoursEnabled) {
      return isOnline.value
        ? replyTimeStatus.value
        : `${t('REPLY_TIME.BACK_IN')} ${timeLeftToBackInOnline.value}`;
    }
    return isOnline.value
      ? replyTimeStatus.value
      : t('TEAM_AVAILABILITY.OFFLINE');
  });

  const outOfOfficeMessage = computed(
    () => channelConfig.value.outOfOfficeMessage
  );

  const isInBusinessHours = computed(() => {
    const { workingHoursEnabled } = channelConfig.value;
    return workingHoursEnabled ? isInBetweenTheWorkingHours.value : true;
  });

  return {
    channelConfig,
    replyTimeStatus,
    currentDayAvailability,
    isInBetweenTheWorkingHours,
    isOnline,
    replyWaitMessage,
    outOfOfficeMessage,
    isInBusinessHours,
  };
};
