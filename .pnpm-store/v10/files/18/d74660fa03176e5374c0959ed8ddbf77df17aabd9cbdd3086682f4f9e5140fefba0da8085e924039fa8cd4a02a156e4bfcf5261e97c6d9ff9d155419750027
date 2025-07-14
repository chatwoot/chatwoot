# new-date

[![CircleCI](https://circleci.com/gh/segmentio/new-date.svg?style=shield&circle-token=060f74f7f82f891aef44686435bdb632d968fb20)](https://circleci.com/gh/segmentio/new-date)
[![Codecov](https://img.shields.io/codecov/c/github/segmentio/new-date/master.svg?maxAge=2592000)](https://codecov.io/gh/segmentio/new-date)

Create a new Date, accepting more input types than normal, like Unix timestamps.

## Installation

```js
$ npm install new-date
```

## API

### newDate(Date|String|Number)

Returns a new Date object created from the input. The input can be:

* Date objects
* [date strings](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Date/parse)
* millisecond numbers
* second numbers
* millisecond strings
* second strings

```js
var newDate = require('new-date');

newDate(new Date);
newDate('Wed, 09 Aug 1995 00:00:00 GMT');
newDate('Aug 9, 1995');
newDate('2011-10-10T14:48:00');
newDate(1363288923637);
newDate(1363288923);
newDate('1363288923637');
newDate('1363288923');
```
