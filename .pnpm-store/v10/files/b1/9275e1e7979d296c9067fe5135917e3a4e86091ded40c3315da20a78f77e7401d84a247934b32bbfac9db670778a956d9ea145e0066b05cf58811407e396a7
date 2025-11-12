import {DelimiterCasedProperties} from './delimiter-cased-properties';

/**
Convert object properties to kebab case but not recursively.

This can be useful when, for example, converting some API types from a different style.

@see KebabCase
@see KebabCasedPropertiesDeep

@example
```
interface User {
	userId: number;
	userName: string;
}

const result: KebabCasedProperties<User> = {
	'user-id': 1,
	'user-name': 'Tom',
};
```

@category Template Literals
*/
export type KebabCasedProperties<Value> = DelimiterCasedProperties<Value, '-'>;
