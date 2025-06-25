import {
  format,
  isSameYear,
  fromUnixTime,
  formatDistanceToNow,
} from 'date-fns';

export default {
  methods: {
    messageStamp(time, dateFormat = 'h:mm a') {
      const unixTime = fromUnixTime(time);
      return format(unixTime, dateFormat);
    },
    messageTimestamp(time, dateFormat = 'MMM d, yyyy') {
      const messageTime = fromUnixTime(time);
      const now = new Date();
      const messageDate = format(messageTime, dateFormat);
      if (!isSameYear(messageTime, now)) {
        return format(messageTime, 'LLL d y, h:mm a');
      }
      return messageDate;
    },
    dynamicTime(time) {
      const unixTime = fromUnixTime(time);
      return formatDistanceToNow(unixTime, { addSuffix: true });
    },
    dateFormat(time, dateFormat = 'MMM d, yyyy') {
      const unixTime = fromUnixTime(time);
      return format(unixTime, dateFormat);
    },
    shortTimestamp(time) {
      const convertToShortTime = time
        .replace(/about|over|almost|/g, '')
        .replace('less than a minute ago', 'now')
        .replace(' minute ago', 'm')
        .replace(' minutes ago', 'm')
        .replace('a minute ago', 'm')
        .replace('an hour ago', 'h')
        .replace(' hour ago', 'h')
        .replace(' hours ago', 'h')
        .replace(' day ago', 'd')
        .replace('a day ago', 'd')
        .replace(' days ago', 'd')
        .replace('a month ago', 'mo')
        .replace(' months ago', 'mo')
        .replace(' month ago', 'mo')
        .replace('a year ago', 'y')
        .replace(' year ago', 'y')
        .replace(' years ago', 'y');
      return convertToShortTime;
    },
  },
};
