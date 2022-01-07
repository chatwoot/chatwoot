import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import formatDistanceToNowStrict from 'date-fns/formatDistanceToNowStrict';

export default {
  methods: {
    messageStamp(time, dateFormat = 'h:mm a') {
      const unixTime = fromUnixTime(time);
      return format(unixTime, dateFormat);
    },
    dynamicTime(time) {
      const unixTime = fromUnixTime(time);
      return formatDistanceToNowStrict(unixTime, { addSuffix: true });
    },
  },
};
