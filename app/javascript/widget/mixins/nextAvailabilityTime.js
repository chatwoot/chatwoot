import {
  timeSlotParse,
  defaultTimeSlot,
} from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { utcToZonedTime } from 'date-fns-tz';

const MINUTE_ROUNDING_FACTOR = 5;

export default {
  data() {
    return {
      dayNames: this.$t('DAY_NAMES'),
      timeSlots: [...defaultTimeSlot],
      timeSlot: {},
    };
  },
  computed: {
    channelConfig() {
      return window.chatwootWebChannel;
    },
    workingHours() {
      return this.channelConfig.workingHours;
    },
    timeZoneValue() {
      return this.channelConfig.timezone;
    },
    currentDayWorkingHours() {
      return this.workingHours.find(
        slot => slot.day_of_week === this.currentDay()
      );
    },
    nextDayWorkingHours() {
      let nextDay = this.getNextDay(this.currentDay());
      let nextWorkingHour = this.getNextWorkingHour(nextDay);

      // It gets the next working hour for the next day. If there is no working hour for the next day,
      // it keeps iterating through the days of the week until it finds the next working hour.
      while (!nextWorkingHour) {
        nextDay = this.getNextDay(nextDay);
        nextWorkingHour = this.getNextWorkingHour(nextDay);
      }
      return nextWorkingHour;
    },
    currentDayTimings() {
      const {
        open_hour: openHour,
        open_minutes: openMinute,
        close_hour: closeHour,
      } = this.currentDayWorkingHours ?? {};
      return {
        openHour,
        openMinute,
        closeHour,
      };
    },
    nextDayTimings() {
      const { open_hour: openHour, open_minutes: openMinute } =
        this.nextDayWorkingHours ?? {};
      return {
        openHour,
        openMinute,
      };
    },
    dayDiff() {
      // Here this is used to get the difference between current day and next working day
      const currentDay = this.currentDay();
      const nextDay = this.nextDayWorkingHours.day_of_week;
      const totalDays = 6;
      return nextDay > currentDay
        ? nextDay - currentDay
        : totalDays - currentDay + nextDay;
    },
    dayNameOfNextWorkingDay() {
      return this.dayNames[this.nextDayWorkingHours.day_of_week];
    },
    hoursAndMinutesBackInOnline() {
      if (this.presentHour() >= this.currentDayTimings.closeHour) {
        return this.getHoursAndMinutesUntilNextDayOpen(
          this.nextDayWorkingHours.open_all_day
            ? 0
            : this.nextDayTimings.openHour,
          this.nextDayTimings.openMinute,
          this.currentDayTimings.closeHour
        );
      }
      return this.getHoursAndMinutesUntilNextDayOpen(
        this.currentDayTimings.openHour,
        this.currentDayTimings.openMinute,
        this.currentDayTimings.closeHour
      );
    },
    exactTimeInAmPm() {
      return `${this.timeSlot.day !== this.currentDay() ? 'tomorrow' : ''} ${
        this.timeSlot.day !== this.currentDay()
          ? ''
          : `at ${this.timeSlot.from}`
      }`;
    },
    hoursAndMinutesLeft() {
      const { hoursLeft, minutesLeft } = this.hoursAndMinutesBackInOnline;

      const timeLeftChars = [];
      const languageCode = window.chatwootWebChannel.locale;

      if (hoursLeft > 0) {
        const roundedUpHoursLeft = minutesLeft > 0 ? hoursLeft + 1 : hoursLeft;
        const hourRelative = this.generateRelativeTime(
          roundedUpHoursLeft,
          'hour',
          languageCode
        );
        timeLeftChars.push(`${hourRelative}`);
      }

      if (minutesLeft > 0 && hoursLeft === 0) {
        const roundedUpMinLeft =
          Math.ceil(minutesLeft / MINUTE_ROUNDING_FACTOR) *
          MINUTE_ROUNDING_FACTOR;
        const minRelative = this.generateRelativeTime(
          roundedUpMinLeft,
          'minutes',
          languageCode
        );
        timeLeftChars.push(`${minRelative}`);
      }

      return timeLeftChars.join(' ');
    },
    hoursAndMinutesToBack() {
      const { hoursLeft, minutesLeft } = this.hoursAndMinutesBackInOnline;
      if (hoursLeft > 3) {
        return this.exactTimeInAmPm;
      }
      if (hoursLeft > 0 || minutesLeft > 0) {
        return this.hoursAndMinutesLeft;
      }
      return 'in some time';
    },
    timeLeftToBackInOnline() {
      if (
        this.dayDiff > 1 &&
        this.presentHour() >= this.currentDayTimings.closeHour
      ) {
        return `on ${this.dayNameOfNextWorkingDay}`;
      }
      if (this.hoursAndMinutesBackInOnline.hoursLeft >= 24) {
        return `tomorrow`;
      }
      return this.hoursAndMinutesToBack;
    },
  },
  mounted() {
    this.setTimeSlot();
  },
  methods: {
    newDateWithTimeZone() {
      const date = new Date();
      const timeZone = this.timeZoneValue;
      const zonedDate = utcToZonedTime(date, timeZone);
      return zonedDate;
    },
    presentHour() {
      return this.newDateWithTimeZone().getHours();
    },
    presentMinute() {
      return this.newDateWithTimeZone().getMinutes();
    },
    currentDay() {
      const date = this.newDateWithTimeZone();
      const day = date.getDay();
      const currentDay = Object.keys(this.dayNames).find(
        key => this.dayNames[key] === this.dayNames[day]
      );
      return Number(currentDay);
    },
    getNextDay(day) {
      // This code calculates the next day of the week based on the current day. If the current day is Saturday (6), then the next day will be Sunday (0).
      return (day + 1) % 7;
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
    generateRelativeTime(value, unit, languageCode) {
      const rtf = new Intl.RelativeTimeFormat(languageCode, {
        numeric: 'auto',
      });
      return rtf.format(value, unit);
    },
    getHoursAndMinutesUntilNextDayOpen(
      openHour, // If the present time is after the closing time of the current day, then the openHour will be the opening hour of the next day else it will be the opening hour of the current day.
      openMinutes, // If the present time is after the closing time of the current day, then the openMinutes will be the opening minutes of the next day else it will be the opening minutes of the current day.
      closeHour // The closeHour will be the closing hour of the current day. It will be used to calculate the time remaining until the next day's opening hours.
    ) {
      // This code calculates the time remaining until the next day's opening hours,
      // given the current time, the opening hours, and the closing hours of the current day.
      if (closeHour < openHour) {
        openHour += 24;
      }
      let diffMinutes =
        openHour * 60 +
        openMinutes -
        (this.presentHour() * 60 + this.presentMinute());
      diffMinutes = diffMinutes < 0 ? diffMinutes + 24 * 60 : diffMinutes;
      const [hoursLeft, minutesLeft] = [
        Math.floor(diffMinutes / 60),
        diffMinutes % 60,
      ];

      // It returns the remaining time in hours and minutes as an object with keys hours and minutes.
      return { hoursLeft, minutesLeft };
    },
    setTimeSlot() {
      // It checks if the working hours feature is enabled for the store.

      const timeSlots = this.workingHours;

      // If the present hour is after the closing hour of the current day,
      // then the next day's working hours will be used to calculate the time remaining until the next day's opening hours,
      // else the current day's working hours will be used
      const currentSlot =
        this.presentHour() >= this.currentDayTimings.closeHour
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
    },
  },
};
