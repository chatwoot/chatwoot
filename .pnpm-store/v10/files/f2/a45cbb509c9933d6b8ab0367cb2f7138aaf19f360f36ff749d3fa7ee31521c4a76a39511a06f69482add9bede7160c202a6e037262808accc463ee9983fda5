/**
Returns a boolean for whether given two types are equal.

@link https://github.com/microsoft/TypeScript/issues/27024#issuecomment-421529650
*/
type IsEqual<T, U> =
	(<G>() => G extends T ? 1 : 2) extends
	(<G>() => G extends U ? 1 : 2)
		? true
		: false;

/**
Returns a boolean for whether the given array includes the given item.

This can be useful if another type wants to make a decision based on whether the array includes that item.

@example
```
import {Includes} from 'type-fest';

type hasRed<array extends any[]> = Includes<array, 'red'>;
```

@category Utilities
*/
export type Includes<Value extends any[], Item> =
	IsEqual<Value[0], Item> extends true
		? true
		: Value extends [Value[0], ...infer rest]
			? Includes<rest, Item>
			: false;
