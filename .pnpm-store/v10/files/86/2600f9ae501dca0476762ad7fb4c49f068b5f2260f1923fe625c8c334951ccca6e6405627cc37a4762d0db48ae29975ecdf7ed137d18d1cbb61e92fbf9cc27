# log-update

> Log by overwriting the previous output in the terminal.\
> Useful for rendering progress bars, animations, etc.

![](screenshot.gif)

## Install

```sh
npm install log-update
```

## Usage

```js
import logUpdate from 'log-update';

const frames = ['-', '\\', '|', '/'];
let index = 0;

setInterval(() => {
	const frame = frames[index = ++index % frames.length];

	logUpdate(
`
        ♥♥
   ${frame} unicorns ${frame}
        ♥♥
`
	);
}, 80);
```

## API

### logUpdate(text…)

Log to stdout.

### logUpdate.clear()

Clear the logged output.

### logUpdate.done()

Persist the logged output.

Useful if you want to start a new log session below the current one.

### logUpdateStderr(text…)

Log to stderr.

### logUpdateStderr.clear()
### logUpdateStderr.done()

### createLogUpdate(stream, options?)

Get a `logUpdate` method that logs to the specified stream.

#### options

Type: `object`

##### showCursor

Type: `boolean`\
Default: `false`

Show the cursor. This can be useful when a CLI accepts input from a user.

```js
import logUpdate from 'log-update';

// Write output but don't hide the cursor
const log = logUpdate.create(process.stdout, {
	showCursor: true
});
```

## Examples

- [listr](https://github.com/SamVerschueren/listr) - Uses this module to render an interactive task list
- [ora](https://github.com/sindresorhus/ora) - Uses this module to render awesome spinners
- [speed-test](https://github.com/sindresorhus/speed-test) - Uses this module to render a [spinner](https://github.com/sindresorhus/elegant-spinner)

---

<div align="center">
	<b>
		<a href="https://tidelift.com/subscription/pkg/npm-log-update?utm_source=npm-log-update&utm_medium=referral&utm_campaign=readme">Get professional support for this package with a Tidelift subscription</a>
	</b>
	<br>
	<sub>
		Tidelift helps make open source sustainable for maintainers while giving companies<br>assurances about security, maintenance, and licensing for their dependencies.
	</sub>
</div>
