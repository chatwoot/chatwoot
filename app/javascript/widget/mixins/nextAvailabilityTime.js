export default {
  data() {
    return {
      dayNames: {
        0: 'Sunday',
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
      },
    };
  },
  computed: {
    channelConfig() {
      return window.chatwootWebChannel;
    },
    workingHoursEnabled() {
      const { workingHoursEnabled } = this.channelConfig;
      return workingHoursEnabled;
    },
    workingHours() {
      if (this.workingHoursEnabled) {
        return this.channelConfig.workingHours;
      }
      return null;
    },
    currentDayWorkingHours() {
      if (this.workingHoursEnabled) {
        return this.workingHours.find(
          slot => slot.day_of_week === this.currentDay
        );
      }
      return null;
    },
    nextDayWorkingHours() {
      if (this.workingHoursEnabled) {
        let nextDay = this.currentDay === 6 ? 0 : this.currentDay + 1;
        let nextWorkingHour = this.workingHours.find(
          slot => slot.day_of_week === nextDay
        );
        while (nextWorkingHour && nextWorkingHour.closed_all_day) {
          let nextAvailableDay = nextDay === 6 ? 0 : nextDay + 1;
          nextWorkingHour = this.workingHours.find(
            slot => slot.day_of_week === nextAvailableDay
          );
          nextDay = nextAvailableDay;
        }
        return nextWorkingHour;
      }
      return null;
    },
    presentHour() {
      return new Date().getHours();
    },
    presentMinute() {
      return new Date().getMinutes();
    },
    currentDay() {
      const date = new Date();
      const day = date.getDay();
      const currentDay = Object.keys(this.dayNames).find(
        key => this.dayNames[key] === this.dayNames[day]
      );
      return Number(currentDay);
    },
    currentDayOpenHour() {
      return this.workingHoursEnabled
        ? this.currentDayWorkingHours.open_hour
        : null;
    },
    currentDayOpenMinute() {
      return this.workingHoursEnabled
        ? this.currentDayWorkingHours.open_minutes
        : null;
    },
    currentDayCloseHour() {
      return this.workingHoursEnabled
        ? this.currentDayWorkingHours.close_hour
        : null;
    },
    nextDayOpenHour() {
      return this.workingHoursEnabled
        ? this.nextDayWorkingHours.open_hour
        : null;
    },
    nextDayOpenMinute() {
      return this.workingHoursEnabled
        ? this.nextDayWorkingHours.open_minutes
        : null;
    },
    dayDiff() {
      if (this.workingHoursEnabled) {
        const currentDay = this.currentDay;
        const nextDay = this.nextDayWorkingHours.day_of_week;
        const totalDays = 6;
        return nextDay > currentDay
          ? nextDay - currentDay
          : totalDays - currentDay + nextDay;
      }
      return null;
    },
    hoursAndMinutesBackInOnline() {
      if (this.presentHour > this.currentDayCloseHour) {
        return this.getHoursAndMinutesUntilNextDayOpen(
          this.nextDayOpenHour,
          this.nextDayOpenMinute,
          this.currentDayCloseHour
        );
      }
      return this.getHoursAndMinutesUntilNextDayOpen(
        this.currentDayOpenHour,
        this.currentDayOpenMinute,
        this.currentDayCloseHour
      );
    },
    hoursLeftToBackInOnline() {
      const hoursAndMinutesLeft = this.hoursAndMinutesBackInOnline;
      const hoursLeft = hoursAndMinutesLeft.hours;
      const minutesLeft = hoursAndMinutesLeft.minutes;
      const hoursLeftString = `${hoursLeft} hour${hoursLeft === 1 ? '' : 's'}`;
      const minutesLeftString =
        minutesLeft > 0
          ? `${minutesLeft} minute${minutesLeft === 1 ? '' : 's'}`
          : 'some time';

      if (this.dayDiff > 1) {
        return `${this.dayDiff} days`;
      }
      return hoursLeft > 0
        ? `${hoursLeftString} and ${minutesLeftString}`
        : minutesLeftString;
    },
  },
  methods: {
    getHoursAndMinutesUntilNextDayOpen(
      openHour,
      openMinutes,
      currentDayCloseHour
    ) {
      const presentHour = this.presentHour;
      const presentMinute = this.presentMinute;
      if (currentDayCloseHour < openHour) {
        openHour += 24;
      }
      let diffMinutes =
        openHour * 60 + openMinutes - (presentHour * 60 + presentMinute);
      if (diffMinutes < 0) {
        diffMinutes += 24 * 60;
      }
      let diffHours = Math.floor(diffMinutes / 60);
      diffMinutes %= 60;
      return { hours: diffHours, minutes: diffMinutes };
    },
  },
};
