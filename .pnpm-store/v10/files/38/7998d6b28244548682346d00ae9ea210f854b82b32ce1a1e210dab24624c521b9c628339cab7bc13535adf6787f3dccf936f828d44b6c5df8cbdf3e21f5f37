import {DelimiterCase} from './delimiter-case';

/**
Convert object properties to delimiter case but not recursively.

This can be useful when, for example, converting some API types from a different style.

@see DelimiterCase
@see DelimiterCasedPropertiesDeep

@example
```
interface User {
	userId: number;
	userName: string;
}

const result: DelimiterCasedProperties<User, '-'> = {
	'user-id': 1,
	'user-name': 'Tom',
};
```

@category Template Literals
*/
export type DelimiterCasedProperties<
	Value,
	Delimiter extends string
> = Value extends Function
	? Value
	: Value extends Array<infer U>
	? Value
	: { [K in keyof Value as DelimiterCase<K, Delimiter>]: Value[K] };
