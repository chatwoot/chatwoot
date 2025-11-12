# vue-datepicker-next

[中文版](https://github.com/mengxiong10/vue-datepicker-next/blob/main/README.zh-CN.md)

> A Datepicker Component For Vue3

![tests](https://github.com/mengxiong10/vue-datepicker-next/actions/workflows/tests.yml/badge.svg)
<a href="https://www.npmjs.com/package/vue-datepicker-next">
<img src="https://img.shields.io/npm/v/vue-datepicker-next.svg" alt="npm">
</a>
<a href="LICENSE">
<img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT">
</a>

## Demo

<https://mengxiong10.github.io/vue-datepicker-next/index.html>

![image](https://github.com/mengxiong10/vue-datepicker-next/raw/main/screenshot/demo.png)

## Install

```bash
$ npm install vue-datepicker-next --save
```

## Usage

```html
<script>
  import DatePicker from 'vue-datepicker-next';
  import 'vue-datepicker-next/index.css';

  export default {
    components: { DatePicker },
    data() {
      return {
        time0: null,
        time1: null,
        time2: null,
        time3: null,
      };
    },
  };
</script>

<template>
  <div>
    <date-picker v-model:value="time0"></date-picker>
    <date-picker v-model:value="time1" type="datetime"></date-picker>
    <date-picker v-model:value="time2" valueType="format"></date-picker>
    <date-picker v-model:value="time3" range></date-picker>
  </div>
</template>
```

## Theme

If your project uses SCSS, you can change the default style variables.

To create a scss file. e.g. `datepicker.scss`:

```scss
$namespace: 'xmx'; // change the 'mx' to 'xmx'. then <date-picker prefix-class="xmx" />

$default-color: #555;
$primary-color: #1284e7;

@import '~vue-datepicker-next/scss/index.scss';
```

## Internationalization

The default language is English. If you need other locales,
you can import a locale file.
Once you import a locale, it becomes the active locale.

```js
import DatePicker from 'vue-datepicker-next';
import 'vue-datepicker-next/index.css';

import 'vue-datepicker-next/locale/zh-cn';
```

You can also override some of the default locale by `lang`.
[Full config](https://github.com/mengxiong10/vue-datepicker-next/blob/main/locale/en.es.js)

```html
<script>
  export default {
    data() {
      return {
        langObject: {
          formatLocale: {
            firstDayOfWeek: 1,
          },
          monthBeforeYear: false,
        },
        langString: 'zh-cn',
      };
    },
  };
</script>

<template>
  <date-picker :lang="langObject"></date-picker>
  <date-picker :lang="langString"></date-picker>
</template>
```

### Props

| Prop                | Description                                      | Type                                             | Default        |
| ------------------- | ------------------------------------------------ | ------------------------------------------------ | -------------- |
| type                | select the type of picker                        | date \|datetime\|year\|month\|time\|week         | 'date'         |
| range               | if true, pick the range date                     | `boolean`                                        | false          |
| format              | to set the date format. similar to moment.js     | [token](#token)                                  | 'YYYY-MM-DD'   |
| formatter           | use your own formatter, such as moment.js        | [object](#formatter)                             | -              |
| value-type          | data type of the binding value                   | [value-type](#value-type)                        | 'date'         |
| default-value       | default date of the calendar                     | `Date`                                           | new Date()     |
| lang                | override the default locale                      | `string`                                         | `object`       |
| placeholder         | input placeholder text                           | `string`                                         | ''             |
| editable            | whether the input is editable                    | `boolean`                                        | true           |
| clearable           | if false, don't show the clear icon              | `boolean`                                        | true           |
| confirm             | if true, need click the button to change value   | `boolean`                                        | false          |
| confirm-text        | the text of confirm button                       | `string`                                         | 'OK'           |
| multiple            | if true, multi-select date                       | `boolean`                                        | false          |
| disabled            | disable the component                            | `boolean`                                        | false          |
| disabled-date       | specify the date that cannot be selected         | `(date: Date, currentValue?: Date[]) => boolean` | -              |
| disabled-time       | specify the time that cannot be selected         | `(date: Date) => boolean`                        | -              |
| append-to-body      | append the popup to body                         | `boolean`                                        | true           |
| input-class         | input classname                                  | `string`                                         | 'mx-input'     |
| input-attr          | input attrs(eg: { name: 'date', id: 'foo'})      | `object`                                         | —              |
| open                | open state of picker                             | `boolean`                                        | -              |
| default-panel       | default panel of the picker                      | year\|month                                      | -              |
| popup-style         | popup style                                      | `object`                                         | —              |
| popup-class         | popup classes                                    |                                                  | —              |
| shortcuts           | set shortcuts to select                          | `Array<{text, onClick}>`                         | -              |
| title-format        | format of the tooltip in calendar cell           | [token](#token)                                  | 'YYYY-MM-DD'   |
| partial-update      | whether update date when select year or month    | `boolean`                                        | false          |
| separator           | text of range separator                          | `string`                                         | ' ~ '          |
| show-week-number    | determine whether show week number               | `boolean`                                        | false          |
| hour-step           | interval between hours in time picker            | 1 - 60                                           | 1              |
| minute-step         | interval between minutes in time picker          | 1 - 60                                           | 1              |
| second-step         | interval between seconds in time picker          | 1 - 60                                           | 1              |
| hour-options        | custom hour column                               | `Array<number>`                                  | -              |
| minute-options      | custom minute column                             | `Array<number>`                                  | -              |
| second-options      | custom second column                             | `Array<number>`                                  | -              |
| show-hour           | whether show hour column                         | `boolean`                                        | base on format |
| show-minute         | whether show minute column                       | `boolean`                                        | base on format |
| show-second         | whether show second column                       | `boolean`                                        | base on format |
| use12h              | whether show ampm column                         | `boolean`                                        | base on format |
| show-time-header    | whether show header of time picker               | `boolean`                                        | false          |
| time-title-format   | format of the time header                        | [token](#token)                                  | 'YYYY-MM-DD'   |
| time-picker-options | set fixed time list to select                    | [time-picker-options](#time-picker-options)      | null           |
| prefix-class        | set prefix class                                 | `string`                                         | 'mx'           |
| scroll-duration     | set the duration of scroll when hour is selected | `number`                                         | 100            |

###

remove inline
range-separator => separator;
input => update:value

#### Token

| Uint                       | Token | output                                 |
| -------------------------- | ----- | -------------------------------------- |
| Year                       | YY    | 70 71 ... 10 11                        |
|                            | YYYY  | 1970 1971 ... 2010 2011                |
|                            | Y     | -1000 ...20 ... 1970 ... 9999 +10000   |
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

#### formatter

The `formatter` accepts an object to customize formatting.

```html
<date-picker :formatter="momentFormat" />
```

```js
data() {
  return {
    // Use moment.js instead of the default
    momentFormat: {
      //[optional] Date to String
      stringify: (date) => {
        return date ? moment(date).format('LL') : ''
      },
      //[optional]  String to Date
      parse: (value) => {
        return value ? moment(value, 'LL').toDate() : null
      },
      //[optional] getWeekNumber
      getWeek: (date) => {
        return // a number
      }
    }
  }
}

```

#### value-type

set the format of binding value

| Value             | Description                                          |
| ----------------- | ---------------------------------------------------- |
| 'date'            | return a Date object                                 |
| 'timestamp'       | return a timestamp number                            |
| 'format'          | returns a string formatted using pattern of `format` |
| token(MM/DD/YYYY) | returns a string formatted using this pattern        |

#### shortcuts

The shortcuts for the range picker

```js
[
  { text: 'today', onClick: () => new Date() },
  {
    text: 'Yesterday',
    onClick: () => {
      const date = new Date();
      date.setTime(date.getTime() - 3600 * 1000 * 24);
      return date;
    },
  },
];
```

| Attribute | Description                               |
| --------- | ----------------------------------------- |
| text      | title of the shortcut                     |
| onClick   | callback function , need to return a Date |

#### time-picker-options

Set fixed time list to select;

```js
{start: '00:00', step:'00:30' , end: '23:30', format: 'HH:mm' }
```

| Attribute | Description                          |
| --------- | ------------------------------------ |
| start     | start time                           |
| step      | step time                            |
| end       | end time                             |
| format    | the default is same as prop `format` |

### Events

| Name            | Description                                                                            | Callback Arguments                                     |
| --------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| update:value    | When the value change(v-model:value event)                                             | date                                                   |
| change          | When the value change(same as input)                                                   | date, type('date'\|'hour'\|'minute'\|'second'\|'ampm') |
| open            | When panel opening                                                                     | event                                                  |
| close           | When panel closing                                                                     |                                                        |
| confirm         | When click 'confirm' button                                                            | date                                                   |
| clear           | When click 'clear' button                                                              |                                                        |
| input-error     | When user type a invalid Date                                                          | the input text                                         |
| pick            | when select date [#429](https://github.com/mengxiong10/vue-datepicker-next/issues/429) | date                                                   |
| calendar-change | when change the calendar                                                               | date                                                   |
| panel-change    | when the calendar panel changes                                                        | type('year'\|'month'\|'date'), oldType                 |

### Slots

| Name          | Description              |
| ------------- | ------------------------ |
| icon-calendar | custom the calender icon |
| icon-clear    | custom the clear icon    |
| input         | replace input            |
| header        | popup header             |
| footer        | popup footer             |
| sidebar       | popup sidebar            |

## ChangeLog

[CHANGELOG](CHANGELOG.md)

## One-time Donations

If you find this project useful, you can buy me a coffee

[Paypal Me](https://www.paypal.me/mengxiong10)

![donate](https://user-images.githubusercontent.com/14135808/83999111-a7947600-a994-11ea-84e9-9a215def4155.png)

## License

[MIT](https://github.com/mengxiong10/vue-datepicker-next/blob/main/LICENSE)

Copyright (c) 2021-present xiemengxiong
