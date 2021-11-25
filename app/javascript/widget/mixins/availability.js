import compareAsc from 'date-fns/compareAsc';
import { buildDateFromTime } from 'shared/helpers/DateHelper';

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
      } = this.currentDayAvailability;
      const { utcOffset } = this.channelConfig;

      if (closedAllDay) return false;

      const startTime = buildDateFromTime(openHour, openMinute, utcOffset);
      const endTime = buildDateFromTime(closeHour, closeMinute, utcOffset);
      const isBetween =
        compareAsc(new Date(), startTime) === 1 &&
        compareAsc(endTime, new Date()) === 1;

      if (isBetween) return true;
      return false;
    },
    currentDayAvailability() {
      const dayOfTheWeek = new Date().getDay();
      const [workingHourConfig = {}] = this.channelConfig.workingHours.filter(
        workingHour => workingHour.day_of_week === dayOfTheWeek
      );
      return {
        closedAllDay: workingHourConfig.closed_all_day,
        openHour: workingHourConfig.open_hour,
        openMinute: workingHourConfig.open_minutes,
        closeHour: workingHourConfig.close_hour,
        closeMinute: workingHourConfig.close_minutes,
      };
    },
    isInBusinessHours() {
      const { workingHoursEnabled } = window.chatwootWebChannel;
      return workingHoursEnabled ? this.isInBetweenTheWorkingHours : true;
    },
  },
};
