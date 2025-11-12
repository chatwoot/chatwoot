declare global {
	interface SymbolConstructor {
		readonly observable: symbol;
	}
}

/**
Matches a value that is like an [Observable](https://github.com/tc39/proposal-observable).

@category Basic
*/
export interface ObservableLike {
	subscribe(observer: (value: unknown) => void): void;
	[Symbol.observable](): ObservableLike;
}
