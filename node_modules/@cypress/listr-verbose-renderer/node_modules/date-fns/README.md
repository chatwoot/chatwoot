# ![](http://cdn.date-fns.org/README-logo.svg) date-fns

**Pinned**: see [a brief comparison with Moment.js](https://github.com/date-fns/date-fns/issues/275#issuecomment-264934189).

**date-fns** provides the most comprehensive, yet simple and consistent toolset
for manipulating **JavaScript dates** in **a browser** & **Node.js**.

**date-fns** is like [lodash](https://lodash.com) for dates. It has
[**140+ functions** for all occasions](https://date-fns.org/docs/).

```js
dateFns.format(new Date(2014, 1, 11), 'MM/DD/YYYY')
//=> '02/11/2014'

var dates = [new Date(1995, 6, 2), new Date(1987, 1, 11), new Date(1989, 6, 10)]
dates.sort(dateFns.compareAsc)
//=> [
//   Wed Feb 11 1987 00:00:00,
//   Mon Jul 10 1989 00:00:00,
//   Sun Jul 02 1995 00:00:00
// ]
```

The library is available as an [npm package](https://www.npmjs.com/package/date-fns),
a Bower package. To install a package run:

```bash
npm install date-fns --save
# or with yarn
yarn add date-fns
# or with bower
bower install date-fns
```

Also, you can simply download the library from
[the releases page](https://github.com/date-fns/date-fns/releases).

## Docs

[See date-fns.org](https://date-fns.org/) for more details, API,
and other docs.

## License

[MIT © Sasha Koss](https://kossnocorp.mit-license.org/)
