/**
Flatten the type output to improve type hints shown in editors.

@example
```
import {Simplify} from 'type-fest';

type PositionProps = {
	top: number;
	left: number;
};

type SizeProps = {
	width: number;
	height: number;
};

// In your editor, hovering over `Props` will show a flattened object with all the properties.
type Props = Simplify<PositionProps & SizeProps>;
```

@category Utilities
*/
export type Simplify<T> = {[KeyType in keyof T]: T[KeyType]};
