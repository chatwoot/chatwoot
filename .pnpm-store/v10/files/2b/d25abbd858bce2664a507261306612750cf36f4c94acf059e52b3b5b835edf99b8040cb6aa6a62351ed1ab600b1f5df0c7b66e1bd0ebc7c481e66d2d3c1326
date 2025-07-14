import {PascalCase} from './pascal-case';

/**
Convert object properties to pascal case but not recursively.

This can be useful when, for example, converting some API types from a different style.

@see PascalCase
@see PascalCasedPropertiesDeep

@example
```
interface User {
	userId: number;
	userName: string;
}

const result: PascalCasedProperties<User> = {
	UserId: 1,
	UserName: 'Tom',
};
```

@category Template Literals
*/
export type PascalCasedProperties<Value> = Value extends Function
	? Value
	: Value extends Array<infer U>
	? Value
	: { [K in keyof Value as PascalCase<K>]: Value[K] };
