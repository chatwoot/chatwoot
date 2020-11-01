/* eslint no-console: 0 */
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import formatDistanceToNow from 'date-fns/formatDistanceToNow';

export default {
  methods: {
    messageStamp(time) {
      const unixTime = fromUnixTime(time);
      return format(unixTime, 'h:mm a');
    },
    dynamicTime(time) {
      const unixTime = fromUnixTime(time);
      return formatDistanceToNow(unixTime, { addSuffix: true });
    },
  },
};
