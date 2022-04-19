import { utcToZonedTime } from 'date-fns-tz';
import { isTimeAfter } from 'shared/helpers/DateHelper';

export default {
  computed: {
    channelConfig() {
      return window.chatwootWebChannel;
    },
    replyTime() {
      return window.chatwootWebChannel.replyTime;
    },
    replyTimeStatus() {
      switch (this.replyTime) {
        case 'in_a_few_minutes':
          return this.$t('REPLY_TIME.IN_A_FEW_MINUTES');
        case 'in_a_few_hours':
          return this.$t('REPLY_TIME.IN_A_FEW_HOURS');
        case 'in_a_day':
          return this.$t('REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
    outOfOfficeMessage() {
      return this.channelConfig.outOfOfficeMessage;
    },
    isInBetweenTheWorkingHours() {
      const {
        openHour,
        openMinute,
        closeHour,
        closeMinute,
        closedAllDay,
        openAllDay,
      } = this.currentDayAvailability;

      if (openAllDay || closedAllDay) {
        return true;
      }

      const { utcOffset } = this.channelConfig;
      const today = this.getDateWithOffset(utcOffset);
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
    },
    currentDayAvailability() {
      const { utcOffset } = this.channelConfig;
      const dayOfTheWeek = this.getDateWithOffset(utcOffset).getDay();
      const [workingHourConfig = {}] = this.channelConfig.workingHours.filter(
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
    },
    isInBusinessHours() {
      const { workingHoursEnabled } = this.channelConfig;
      return workingHoursEnabled ? this.isInBetweenTheWorkingHours : true;
    },
  },

  methods: {
    getDateWithOffset(utcOffset) {
      return utcToZonedTime(new Date().toISOString(), utcOffset);
    },
  },
};
