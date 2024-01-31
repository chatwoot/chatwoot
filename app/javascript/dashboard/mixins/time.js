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
    shortTimestamp(time, withAgo = false) {
      const suffix = withAgo ? ' ago' : '';
      const convertToShortTime = time
        .replace(/about|over|almost|/g, '')
        .replace('less than a minute ago', 'now')
        .replace('a minute ago', `${withAgo ? '1m ago' : '1m'}`)
        .replace('an hour ago', `${withAgo ? '1h ago' : '1h'}`)
        .replace('a day ago', `${withAgo ? '1d ago' : '1d'}`)
        .replace('a month ago', `${withAgo ? '1mo ago' : '1mo'}`)
        .replace('a year ago', `${withAgo ? '1y ago' : '1y'}`)
        .replace(' minute ago', `m${suffix}`)
        .replace(' minutes ago', `m${suffix}`)
        .replace(' hour ago', `h${suffix}`)
        .replace(' hours ago', `h${suffix}`)
        .replace(' day ago', `d${suffix}`)
        .replace(' days ago', `d${suffix}`)
        .replace(' month ago', `mo${suffix}`)
        .replace(' months ago', `mo${suffix}`)
        .replace(' year ago', `y${suffix}`)
        .replace(' years ago', `y${suffix}`);
      return convertToShortTime;
    },
  },
};
