# p-filter [![Build Status](https://travis-ci.org/sindresorhus/p-filter.svg?branch=master)](https://travis-ci.org/sindresorhus/p-filter)

> Filter promises concurrently

Useful when you need to run promise-returning & async functions multiple times with different inputs concurrently and get a filtered down result.


## Install

```
$ npm install p-filter
```


## Usage

```js
const pFilter = require('p-filter');
const getWeather = require('get-weather'); // not a real module

const places = [
	getCapital('Norway').then(info => info.name),
	'Bangkok, Thailand',
	'Berlin, Germany',
	'Tokyo, Japan'
];

const filterer = async place => {
	const weather = await getWeather(place);
	return weather.temperature > 30;
};

(async () => {
	const result = await pFilter(places, filterer);

	console.log(result);
	//=> ['Bangkok, Thailand']
})();
```


## API

### pFilter(input, filterer, [options])

Returns a `Promise` that is fulfilled when all promises in `input` and ones returned from `filterer` are fulfilled, or rejects if any of the promises reject. The fulfilled value is an `Array` of the fulfilled values returned from `filterer` in `input` order.

#### input

Type: `Iterable<Promise|any>`

Iterated over concurrently in the `filterer` function.

#### filterer(element, index)

Type: `Function`

The filterer function that decides whether an element should be included into result. Expected to return `boolean | Promise<boolean>`.

#### options

Type: `Object`

##### concurrency

Type: `number`<br>
Default: `Infinity`<br>
Minimum: `1`

Number of concurrently pending promises returned by `filterer`.


## Related

- [p-locate](https://github.com/sindresorhus/p-locate) - Get the first fulfilled promise that satisfies the provided testing function
- [p-map](https://github.com/sindresorhus/p-map) - Map over promises concurrently
- [p-times](https://github.com/sindresorhus/p-times) - Run promise-returning & async functions a specific number of times concurrently
- [More…](https://github.com/sindresorhus/promise-fun)


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
