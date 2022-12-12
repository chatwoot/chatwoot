# date-format-parse

<a href="https://travis-ci.org/mengxiong10/date-format-parse">
  <img src="https://travis-ci.org/mengxiong10/date-format-parse.svg?branch=master" alt="build:passed">
</a>
<a href="https://coveralls.io/github/mengxiong10/date-format-parse">
  <img src="https://coveralls.io/repos/github/mengxiong10/date-format-parse/badge.svg?branch=master&service=github" alt="Badge">
</a>
<a href="https://www.npmjs.com/package/date-format-parse">
  <img src="https://img.shields.io/npm/v/date-format-parse.svg" alt="npm">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT">
</a>

Lightweight date format and parse. Meant to replace the primary functions of format and parse of momentjs.

## NPM

```bash
$ npm install date-format-parse --save
```

## Usage

### Format

Format Date to String.

```js
import { format } from 'date-format-parse';

format(new Date(), 'YYYY-MM-DD HH:mm:ss.SSS');

// with locale, see locale config below
const obj = { ... }

format(new Date(), 'YYYY-MM-DD', { locale: obj })

```

### Parse

Parse String to Date

```js
import { parse } from 'date-format-parse';

parse('2019-12-10 14:11:12', 'YYYY-MM-DD HH:mm:ss'); // new Date(2019, 11, 10, 14, 11, 12)

// with backupDate, default is new Date()
parse('10:00', 'HH:mm', { backupDate: new Date(2019, 5, 6) }) // new Date(2019, 5, 6, 10)

// with locale, see locale config below
const obj = { ... }

parse('2019-12-10 14:11:12', 'YYYY-MM-DD HH:mm:ss', { locale: obj });

```

### Locale

```ts
interface Locale {
  months: string[];
  monthsShort: string[];
  weekdays: string[];
  weekdaysShort: string[];
  weekdaysMin: string[];
  meridiem?: (hours: number, minutes: number, isLowercase: boolean) => string;
  meridiemParse?: RegExp;
  isPM?: (input: string) => boolean;
  ordinal?: () => string;
}

const locale = {
  // MMMM
  months: [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
  // MMM
  monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  // dddd
  weekdays: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  // ddd
  weekdaysShort: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  // dd
  weekdaysMin: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
  // [A a] format the ampm. The following is the default value
  meridiem: (h: number, m: number, isLowercase: boolean) => {
    const word = h < 12 ? 'AM' : 'PM';
    return isLowercase ? word.toLocaleLowerCase() : word;
  };
  // [A a] used by parse to match the ampm. The following is the default value
  meridiemParse: /[ap]\.?m?\.?/i,
  // [A a] used by parse to determine if the matching string is pm. The following is the default value
  isPM: (input) => {
    return (input + '').toLowerCase().charAt(0) === 'p';
  }
};
```

## Tokens

| Uint                       | Token | output                                 |
| -------------------------- | ----- | -------------------------------------- |
| Year                       | YY    | 70 71 ... 10 11                        |
|                            | YYYY  | 1970 1971 ... 2010 2011                |
| Month                      | M     | 1 2 ... 11 12                          |
|                            | MM    | 01 02 ... 11 12                        |
|                            | MMM   | Jan Feb ... Nov Dec                    |
|                            | MMMM  | January February ... November December |
| Day of Month               | D     | 1 2 ... 30 31                          |
|                            | DD    | 01 02 ... 30 31                        |
| Day of Week                | d     | 0 1 ... 5 6                            |
|                            | dd    | Su Mo ... Fr Sa                        |
|                            | ddd   | Sun Mon ... Fri Sat                    |
|                            | dddd  | Sunday Monday ... Friday Saturday      |
| AM/PM                      | A     | AM PM                                  |
|                            | a     | am pm                                  |
| Hour                       | H     | 0 1 ... 22 23                          |
|                            | HH    | 00 01 ... 22 23                        |
|                            | h     | 1 2 ... 12                             |
|                            | hh    | 01 02 ... 12                           |
| Minute                     | m     | 0 1 ... 58 59                          |
|                            | mm    | 00 01 ... 58 59                        |
| Second                     | s     | 0 1 ... 58 59                          |
|                            | ss    | 00 01 ... 58 59                        |
| Fractional Second          | S     | 0 1 ... 8 9                            |
|                            | SS    | 00 01 ... 98 99                        |
|                            | SSS   | 000 001 ... 998 999                    |
| Time Zone                  | Z     | -07:00 -06:00 ... +06:00 +07:00        |
|                            | ZZ    | -0700 -0600 ... +0600 +0700            |
| Week of Year               | w     | 1 2 ... 52 53                          |
|                            | ww    | 01 02 ... 52 53                        |
| Unix Timestamp             | X     | 1360013296                             |
| Unix Millisecond Timestamp | x     | 1360013296123                          |
