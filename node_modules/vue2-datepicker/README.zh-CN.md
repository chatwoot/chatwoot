# vue2-datepicker

[English Version](https://github.com/mengxiong10/vue2-datepicker/blob/master/README.md)

> 一个基于 Vue2.x 的日期时间选择组件

<a href="https://travis-ci.org/mengxiong10/vue2-datepicker">
  <img src="https://travis-ci.org/mengxiong10/vue2-datepicker.svg?branch=master" alt="build:passed">
</a>
<a href="https://coveralls.io/github/mengxiong10/vue2-datepicker">
  <img src="https://coveralls.io/repos/github/mengxiong10/vue2-datepicker/badge.svg?branch=master&service=github" alt="Badge">
</a>
<a href="https://www.npmjs.com/package/vue2-datepicker">
  <img src="https://img.shields.io/npm/v/vue2-datepicker.svg" alt="npm">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT">
</a>

## 线上 Demo

<https://mengxiong10.github.io/vue2-datepicker/index.html>

![image](https://github.com/mengxiong10/vue2-datepicker/raw/master/screenshot/demo.png)

## 安装

```bash
$ npm install vue2-datepicker --save
```

## 主题

如果你的项目使用了 SCSS, 你可以改变默认的变量.

创建一个新的文件. e.g. `datepicker.scss`:

```scss
$namespace: 'xmx'; // 更改默认前缀为'xmx'. 然后设置 <date-picker prefix-class="xmx" />

$default-color: #555;
$primary-color: #1284e7;

@import '~vue2-datepicker/scss/index.scss';
```

## 用法

```html
<script>
  import DatePicker from 'vue2-datepicker';
  import 'vue2-datepicker/index.css';

  export default {
    components: { DatePicker },
    data() {
      return {
        time1: null,
        time2: null,
        time3: null,
      };
    },
  };
</script>

<template>
  <div>
    <date-picker v-model="time1" valueType="format"></date-picker>
    <date-picker v-model="time2" type="datetime"></date-picker>
    <date-picker v-model="time3" range></date-picker>
  </div>
</template>
```

## 国际化

v3.x 默认语言是英文. 可以引入语言包切换到中文.

```js
import DatePicker from 'vue2-datepicker';
import 'vue2-datepicker/index.css';

import 'vue2-datepicker/locale/zh-cn';
```

还可以通过`lang`去覆盖一些默认语言选项.
[完整配置](https://github.com/mengxiong10/vue2-datepicker/blob/master/locale.md)

```html
<script>
  export default {
    data() {
      return {
        lang: {
          formatLocale: {
            firstDayOfWeek: 1,
          },
          monthBeforeYear: false,
        },
      };
    },
  };
</script>

<template>
  <date-picker :lang="lang"></date-picker>
</template>
```

### Props

| 属性                | 描述                                             | 类型                                            | 默认值         |
| ------------------- | ------------------------------------------------ | ----------------------------------------------- | -------------- |
| type                | 日期选择的类型                                   | date \|datetime\|year\|month\|time\|week        | 'date'         |
| range               | 如果是 true, 变成日期范围选择                    | `boolean`                                       | false          |
| format              | 设置格式化的 token, 类似 moment.js               | [token](#token)                                 | 'YYYY-MM-DD'   |
| formatter           | 使用自己的格式化程序, 比如 moment.js             | [object](#formatter)                            | -              |
| value-type          | 设置绑定值的类型                                 | [value-type](#value-type)                       | 'date'         |
| default-value       | 设置日历默认的时间                               | `Date`                                          | new Date()     |
| lang                | 覆盖默认的语音设置                               | `object`                                        |                |
| placeholder         | 输入框的 placeholder                             | `string`                                        | ''             |
| editable            | 输入框是否可以输入                               | `boolean`                                       | true           |
| clearable           | 是否显示清除按钮                                 | `boolean`                                       | true           |
| confirm             | 是否需要确认                                     | `boolean`                                       | false          |
| confirm-text        | 确认按钮的文字                                   | `string`                                        | 'OK'           |
| multiple            | 如果是 true, 可以选择多个日期                    | `boolean`                                       | false          |
| disabled            | 禁用组件                                         | `boolean`                                       | false          |
| disabled-date       | 禁止选择的日期                                   | `(date: Date, currentValue: Date[]) => boolean` | -              |
| disabled-time       | 禁止选择的时间                                   | `(date: Date) => boolean`                       | -              |
| append-to-body      | 弹出层插入到 body 元素下                         | `boolean`                                       | true           |
| inline              | 不显示输入框                                     | `boolean`                                       | false          |
| input-class         | 输入框的类                                       | `string`                                        | 'mx-input'     |
| input-attr          | 输入框的其他属性(eg: { name: 'date', id: 'foo'}) | `object`                                        | —              |
| open                | 控制弹出层的显示                                 | `boolean`                                       | -              |
| default-panel       | 控制打开的面板                                   | year\|month                                     | -              |
| popup-style         | 弹出层的样式                                     | `object`                                        | —              |
| popup-class         | 弹出层的类                                       |                                                 | —              |
| shortcuts           | 设置快捷选择                                     | `Array<{text, onClick}>`                        | -              |
| title-format        | 日历单元格的 tooltip                             | [token](#token)                                 | 'YYYY-MM-DD'   |
| partial-update      | 是否更新日期当选择年或月的时候                   | `boolean`                                       | false          |
| range-separator     | 范围分隔符                                       | `string`                                        | ' ~ '          |
| show-week-number    | 是否显示星期数字                                 | `boolean`                                       | false          |
| hour-step           | 小时列的间隔                                     | 1 - 60                                          | 1              |
| minute-step         | 分钟列的间隔                                     | 1 - 60                                          | 1              |
| second-step         | 秒列的间隔                                       | 1 - 60                                          | 1              |
| hour-options        | 自定义小时列                                     | `Array<number>`                                 | -              |
| minute-options      | 自定义分钟列                                     | `Array<number>`                                 | -              |
| second-options      | 自定义秒列                                       | `Array<number>`                                 | -              |
| show-hour           | 是否显示小时列                                   | `boolean`                                       | base on format |
| show-minute         | 是否显示分钟列                                   | `boolean`                                       | base on format |
| show-second         | 是否显示秒列                                     | `boolean`                                       | base on format |
| use12h              | 是否显示 ampm 列                                 | `boolean`                                       | base on format |
| show-time-header    | 是否显示时间选择面板的头部                       | `boolean`                                       | false          |
| time-title-format   | 时间面板头部的格式化                             | [token](#token)                                 | 'YYYY-MM-DD'   |
| time-picker-options | 设置固定时间去选择                               | [time-picker-options](#time-picker-options)     | null           |
| prefix-class        | 设置 class 的前缀                                | `string`                                        | 'mx'           |
| scroll-duration     | 设置滚动时候当选中小时的时候                     | `number`                                        | 100            |

#### Token

| 单元                       | 符号 | 输入                                   |
| -------------------------- | ---- | -------------------------------------- |
| Year                       | YY   | 70 71 ... 10 11                        |
|                            | YYYY | 1970 1971 ... 2010 2011                |
|                            | Y    | -1000 ...20 ... 1970 ... 9999 +10000   |
| Month                      | M    | 1 2 ... 11 12                          |
|                            | MM   | 01 02 ... 11 12                        |
|                            | MMM  | Jan Feb ... Nov Dec                    |
|                            | MMMM | January February ... November December |
| Day of Month               | D    | 1 2 ... 30 31                          |
|                            | DD   | 01 02 ... 30 31                        |
| Day of Week                | d    | 0 1 ... 5 6                            |
|                            | dd   | Su Mo ... Fr Sa                        |
|                            | ddd  | Sun Mon ... Fri Sat                    |
|                            | dddd | Sunday Monday ... Friday Saturday      |
| AM/PM                      | A    | AM PM                                  |
|                            | a    | am pm                                  |
| Hour                       | H    | 0 1 ... 22 23                          |
|                            | HH   | 00 01 ... 22 23                        |
|                            | h    | 1 2 ... 12                             |
|                            | hh   | 01 02 ... 12                           |
| Minute                     | m    | 0 1 ... 58 59                          |
|                            | mm   | 00 01 ... 58 59                        |
| Second                     | s    | 0 1 ... 58 59                          |
|                            | ss   | 00 01 ... 58 59                        |
| Fractional Second          | S    | 0 1 ... 8 9                            |
|                            | SS   | 00 01 ... 98 99                        |
|                            | SSS  | 000 001 ... 998 999                    |
| Time Zone                  | Z    | -07:00 -06:00 ... +06:00 +07:00        |
|                            | ZZ   | -0700 -0600 ... +0600 +0700            |
| Week of Year               | w    | 1 2 ... 52 53                          |
|                            | ww   | 01 02 ... 52 53                        |
| Unix Timestamp             | X    | 1360013296                             |
| Unix Millisecond Timestamp | x    | 1360013296123                          |

#### formatter

`formatter` 接受一个对象去自定义格式化

```html
<date-picker :formatter="momentFormat" />
```

```js
data() {
  return {
    // 使用moment.js 替换默认
    momentFormat: {
      //[可选] Date to String
      stringify: (date) => {
        return date ? moment(date).format('LL') : ''
      },
      //[可选]  String to Date
      parse: (value) => {
        return value ? moment(value, 'LL').toDate() : null
      },
      //[可选] getWeekNumber
      getWeek: (date) => {
        return // a number
      }
    }
  }
}

```

#### value-type

设置绑定值的类型

| 可选值            | 描述                                 |
| ----------------- | ------------------------------------ |
| 'date'            | 返回一个日期对象                     |
| 'timestamp'       | 返回一个时间戳                       |
| 'format'          | 返回一个用 format 字段格式化的字符串 |
| token(MM/DD/YYYY) | 返回一个用这个字段格式化的字符串     |

#### shortcuts

设置快捷选择方式

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

| 属性    | 描述                              |
| ------- | --------------------------------- |
| text    | 显示的名称                        |
| onClick | 回调函数， 需要返回一个 Date 对象 |

#### time-picker-options

设置固定时间用于选择

```js
{start: '00:00', step:'00:30' , end: '23:30'}
```

| 属性  | 描述     |
| ----- | -------- |
| start | 开始时间 |
| step  | 间隔时间 |
| end   | 结束时间 |

### 事件

| 名称            | 描述                                                                           | 回调函数的参数                                                                                                           |
| --------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| input           | 当选择日期的事件触发                                                           | date                                                                                                                     |
| change          | 当选择日期的事件触发                                                           | date, type('date'\|'hour'\|'minute'\|'second'\|'ampm                                                                     |
| open            | 当弹出层打开时候                                                               | event                                                                                                                    |
| close           | 当弹出层关闭时候                                                               |                                                                                                                          |
| confirm         | 当点击确认按钮                                                                 | date                                                                                                                     |
| clear           | 当点击清除按钮                                                                 |                                                                                                                          |
| input-error     | 当输入一个无效的时间                                                           | 输入的值                                                                                                                 |
| focus           | 当输入框有焦点                                                                 |                                                                                                                          |
| blur            | 当输入框失焦                                                                   |                                                                                                                          |
| pick            | 当点击日期时 [#429](https://github.com/mengxiong10/vue2-datepicker/issues/429) | date                                                                                                                     |
| calendar-change | 当改变年月时                                                                   | date, oldDate, type('year'\|'month'\|'last-year'\|'next-year'\|'last-month'\|'next-month'\|'last-decade'\|'next-decade') |
| panel-change    | 当日历面板改变时                                                               | type('year'\|'month'\|'date'), oldType                                                                                   |

### Slots

| 名称          | 描述           |
| ------------- | -------------- |
| icon-calendar | 自定义日历图标 |
| icon-clear    | 自定义清除图标 |
| input         | 替换输入框     |
| header        | 弹出层的头部   |
| footer        | 弹出层的底部   |
| sidebar       | 弹出层的侧边   |

## ChangeLog

[CHANGELOG](CHANGELOG.md)

## 一次性捐赠

如果这个项目对你很有用，你可以请我喝杯咖啡

[Paypal Me](https://www.paypal.me/mengxiong10)

![donate](https://user-images.githubusercontent.com/14135808/83999111-a7947600-a994-11ea-84e9-9a215def4155.png)

## License

[MIT](https://github.com/mengxiong10/vue2-datepicker/blob/master/LICENSE)

Copyright (c) 2017-present xiemengxiong
