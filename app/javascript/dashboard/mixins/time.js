import format from 'date-fns/format';

const divisions = [
  { amount: 60, name: 'seconds' },
  { amount: 60, name: 'minutes' },
  { amount: 24, name: 'hours' },
  { amount: 30, name: 'days' },
  { amount: 12, name: 'months' },
  { amount: Number.POSITIVE_INFINITY, name: 'years' },
];

export default {
  methods: {
    messageStamp(unixTimestamp, dateFormat = 'h:mm a') {
      return format(unixTimestamp * 1000, dateFormat);
    },
    dynamicTime(unixTimestamp) {
      let duration = unixTimestamp - new Date() / 1000;
      const formatter = new Intl.RelativeTimeFormat(this.$root.$i18n.locale, {
        numeric: 'auto',
      });

      let division;
      for (let i = 0; i <= divisions.length; i += 1) {
        division = divisions[i];
        if (Math.abs(duration) < division.amount) break;
        duration /= division.amount;
      }

      return formatter.format(Math.round(duration), division.name);
    },
  },
};
