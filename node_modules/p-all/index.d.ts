declare namespace pAll {
	interface Options {
		/**
		Number of concurrent pending promises. Minimum: `1`.

		@default Infinity
		*/
		concurrency?: number;
	}

	type PromiseFactory<T> = () => PromiseLike<T>;
}

/**
Run promise-returning & async functions concurrently with optional limited concurrency.

@param tasks - Iterable with promise-returning/async functions.
@returns A `Promise` that is fulfilled when all promises returned from calling the functions in `tasks` are fulfilled, or rejects if any of the promises reject. The fulfilled value is an `Array` of the fulfilled values in `tasks` order.

@example
```
import pAll = require('p-all');
import got = require('got');

(async () => {
	const actions = [
		() => got('https://sindresorhus.com'),
		() => got('https://ava.li'),
		() => checkSomething(),
		() => doSomethingElse()
	];

	console.log(await pAll(actions, {concurrency: 2}));
})();
```
*/
declare const pAll: {
	<
		Result1,
		Result2,
		Result3,
		Result4,
		Result5,
		Result6,
		Result7,
		Result8,
		Result9,
		Result10
	>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>,
			pAll.PromiseFactory<Result6>,
			pAll.PromiseFactory<Result7>,
			pAll.PromiseFactory<Result8>,
			pAll.PromiseFactory<Result9>,
			pAll.PromiseFactory<Result10>
		],
		options?: pAll.Options
	): Promise<
		[
			Result1,
			Result2,
			Result3,
			Result4,
			Result5,
			Result6,
			Result7,
			Result8,
			Result9,
			Result10
		]
	>;
	<
		Result1,
		Result2,
		Result3,
		Result4,
		Result5,
		Result6,
		Result7,
		Result8,
		Result9
	>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>,
			pAll.PromiseFactory<Result6>,
			pAll.PromiseFactory<Result7>,
			pAll.PromiseFactory<Result8>,
			pAll.PromiseFactory<Result9>
		],
		options?: pAll.Options
	): Promise<
		[
			Result1,
			Result2,
			Result3,
			Result4,
			Result5,
			Result6,
			Result7,
			Result8,
			Result9
		]
	>;
	<Result1, Result2, Result3, Result4, Result5, Result6, Result7, Result8>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>,
			pAll.PromiseFactory<Result6>,
			pAll.PromiseFactory<Result7>,
			pAll.PromiseFactory<Result8>
		],
		options?: pAll.Options
	): Promise<
		[Result1, Result2, Result3, Result4, Result5, Result6, Result7, Result8]
	>;
	<Result1, Result2, Result3, Result4, Result5, Result6, Result7>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>,
			pAll.PromiseFactory<Result6>,
			pAll.PromiseFactory<Result7>
		],
		options?: pAll.Options
	): Promise<[Result1, Result2, Result3, Result4, Result5, Result6, Result7]>;
	<Result1, Result2, Result3, Result4, Result5, Result6>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>,
			pAll.PromiseFactory<Result6>
		],
		options?: pAll.Options
	): Promise<[Result1, Result2, Result3, Result4, Result5, Result6]>;
	<Result1, Result2, Result3, Result4, Result5>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>,
			pAll.PromiseFactory<Result5>
		],
		options?: pAll.Options
	): Promise<[Result1, Result2, Result3, Result4, Result5]>;
	<Result1, Result2, Result3, Result4>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>,
			pAll.PromiseFactory<Result4>
		],
		options?: pAll.Options
	): Promise<[Result1, Result2, Result3, Result4]>;
	<Result1, Result2, Result3>(
		tasks: [
			pAll.PromiseFactory<Result1>,
			pAll.PromiseFactory<Result2>,
			pAll.PromiseFactory<Result3>
		],
		options?: pAll.Options
	): Promise<[Result1, Result2, Result3]>;
	<Result1, Result2>(
		tasks: [pAll.PromiseFactory<Result1>, pAll.PromiseFactory<Result2>],
		options?: pAll.Options
	): Promise<[Result1, Result2]>;
	<Result1>(
		tasks: [pAll.PromiseFactory<Result1>],
		options?: pAll.Options
	): Promise<[Result1]>;
	<TAll>(
		tasks: Iterable<pAll.PromiseFactory<TAll>> | pAll.PromiseFactory<TAll>[],
		options?: pAll.Options
	): Promise<TAll[]>;

	// TODO: Remove this for the next major release, refactor the whole definition back to multiple overloaded functions
	default: typeof pAll;
};

export = pAll;
