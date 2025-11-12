# slash

> Convert Windows backslash paths to slash paths: `foo\\bar` ➔ `foo/bar`

[Forward-slash paths can be used in Windows](http://superuser.com/a/176395/6877) as long as they're not extended-length paths and don't contain any non-ascii characters.

This was created since the `path` methods in Node.js outputs `\\` paths on Windows.

## Install

```
$ npm install slash
```

## Usage

```js
import path from 'path';
import slash from 'slash';

const string = path.join('foo', 'bar');
// Unix    => foo/bar
// Windows => foo\\bar

slash(string);
// Unix    => foo/bar
// Windows => foo/bar
```

## API

### slash(path)

Type: `string`

Accepts a Windows backslash path and returns a path with forward slashes.

---

<div align="center">
	<b>
		<a href="https://tidelift.com/subscription/pkg/npm-slash?utm_source=npm-slash&utm_medium=referral&utm_campaign=readme">Get professional support for this package with a Tidelift subscription</a>
	</b>
	<br>
	<sub>
		Tidelift helps make open source sustainable for maintainers while giving companies<br>assurances about security, maintenance, and licensing for their dependencies.
	</sub>
</div>
