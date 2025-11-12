import {Options as FastGlobOptions, Entry} from 'fast-glob';

export type GlobEntry = Entry;

export interface GlobTask {
	readonly patterns: string[];
	readonly options: Options;
}

export type ExpandDirectoriesOption =
	| boolean
	| readonly string[]
	| {files?: readonly string[]; extensions?: readonly string[]};

type FastGlobOptionsWithoutCwd = Omit<FastGlobOptions, 'cwd'>;

export interface Options extends FastGlobOptionsWithoutCwd {
	/**
	If set to `true`, `globby` will automatically glob directories for you. If you define an `Array` it will only glob files that matches the patterns inside the `Array`. You can also define an `Object` with `files` and `extensions` like in the example below.

	Note that if you set this option to `false`, you won't get back matched directories unless you set `onlyFiles: false`.

	@default true

	@example
	```
	import {globby} from 'globby';

	const paths = await globby('images', {
		expandDirectories: {
			files: ['cat', 'unicorn', '*.jpg'],
			extensions: ['png']
		}
	});

	console.log(paths);
	//=> ['cat.png', 'unicorn.png', 'cow.jpg', 'rainbow.jpg']
	```
	*/
	readonly expandDirectories?: ExpandDirectoriesOption;

	/**
	Respect ignore patterns in `.gitignore` files that apply to the globbed files.

	@default false
	*/
	readonly gitignore?: boolean;

	/**
	Glob patterns to look for ignore files, which are then used to ignore globbed files.

	This is a more generic form of the `gitignore` option, allowing you to find ignore files with a [compatible syntax](http://git-scm.com/docs/gitignore). For instance, this works with Babel's `.babelignore`, Prettier's `.prettierignore`, or ESLint's `.eslintignore` files.

	@default undefined
	*/
	readonly ignoreFiles?: string | readonly string[];

	/**
	The current working directory in which to search.

	@default process.cwd()
	*/
	readonly cwd?: URL | string;
}

export interface GitignoreOptions {
	readonly cwd?: URL | string;
}

export type GlobbyFilterFunction = (path: URL | string) => boolean;

/**
Find files and directories using glob patterns.

Note that glob patterns can only contain forward-slashes, not backward-slashes, so if you want to construct a glob pattern from path components, you need to use `path.posix.join()` instead of `path.join()`.

@param patterns - See the supported [glob patterns](https://github.com/sindresorhus/globby#globbing-patterns).
@param options - See the [`fast-glob` options](https://github.com/mrmlnc/fast-glob#options-3) in addition to the ones in this package.
@returns The matching paths.

@example
```
import {globby} from 'globby';

const paths = await globby(['*', '!cake']);

console.log(paths);
//=> ['unicorn', 'rainbow']
```
*/
export function globby(
	patterns: string | readonly string[],
	options: Options & {objectMode: true}
): Promise<GlobEntry[]>;
export function globby(
	patterns: string | readonly string[],
	options?: Options
): Promise<string[]>;

/**
Find files and directories using glob patterns.

Note that glob patterns can only contain forward-slashes, not backward-slashes, so if you want to construct a glob pattern from path components, you need to use `path.posix.join()` instead of `path.join()`.

@param patterns - See the supported [glob patterns](https://github.com/sindresorhus/globby#globbing-patterns).
@param options - See the [`fast-glob` options](https://github.com/mrmlnc/fast-glob#options-3) in addition to the ones in this package.
@returns The matching paths.
*/
export function globbySync(
	patterns: string | readonly string[],
	options: Options & {objectMode: true}
): GlobEntry[];
export function globbySync(
	patterns: string | readonly string[],
	options?: Options
): string[];

/**
Find files and directories using glob patterns.

Note that glob patterns can only contain forward-slashes, not backward-slashes, so if you want to construct a glob pattern from path components, you need to use `path.posix.join()` instead of `path.join()`.

@param patterns - See the supported [glob patterns](https://github.com/sindresorhus/globby#globbing-patterns).
@param options - See the [`fast-glob` options](https://github.com/mrmlnc/fast-glob#options-3) in addition to the ones in this package.
@returns The stream of matching paths.

@example
```
import {globbyStream} from 'globby';

for await (const path of globbyStream('*.tmp')) {
	console.log(path);
}
```
*/
export function globbyStream(
	patterns: string | readonly string[],
	options?: Options
): NodeJS.ReadableStream;

/**
Note that you should avoid running the same tasks multiple times as they contain a file system cache. Instead, run this method each time to ensure file system changes are taken into consideration.

@param patterns - See the supported [glob patterns](https://github.com/sindresorhus/globby#globbing-patterns).
@param options - See the [`fast-glob` options](https://github.com/mrmlnc/fast-glob#options-3) in addition to the ones in this package.
@returns An object in the format `{pattern: string, options: object}`, which can be passed as arguments to [`fast-glob`](https://github.com/mrmlnc/fast-glob). This is useful for other globbing-related packages.
*/
export function generateGlobTasks(
	patterns: string | readonly string[],
	options?: Options
): Promise<GlobTask[]>;

/**
@see generateGlobTasks

@returns An object in the format `{pattern: string, options: object}`, which can be passed as arguments to [`fast-glob`](https://github.com/mrmlnc/fast-glob). This is useful for other globbing-related packages.
*/
export function generateGlobTasksSync(
	patterns: string | readonly string[],
	options?: Options
): GlobTask[];

/**
Note that the options affect the results.

This function is backed by [`fast-glob`](https://github.com/mrmlnc/fast-glob#isdynamicpatternpattern-options).

@param patterns - See the supported [glob patterns](https://github.com/sindresorhus/globby#globbing-patterns).
@param options - See the [`fast-glob` options](https://github.com/mrmlnc/fast-glob#options-3).
@returns Whether there are any special glob characters in the `patterns`.
*/
export function isDynamicPattern(
	patterns: string | readonly string[],
	options?: FastGlobOptionsWithoutCwd & {
		/**
		The current working directory in which to search.

		@default process.cwd()
		*/
		readonly cwd?: URL | string;
	}
): boolean;

/**
`.gitignore` files matched by the ignore config are not used for the resulting filter function.

@returns A filter function indicating whether a given path is ignored via a `.gitignore` file.

@example
```
import {isGitIgnored} from 'globby';

const isIgnored = await isGitIgnored();

console.log(isIgnored('some/file'));
```
*/
export function isGitIgnored(options?: GitignoreOptions): Promise<GlobbyFilterFunction>;

/**
@see isGitIgnored

@returns A filter function indicating whether a given path is ignored via a `.gitignore` file.
*/
export function isGitIgnoredSync(options?: GitignoreOptions): GlobbyFilterFunction;
