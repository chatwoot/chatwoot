declare const stop: unique symbol;

declare namespace pEachSeries {
	type StopSymbol = typeof stop;
}

declare const pEachSeries: {
	/**
	Iterate over promises serially.

	@param input - Iterated over serially in the `iterator` function.
	@param iterator - Return value is ignored unless it's `Promise`, then it's awaited before continuing with the next iteration.
	@returns A `Promise` that fulfills when all promises in `input` and ones returned from `iterator` are fulfilled, or rejects if any of the promises reject. The fulfillment value is the original `input`.

	@example
	```
	import pEachSeries = require('p-each-series');

	const keywords = [
		getTopKeyword(), //=> Promise
		'rainbow',
		'pony'
	];

	const iterator = async element => saveToDiskPromise(element);

	(async () => {
		console.log(await pEachSeries(keywords, iterator));
		//=> ['unicorn', 'rainbow', 'pony']
	})();
	```
	*/
	<ValueType>(
		input: Iterable<PromiseLike<ValueType> | ValueType>,
		iterator: (element: ValueType, index: number) => pEachSeries.StopSymbol | unknown
	): Promise<ValueType[]>;

	/**
	Stop iterating through items by returning `pEachSeries.stop` from the iterator function.

	@example
	```
	const pEachSeries = require('p-each-series');

	// Logs `a` and `b`.
	const result = await pEachSeries(['a', 'b', 'c'], value => {
		console.log(value);

		if (value === 'b') {
			return pEachSeries.stop;
		}
	});

	console.log(result);
	//=> ['a', 'b', 'c']
	```
	*/
	readonly stop: pEachSeries.StopSymbol;

	// TODO: Remove this for the next major release
	default: typeof pEachSeries;
};

export = pEachSeries;
