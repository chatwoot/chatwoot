import {SplitIncludingDelimiters} from './delimiter-case';
import {SnakeCase} from './snake-case';
import {Includes} from './includes';

/**
Returns a boolean for whether the string is screaming snake case.
*/
type IsScreamingSnakeCase<Value extends string> = Value extends Uppercase<Value>
	? Includes<SplitIncludingDelimiters<Lowercase<Value>, '_'>, '_'> extends true
		? true
		: false
	: false;

/**
Convert a string literal to screaming-snake-case.

This can be useful when, for example, converting a camel-cased object property to a screaming-snake-cased SQL column name.

@example
```
import {ScreamingSnakeCase} from 'type-fest';

const someVariable: ScreamingSnakeCase<'fooBar'> = 'FOO_BAR';
```

@category Template Literals
*/
export type ScreamingSnakeCase<Value> = Value extends string
	? IsScreamingSnakeCase<Value> extends true
		? Value
		: Uppercase<SnakeCase<Value>>
	: Value;
