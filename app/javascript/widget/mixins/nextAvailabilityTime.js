import {
  timeSlotParse,
  defaultTimeSlot,
} from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
const { utcToZonedTime } = require('date-fns-tz');

export default {
  data() {
    return {
      dayNames: [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
      timeSlots: [...defaultTimeSlot],
      timeSlot: {},
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
    timeZoneValue() {
      if (this.workingHoursEnabled) {
        return this.channelConfig.timezone;
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
        let nextDay = this.getNextDay(this.currentDay);
        let nextWorkingHour = this.getNextWorkingHour(nextDay);

        // It gets the next working hour for the next day. If there is no working hour for the next day,
        // it keeps iterating through the days of the week until it finds the next working hour.
        while (!nextWorkingHour) {
          nextDay = this.getNextDay(nextDay);
          nextWorkingHour = this.getNextWorkingHour(nextDay);
        }
        return nextWorkingHour;
      }
      return null;
    },
    newDateWithTimeZone() {
      const date = new Date();
      const timeZone = this.timeZoneValue;
      const zonedDate = utcToZonedTime(date, timeZone);
      return zonedDate;
    },
    presentHour() {
      return this.newDateWithTimeZone.getHours();
    },
    presentMinute() {
      return this.newDateWithTimeZone.getMinutes();
    },
    currentDay() {
      const date = this.newDateWithTimeZone;
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
      if (this.workingHoursEnabled) {
        return this.nextDayWorkingHours.open_all_day
          ? 0
          : this.nextDayWorkingHours.open_hour;
      }
      return null;
    },
    nextDayOpenMinute() {
      return this.workingHoursEnabled
        ? this.nextDayWorkingHours.open_minutes
        : null;
    },
    dayDiff() {
      // Here this is used to get the difference between current day and next working day
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
    dayNameOfNextWorkingDay() {
      if (this.workingHoursEnabled) {
        return this.dayNames[this.nextDayWorkingHours.day_of_week];
      }
      return null;
    },
    hoursAndMinutesBackInOnline() {
      if (this.presentHour >= this.currentDayCloseHour) {
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
    exactTimeInAmPm() {
      return `${this.timeSlot.day !== this.currentDay ? 'tomorrow' : ''} ${
        this.timeSlot.day !== this.currentDay ? '' : `at ${this.timeSlot.from}`
      }`;
    },
    hoursLeftValue() {
      const {
        hours: hoursLeft,
        minutes: minutesLeft,
      } = this.hoursAndMinutesBackInOnline;
      const hourString = hoursLeft === 1 ? 'hour' : 'hours';
      const roundedUpMinLeft = Math.ceil(minutesLeft / 5) * 5; // round up minutes to nearest multiple of 5
      return `in ${hoursLeft} ${hourString}${
        minutesLeft > 0 ? ` and ${roundedUpMinLeft} minutes` : ''
      }`;
    },
    minutesLeftValue() {
      const { minutes: minutesLeft } = this.hoursAndMinutesBackInOnline;
      const roundedUpMinLeft = Math.ceil(minutesLeft / 5) * 5; // round up minutes to nearest multiple of 5
      return `in ${roundedUpMinLeft} minutes`;
    },
    hoursAndMinutesToBack() {
      const {
        hours: hoursLeft,
        minutes: minutesLeft,
      } = this.hoursAndMinutesBackInOnline;
      if (hoursLeft > 3) {
        return this.exactTimeInAmPm;
      }
      if (hoursLeft > 0) {
        return this.hoursLeftValue;
      }
      if (minutesLeft > 0) {
        return this.minutesLeftValue;
      }
      return 'in some time';
    },
    timeLeftToBackInOnline() {
      if (this.dayDiff > 1 && this.presentHour >= this.currentDayCloseHour) {
        return `on ${this.dayNameOfNextWorkingDay}`;
      }
      if (this.hoursAndMinutesBackInOnline.hours >= 24) {
        return `tomorrow`;
      }
      return this.hoursAndMinutesToBack;
    },
  },
  mounted() {
    this.setTimeSlot();
  },
  methods: {
    getNextDay(day) {
      // This code calculates the next day of the week based on the current day. If the current day is Saturday (6), then the next day will be Sunday (0).
      return day === 6 ? 0 : day + 1;
    },
    getNextWorkingHour(day) {
      const workingHour = this.workingHours.find(
        slot => slot.day_of_week === day
      );
      if (workingHour && !workingHour.closed_all_day) {
        return workingHour;
      }
      return null;
    },
    getHoursAndMinutesUntilNextDayOpen(
      openHour, // If the present time is after the closing time of the current day, then the openHour will be the opening hour of the next day else it will be the opening hour of the current day.
      openMinutes, // If the present time is after the closing time of the current day, then the openMinutes will be the opening minutes of the next day else it will be the opening minutes of the current day.
      closeHour // The closeHour will be the closing hour of the current day. It will be used to calculate the time remaining until the next day's opening hours.
    ) {
      // This code calculates the time remaining until the next day's opening hours,
      // given the current time, the opening hours, and the closing hours of the current day.
      const { presentHour, presentMinute } = this;
      if (closeHour < openHour) {
        openHour += 24;
      }
      let diffMinutes =
        openHour * 60 + openMinutes - (presentHour * 60 + presentMinute);
      diffMinutes = diffMinutes < 0 ? diffMinutes + 24 * 60 : diffMinutes;
      const [hours, minutes] = [Math.floor(diffMinutes / 60), diffMinutes % 60];

      // It returns the remaining time in hours and minutes as an object with keys hours and minutes.
      return { hours, minutes };
    },
    setTimeSlot() {
      // It checks if the working hours feature is enabled for the store.

      if (this.workingHoursEnabled) {
        const timeSlots = this.workingHours;

        // If the present hour is after the closing hour of the current day,
        // then the next day's working hours will be used to calculate the time remaining until the next day's opening hours,
        // else the current day's working hours will be used
        const currentSlot =
          this.presentHour >= this.currentDayCloseHour
            ? this.nextDayWorkingHours
            : this.currentDayWorkingHours;

        // It parses the working hours to get the time slots in AM/PM format.
        const slots = timeSlotParse(timeSlots).length
          ? timeSlotParse(timeSlots)
          : defaultTimeSlot;
        this.timeSlots = slots;

        // It finds the time slot for the current slot.
        this.timeSlot = this.timeSlots.find(
          slot => slot.day === currentSlot.day_of_week
        );
      }
    },
  },
};
