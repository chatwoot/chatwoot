import {PascalCase} from './pascal-case';

/**
Convert object properties to pascal case recursively.

This can be useful when, for example, converting some API types from a different style.

@see PascalCase
@see PascalCasedProperties

@example
```
interface User {
	userId: number;
	userName: string;
}

interface UserWithFriends {
	userInfo: User;
	userFriends: User[];
}

const result: PascalCasedPropertiesDeep<UserWithFriends> = {
	UserInfo: {
		UserId: 1,
		UserName: 'Tom',
	},
	UserFriends: [
		{
			UserId: 2,
			UserName: 'Jerry',
		},
		{
			UserId: 3,
			UserName: 'Spike',
		},
	],
};
```

@category Template Literals
*/
export type PascalCasedPropertiesDeep<Value> = Value extends Function
	? Value
	: Value extends Array<infer U>
	? Array<PascalCasedPropertiesDeep<U>>
	: Value extends Set<infer U>
	? Set<PascalCasedPropertiesDeep<U>> : {
			[K in keyof Value as PascalCase<K>]: PascalCasedPropertiesDeep<Value[K]>;
	};
