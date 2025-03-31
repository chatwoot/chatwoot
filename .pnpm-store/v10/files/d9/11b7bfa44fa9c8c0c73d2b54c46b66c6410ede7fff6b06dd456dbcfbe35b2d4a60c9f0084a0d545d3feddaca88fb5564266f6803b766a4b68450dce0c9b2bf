import {CamelCase} from './camel-case';

/**
Converts a string literal to pascal-case.

@example
```
import {PascalCase} from 'type-fest';

// Simple

const someVariable: PascalCase<'foo-bar'> = 'FooBar';

// Advanced

type PascalCaseProps<T> = {
	[K in keyof T as PascalCase<K>]: T[K]
};

interface RawOptions {
	'dry-run': boolean;
	'full_family_name': string;
	foo: number;
}

const dbResult: CamelCasedProperties<ModelProps> = {
	DryRun: true,
	FullFamilyName: 'bar.js',
	Foo: 123
};
```

@category Template Literals
*/
export type PascalCase<Value> = CamelCase<Value> extends string
	? Capitalize<CamelCase<Value>>
	: CamelCase<Value>;
