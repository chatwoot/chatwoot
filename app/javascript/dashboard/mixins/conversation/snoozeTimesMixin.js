import {
  getUnixTime,
  addHours,
  addWeeks,
  startOfTomorrow,
  startOfWeek,
} from 'date-fns';

export default {
  computed: {
    snoozeTimes() {
      return {
        // tomorrow  = 9AM next day
        tomorrow: getUnixTime(addHours(startOfTomorrow(), 9)),
        // next week = 9AM Monday, next week
        nextWeek: getUnixTime(
          addHours(startOfWeek(addWeeks(new Date(), 1), { weekStartsOn: 1 }), 9)
        ),
      };
    },
  },
};
