# cpy

> Copy files

## Why

- Fast by using streams.
- Resilient by using [graceful-fs](https://github.com/isaacs/node-graceful-fs).
- User-friendly by accepting [globs](https://github.com/sindresorhus/globby#globbing-patterns) and creating non-existent destination directories.
- User-friendly error messages.
- Progress reporting.

## Install

```
$ npm install cpy
```

## Usage

```js
const cpy = require('cpy');

(async () => {
	await cpy(['source/*.png', '!source/goat.png'], 'destination');
	console.log('Files copied!');
})();
```

## API

### cpy(source, destination, options?)

Returns a `Promise<string[]>` with the destination file paths.

#### source

Type: `string | string[]`

Files to copy.

If any of the files do not exist, an error will be thrown (does not apply to globs).

#### destination

Type: `string`

Destination directory.

#### options

Type: `object`

Options are passed to [globby](https://github.com/sindresorhus/globby#options).

In addition, you can specify the below options.

##### cwd

Type: `string`\
Default: `process.cwd()`

Working directory to find source files.

##### overwrite

Type: `boolean`\
Default: `true`

Overwrite existing files.

##### parents

Type: `boolean`\
Default: `false`

Preserve path structure.

##### rename

Type: `string | Function`

Filename or function returning a filename used to rename every file in `source`.

```js
const cpy = require('cpy');

(async () => {
	await cpy('foo.js', 'destination', {
		rename: basename => `prefix-${basename}`
	});
})();
```

##### concurrency

Type: `number`\
Default: `(os.cpus().length || 1) * 2`

Number of files being copied concurrently.

##### ignoreJunk

Type: `boolean`\
Default: `true`

Ignores [junk](https://github.com/sindresorhus/junk) files.

##### filter

Type: `Function`

Function to filter files to copy.

Receives a source file object as the first argument.

Return true to include, false to exclude. You can also return a Promise that resolves to true or false.

```js
const cpy = require('cpy');

(async () => {
	await cpy('foo', 'destination', {
		filter: file => file.extension !== 'nocopy'
	});
})();
```

##### Source file object

###### path

Type: `string`\
Example: `'/tmp/dir/foo.js'`

Resolved path to the file.

###### relativePath

Type: `string`\
Example: `'dir/foo.js'` if `cwd` was `'/tmp'`

Relative path to the file from `cwd`.

###### name

Type: `string`\
Example: `'foo.js'`

Filename with extension.

###### nameWithoutExtension

Type: `string`\
Example: `'foo'`

Filename without extension.

###### extension

Type: `string`\
Example: `'js'`

File extension.

## Progress reporting

### cpy.on('progress', handler)

#### handler(progress)

Type: `Function`

##### progress

```js
{
	completedFiles: number,
	totalFiles: number,
	completedSize: number,
	percent: number
}
```

- `completedSize` is in bytes
- `percent` is a value between `0` and `1`

Note that the `.on()` method is available only right after the initial `cpy` call, so make sure you add a `handler` before awaiting the promise:

```js
(async () => {
	await cpy(source, destination).on('progress', progress => {
		// …
	});
})();
```

## Related

- [cpy-cli](https://github.com/sindresorhus/cpy-cli) - CLI for this module
- [cp-file](https://github.com/sindresorhus/cp-file) - Copy a single file
- [move-file](https://github.com/sindresorhus/move-file) - Move a file
- [make-dir](https://github.com/sindresorhus/make-dir) - Make a directory and its parents if needed
