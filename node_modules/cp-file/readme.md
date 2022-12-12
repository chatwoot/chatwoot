# cp-file [![Build Status](https://travis-ci.org/sindresorhus/cp-file.svg?branch=master)](https://travis-ci.org/sindresorhus/cp-file) [![Coverage Status](https://coveralls.io/repos/github/sindresorhus/cp-file/badge.svg?branch=master)](https://coveralls.io/github/sindresorhus/cp-file?branch=master)

> Copy a file


## Highlights

- Fast by using streams in the async version and [`fs.copyFileSync()`](https://nodejs.org/api/fs.html#fs_fs_copyfilesync_src_dest_flags) in the synchronous version.
- Resilient by using [graceful-fs](https://github.com/isaacs/node-graceful-fs).
- User-friendly by creating non-existent destination directories for you.
- Can be safe by turning off [overwriting](#optionsoverwrite).
- User-friendly errors.


## Install

```
$ npm install cp-file
```


## Usage

```js
const cpFile = require('cp-file');

(async () => {
	await cpFile('source/unicorn.png', 'destination/unicorn.png');
	console.log('File copied');
})();
```


## API

### cpFile(source, destination, [options])

Returns a `Promise` that resolves when the file is copied.

### cpFile.sync(source, destination, [options])

#### source

Type: `string`

File you want to copy.

#### destination

Type: `string`

Where you want the file copied.

#### options

Type: `Object`

##### overwrite

Type: `boolean`<br>
Default: `true`

Overwrite existing file.

### cpFile.on('progress', handler)

Progress reporting. Only available when using the async method.

#### handler(data)

Type: `Function`

##### data

```js
{
	src: string,
	dest: string,
	size: number,
	written: number,
	percent: number
}
```

- `src` and `dest` are absolute paths.
- `size` and `written` are in bytes.
- `percent` is a value between `0` and `1`.

###### Notes

- For empty files, the `progress` event is emitted only once.
- The `.on()` method is available only right after the initial `cpFile()` call. So make sure
you add a `handler` before `.then()`:

```js
(async () => {
	await cpFile(source, destination).on('progress', data => {
		// …
	});
})();
```


## Related

- [cpy](https://github.com/sindresorhus/cpy) - Copy files
- [cpy-cli](https://github.com/sindresorhus/cpy-cli) - Copy files on the command-line
- [move-file](https://github.com/sindresorhus/move-file) - Move a file
- [make-dir](https://github.com/sindresorhus/make-dir) - Make a directory and its parents if needed


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
