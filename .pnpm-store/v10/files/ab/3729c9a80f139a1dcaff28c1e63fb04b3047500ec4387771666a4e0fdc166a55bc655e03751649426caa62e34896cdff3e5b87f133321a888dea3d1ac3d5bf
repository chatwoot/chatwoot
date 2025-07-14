# pkg-dir

> Find the root directory of a Node.js project or npm package

## Install

```sh
npm install pkg-dir
```

## Usage

```
/
└── Users
    └── sindresorhus
        └── foo
            ├── package.json
            └── bar
                ├── baz
                └── example.js
```

```js
// example.js
import {packageDirectory} from 'pkg-dir';

console.log(await packageDirectory());
//=> '/Users/sindresorhus/foo'
```

## API

### packageDirectory(option?)

Returns a `Promise` for either the project root path or `undefined` if it could not be found.

### packageDirectorySync(options?)

Returns the project root path or `undefined` if it could not be found.

#### options

Type: `object`

##### cwd

Type: `string`\
Default: `process.cwd()`

The directory to start searching from.

## Related

- [pkg-dir-cli](https://github.com/sindresorhus/pkg-dir-cli) - CLI for this module
- [pkg-up](https://github.com/sindresorhus/pkg-up) - Find the closest package.json file
- [find-up](https://github.com/sindresorhus/find-up) - Find a file by walking up parent directories

---

<div align="center">
	<b>
		<a href="https://tidelift.com/subscription/pkg/npm-pkg-dir?utm_source=npm-pkg-dir&utm_medium=referral&utm_campaign=readme">Get professional support for this package with a Tidelift subscription</a>
	</b>
	<br>
	<sub>
		Tidelift helps make open source sustainable for maintainers while giving companies<br>assurances about security, maintenance, and licensing for their dependencies.
	</sub>
</div>
