import { Unionize, PickByValue } from 'utility-types';
import { Locale } from './locale';
import defaultLocale from './locale/en';

import { startOfWeekYear } from './util';

const formattingTokens = /(\[[^\[]*\])|(MM?M?M?|Do|DD?|ddd?d?|w[o|w]?|YYYY|YY|a|A|hh?|HH?|mm?|ss?|S{1,3}|x|X|ZZ?|.)/g;

const match1 = /\d/; // 0 - 9
const match2 = /\d\d/; // 00 - 99
const match3 = /\d{3}/; // 000 - 999
const match4 = /\d{4}/; // 0000 - 9999
const match1to2 = /\d\d?/; // 0 - 99
const matchShortOffset = /[+-]\d\d:?\d\d/; // +00:00 -00:00 +0000 or -0000
const matchSigned = /[+-]?\d+/; // -inf - inf
const matchTimestamp = /[+-]?\d+(\.\d{1,3})?/; // 123456789 123456789.123

// const matchWord = /[0-9]{0,256}['a-z\u00A0-\u05FF\u0700-\uD7FF\uF900-\uFDCF\uFDF0-\uFF07\uFF10-\uFFEF]{1,256}|[\u0600-\u06FF\/]{1,256}(\s*?[\u0600-\u06FF]{1,256}){1,2}/i; // Word

const YEAR = 'year';
const MONTH = 'month';
const DAY = 'day';
const HOUR = 'hour';
const MINUTE = 'minute';
const SECOND = 'second';
const MILLISECOND = 'millisecond';

export interface ParseFlagMark {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  millisecond: number;
  offset: number;
  weekday: number; // 0,1...6
  week: number; //  0 1... 52
  date: Date;
  isPM: boolean;
}

export type ParseFlagCallBackReturn = Unionize<ParseFlagMark>;

export type ParseFlagRegExp = RegExp | ((locale: Locale) => RegExp);
export type ParseFlagCallBack = (input: string, locale: Locale) => ParseFlagCallBackReturn;

export interface ParseFlag {
  [key: string]: [ParseFlagRegExp, ParseFlagCallBack];
}

const parseFlags: ParseFlag = {};

const addParseFlag = (
  token: string | string[],
  regex: ParseFlagRegExp,
  callback: ParseFlagCallBack | keyof PickByValue<ParseFlagMark, number>
) => {
  const tokens = Array.isArray(token) ? token : [token];
  let func: ParseFlagCallBack;
  if (typeof callback === 'string') {
    func = input => {
      const value = parseInt(input, 10);
      return { [callback]: value } as Unionize<PickByValue<ParseFlagMark, number>>;
    };
  } else {
    func = callback;
  }
  tokens.forEach(key => {
    parseFlags[key] = [regex, func];
  });
};

const escapeStringRegExp = (str: string) => {
  return str.replace(/[|\\{}()[\]^$+*?.]/g, '\\$&');
};

const matchWordRegExp = (localeKey: string) => {
  return (locale: Locale) => {
    const array = locale[localeKey];
    if (!Array.isArray(array)) {
      throw new Error(`Locale[${localeKey}] need an array`);
    }
    return new RegExp(array.map(escapeStringRegExp).join('|'));
  };
};

const matchWordCallback = (localeKey: string, key: 'month' | 'weekday') => {
  return (input: string, locale: Locale) => {
    const array = locale[localeKey];
    if (!Array.isArray(array)) {
      throw new Error(`Locale[${localeKey}] need an array`);
    }
    const index = array.indexOf(input);
    if (index < 0) {
      throw new Error('Invalid Word');
    }
    return { [key]: index } as Unionize<Pick<ParseFlagMark, 'month' | 'weekday'>>;
  };
};

addParseFlag('Y', matchSigned, YEAR);
addParseFlag('YY', match2, input => {
  const year = new Date().getFullYear();
  const cent = Math.floor(year / 100);
  let value = parseInt(input, 10);
  value = (value > 68 ? cent - 1 : cent) * 100 + value;
  return { [YEAR]: value };
});
addParseFlag('YYYY', match4, YEAR);
addParseFlag('M', match1to2, input => ({ [MONTH]: parseInt(input, 10) - 1 }));
addParseFlag('MM', match2, input => ({ [MONTH]: parseInt(input, 10) - 1 }));
addParseFlag('MMM', matchWordRegExp('monthsShort'), matchWordCallback('monthsShort', MONTH));
addParseFlag('MMMM', matchWordRegExp('months'), matchWordCallback('months', MONTH));
addParseFlag('D', match1to2, DAY);
addParseFlag('DD', match2, DAY);
addParseFlag(['H', 'h'], match1to2, HOUR);
addParseFlag(['HH', 'hh'], match2, HOUR);
addParseFlag('m', match1to2, MINUTE);
addParseFlag('mm', match2, MINUTE);
addParseFlag('s', match1to2, SECOND);
addParseFlag('ss', match2, SECOND);
addParseFlag('S', match1, input => {
  return {
    [MILLISECOND]: parseInt(input, 10) * 100,
  };
});
addParseFlag('SS', match2, input => {
  return {
    [MILLISECOND]: parseInt(input, 10) * 10,
  };
});
addParseFlag('SSS', match3, MILLISECOND);

function matchMeridiem(locale: Locale) {
  return locale.meridiemParse || /[ap]\.?m?\.?/i;
}

function defaultIsPM(input: string) {
  return `${input}`.toLowerCase().charAt(0) === 'p';
}

addParseFlag(['A', 'a'], matchMeridiem, (input, locale) => {
  const isPM = typeof locale.isPM === 'function' ? locale.isPM(input) : defaultIsPM(input);
  return { isPM };
});

function offsetFromString(str: string) {
  const [symbol, hour, minute] = str.match(/([+-]|\d\d)/g) || ['-', '0', '0'];
  const minutes = parseInt(hour, 10) * 60 + parseInt(minute, 10);
  if (minutes === 0) {
    return 0;
  }
  return symbol === '+' ? -minutes : +minutes;
}

addParseFlag(['Z', 'ZZ'], matchShortOffset, input => {
  return { offset: offsetFromString(input) };
});

addParseFlag('x', matchSigned, input => {
  return { date: new Date(parseInt(input, 10)) };
});

addParseFlag('X', matchTimestamp, input => {
  return { date: new Date(parseFloat(input) * 1000) };
});

addParseFlag('d', match1, 'weekday');
addParseFlag('dd', matchWordRegExp('weekdaysMin'), matchWordCallback('weekdaysMin', 'weekday'));
addParseFlag(
  'ddd',
  matchWordRegExp('weekdaysShort'),
  matchWordCallback('weekdaysShort', 'weekday')
);
addParseFlag('dddd', matchWordRegExp('weekdays'), matchWordCallback('weekdays', 'weekday'));

addParseFlag('w', match1to2, 'week');
addParseFlag('ww', match2, 'week');

function to24hour(hour?: number, isPM?: boolean) {
  if (hour !== undefined && isPM !== undefined) {
    if (isPM) {
      if (hour < 12) {
        return hour + 12;
      }
    } else if (hour === 12) {
      return 0;
    }
  }
  return hour;
}

type DateArgs = [number, number, number, number, number, number, number];

function getFullInputArray(input: Array<number | undefined>, backupDate = new Date()) {
  const result: DateArgs = [0, 0, 1, 0, 0, 0, 0];
  const backupArr = [
    backupDate.getFullYear(),
    backupDate.getMonth(),
    backupDate.getDate(),
    backupDate.getHours(),
    backupDate.getMinutes(),
    backupDate.getSeconds(),
    backupDate.getMilliseconds(),
  ];
  let useBackup = true;
  for (let i = 0; i < 7; i++) {
    if (input[i] === undefined) {
      result[i] = useBackup ? backupArr[i] : result[i];
    } else {
      result[i] = input[i]!;
      useBackup = false;
    }
  }
  return result;
}

function createUTCDate(...args: DateArgs) {
  let date: Date;
  const y = args[0];
  if (y < 100 && y >= 0) {
    args[0] += 400;
    date = new Date(Date.UTC(...args));
    // eslint-disable-next-line no-restricted-globals
    if (isFinite(date.getUTCFullYear())) {
      date.setUTCFullYear(y);
    }
  } else {
    date = new Date(Date.UTC(...args));
  }

  return date;
}

function makeParser(dateString: string, format: string, locale: Locale) {
  const tokens = format.match(formattingTokens);
  if (!tokens) {
    throw new Error();
  }
  const { length } = tokens;
  let mark: Partial<ParseFlagMark> = {};
  for (let i = 0; i < length; i += 1) {
    const token = tokens[i];
    const parseTo = parseFlags[token];
    if (!parseTo) {
      const word = token.replace(/^\[|\]$/g, '');
      if (dateString.indexOf(word) === 0) {
        dateString = dateString.substr(word.length);
      } else {
        throw new Error('not match');
      }
    } else {
      const regex = typeof parseTo[0] === 'function' ? parseTo[0](locale) : parseTo[0];
      const parser = parseTo[1];
      const value = (regex.exec(dateString) || [])[0];
      const obj = parser(value, locale);
      mark = { ...mark, ...obj };
      dateString = dateString.replace(value, '');
    }
  }
  return mark;
}

export default function parse(
  str: string,
  format: string,
  options: { locale?: Locale; backupDate?: Date } = {}
) {
  try {
    const { locale = defaultLocale, backupDate = new Date() } = options;
    const parseResult = makeParser(str, format, locale);
    const {
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      isPM,
      date,
      offset,
      weekday,
      week,
    } = parseResult;
    if (date) {
      return date;
    }
    const inputArray = [year, month, day, hour, minute, second, millisecond];
    inputArray[3] = to24hour(inputArray[3], isPM);
    // check week
    if (week !== undefined && month === undefined && day === undefined) {
      // new Date(year, 3) make sure in current year
      const firstDate = startOfWeekYear(year === undefined ? backupDate : new Date(year, 3), {
        firstDayOfWeek: locale.firstDayOfWeek,
        firstWeekContainsDate: locale.firstWeekContainsDate,
      });
      return new Date(firstDate.getTime() + (week - 1) * 7 * 24 * 3600 * 1000);
    }

    const utcDate = createUTCDate(...getFullInputArray(inputArray, backupDate));
    const offsetMilliseconds =
      (offset === undefined ? utcDate.getTimezoneOffset() : offset) * 60 * 1000;
    const parsedDate = new Date(utcDate.getTime() + offsetMilliseconds);
    // check weekday
    if (weekday !== undefined && parsedDate.getDay() !== weekday) {
      return new Date(NaN);
    }
    return parsedDate;
  } catch (e) {
    return new Date(NaN);
  }
}
