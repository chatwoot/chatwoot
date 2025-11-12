/**
Remove spaces from the left side.
*/
type TrimLeft<V extends string> = V extends ` ${infer R}` ? TrimLeft<R> : V;

/**
Remove spaces from the right side.
*/
type TrimRight<V extends string> = V extends `${infer R} ` ? TrimRight<R> : V;

/**
Remove leading and trailing spaces from a string.

@example
```
import {Trim} from 'type-fest';

Trim<' foo '>
//=> 'foo'
```

@category Template Literals
*/
export type Trim<V extends string> = TrimLeft<TrimRight<V>>;
