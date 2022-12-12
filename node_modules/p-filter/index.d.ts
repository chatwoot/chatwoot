import {Options as PMapOptions} from 'p-map';

declare namespace pFilter {
	type Options = PMapOptions;
}

declare const pFilter: {
	/**
	Filter promises concurrently.

	@param input - Iterated over concurrently in the `filterer` function.
	@param filterer - The filterer function that decides whether an element should be included into result.

	@example
	```
	import pFilter = require('p-filter');
	import getWeather from 'get-weather'; // not a real module

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
	*/
	<ValueType>(
		input: Iterable<ValueType | PromiseLike<ValueType>>,
		filterer: (
			element: ValueType,
			index: number
		) => boolean | PromiseLike<boolean>,
		options?: pFilter.Options
	): Promise<ValueType[]>;

	// TODO: Remove this for the next major release, refactor the whole definition to:
	// declare function pFilter<ValueType>(
	// 	input: Iterable<ValueType | PromiseLike<ValueType>>,
	// 	filterer: (
	// 		element: ValueType,
	// 		index: number
	// 	) => boolean | PromiseLike<boolean>,
	// 	options?: pFilter.Options
	// ): Promise<ValueType[]>;
	// export = pFilter;
	default: typeof pFilter;
};

export = pFilter;
