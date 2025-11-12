# find-cache-dir

> Finds the common standard cache directory

The [`nyc`](https://github.com/istanbuljs/nyc) and [`AVA`](https://ava.li) projects decided to standardize on a common directory structure for storing cache information:

```sh
# nyc
./node_modules/.cache/nyc

# ava
./node_modules/.cache/ava

# your-module
./node_modules/.cache/your-module
```

This module makes it easy to correctly locate the cache directory according to this shared spec. If this pattern becomes ubiquitous, clearing the cache for multiple dependencies becomes easy and consistent:

```
rm -rf ./node_modules/.cache
```

## Install

```sh
npm install find-cache-dir
```

## Usage

```js
import findCacheDirectory from 'find-cache-dir';

findCacheDirectory({name: 'unicorns'});
//=> '/user/path/node-modules/.cache/unicorns'
```

## API

### findCacheDirectory(options?)

Finds the cache directory using the given options.

The algorithm checks for the `CACHE_DIR` environmental variable and uses it if it is not set to `true`, `false`, `1` or `0`. If one is not found, it tries to find a `package.json` file, searching every parent directory of the `cwd` specified (or implied from other options). It returns a `string` containing the absolute path to the cache directory, or `undefined` if `package.json` was never found or if the `node_modules` directory is unwritable.

#### options

Type: `object`

##### name

*Required*\
Type: `string`

Should be the same as your project name in `package.json`.

##### files

Type: `string[]`

An array of files that will be searched for a common parent directory. This common parent directory will be used in lieu of the `cwd` option below.

##### cwd

Type: `string`\
Default `process.cwd()`

The directory to start searching for a `package.json` from.

##### create

Type: `boolean`\
Default `false`

Create the directory synchronously before returning.

## Tips

- To test modules using `find-cache-dir`, set the `CACHE_DIR` environment variable to temporarily override the directory that is resolved.

## Adopters

- [`ava`](https://avajs.dev)
- [`nyc`](https://github.com/istanbuljs/nyc)
- [`storybook`](https://github.com/storybookjs/storybook)
- [`babel-loader`](https://github.com/babel/babel-loader)
- [`eslint-loader`](https://github.com/MoOx/eslint-loader)
- [More…](https://www.npmjs.com/browse/depended/find-cache-dir)
