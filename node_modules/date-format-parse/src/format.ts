import { toDate, isValidDate, getWeek } from './util';
import { Locale } from './locale';
import defaultLocale from './locale/en';

const REGEX_FORMAT = /\[([^\]]+)]|YYYY|YY?|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|m{1,2}|s{1,2}|Z{1,2}|S{1,3}|w{1,2}|x|X|a|A/g;

function pad(val: number, len = 2) {
  let output = `${Math.abs(val)}`;
  const sign = val < 0 ? '-' : '';
  while (output.length < len) {
    output = `0${output}`;
  }
  return sign + output;
}

function formatTimezone(offset: number, delimeter = '') {
  const sign = offset > 0 ? '-' : '+';
  const absOffset = Math.abs(offset);
  const hours = Math.floor(absOffset / 60);
  const minutes = absOffset % 60;
  return sign + pad(hours, 2) + delimeter + pad(minutes, 2);
}

interface FormatFlag {
  [key: string]: (date: Date, locale: Locale) => string | number;
}

const meridiem = (h: number, _: number, isLowercase: boolean) => {
  const word = h < 12 ? 'AM' : 'PM';
  return isLowercase ? word.toLocaleLowerCase() : word;
};

const formatFlags: FormatFlag = {
  Y(date) {
    const y = date.getFullYear();
    return y <= 9999 ? `${y}` : `+${y}`;
  },

  // Year: 00, 01, ..., 99
  YY(date) {
    return pad(date.getFullYear(), 4).substr(2);
  },

  // Year: 1900, 1901, ..., 2099
  YYYY(date) {
    return pad(date.getFullYear(), 4);
  },

  // Month: 1, 2, ..., 12
  M(date) {
    return date.getMonth() + 1;
  },

  // Month: 01, 02, ..., 12
  MM(date) {
    return pad(date.getMonth() + 1, 2);
  },

  MMM(date, locale) {
    return locale.monthsShort[date.getMonth()];
  },

  MMMM(date, locale) {
    return locale.months[date.getMonth()];
  },

  // Day of month: 1, 2, ..., 31
  D(date) {
    return date.getDate();
  },

  // Day of month: 01, 02, ..., 31
  DD(date) {
    return pad(date.getDate(), 2);
  },

  // Hour: 0, 1, ... 23
  H(date) {
    return date.getHours();
  },

  // Hour: 00, 01, ..., 23
  HH(date) {
    return pad(date.getHours(), 2);
  },

  // Hour: 1, 2, ..., 12
  h(date) {
    const hours = date.getHours();
    if (hours === 0) {
      return 12;
    }
    if (hours > 12) {
      return hours % 12;
    }
    return hours;
  },

  // Hour: 01, 02, ..., 12
  hh(...args) {
    const hours = formatFlags.h(...args) as number;
    return pad(hours, 2);
  },

  // Minute: 0, 1, ..., 59
  m(date) {
    return date.getMinutes();
  },

  // Minute: 00, 01, ..., 59
  mm(date) {
    return pad(date.getMinutes(), 2);
  },

  // Second: 0, 1, ..., 59
  s(date) {
    return date.getSeconds();
  },

  // Second: 00, 01, ..., 59
  ss(date) {
    return pad(date.getSeconds(), 2);
  },

  // 1/10 of second: 0, 1, ..., 9
  S(date) {
    return Math.floor(date.getMilliseconds() / 100);
  },

  // 1/100 of second: 00, 01, ..., 99
  SS(date) {
    return pad(Math.floor(date.getMilliseconds() / 10), 2);
  },

  // Millisecond: 000, 001, ..., 999
  SSS(date) {
    return pad(date.getMilliseconds(), 3);
  },

  // Day of week: 0, 1, ..., 6
  d(date) {
    return date.getDay();
  },
  // Day of week: 'Su', 'Mo', ..., 'Sa'
  dd(date, locale) {
    return locale.weekdaysMin[date.getDay()];
  },

  // Day of week: 'Sun', 'Mon',..., 'Sat'
  ddd(date, locale) {
    return locale.weekdaysShort[date.getDay()];
  },

  // Day of week: 'Sunday', 'Monday', ...,'Saturday'
  dddd(date, locale) {
    return locale.weekdays[date.getDay()];
  },

  // AM, PM
  A(date, locale) {
    const meridiemFunc = locale.meridiem || meridiem;
    return meridiemFunc(date.getHours(), date.getMinutes(), false);
  },

  // am, pm
  a(date, locale) {
    const meridiemFunc = locale.meridiem || meridiem;
    return meridiemFunc(date.getHours(), date.getMinutes(), true);
  },

  // Timezone: -01:00, +00:00, ... +12:00
  Z(date) {
    return formatTimezone(date.getTimezoneOffset(), ':');
  },

  // Timezone: -0100, +0000, ... +1200
  ZZ(date) {
    return formatTimezone(date.getTimezoneOffset());
  },

  // Seconds timestamp: 512969520
  X(date) {
    return Math.floor(date.getTime() / 1000);
  },

  // Milliseconds timestamp: 512969520900
  x(date) {
    return date.getTime();
  },

  w(date, locale) {
    return getWeek(date, {
      firstDayOfWeek: locale.firstDayOfWeek,
      firstWeekContainsDate: locale.firstWeekContainsDate,
    });
  },

  ww(date, locale) {
    return pad(formatFlags.w(date, locale) as number, 2);
  },
};

function format(val: Date, str: string, options: { locale?: Locale } = {}) {
  const formatStr = str ? String(str) : 'YYYY-MM-DDTHH:mm:ss.SSSZ';
  const date = toDate(val);
  if (!isValidDate(date)) {
    return 'Invalid Date';
  }

  const locale = options.locale || defaultLocale;

  return formatStr.replace(REGEX_FORMAT, (match, p1: string) => {
    if (p1) {
      return p1;
    }
    if (typeof formatFlags[match] === 'function') {
      return `${formatFlags[match](date, locale)}`;
    }
    return match;
  });
}

export default format;
