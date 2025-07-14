# ora

> Elegant terminal spinner

<p align="center">
	<br>
	<img src="screenshot.svg" width="500">
	<br>
</p>

## Install

```sh
npm install ora
```

*Check out [`yocto-spinner`](https://github.com/sindresorhus/yocto-spinner) for a smaller alternative.*

## Usage

```js
import ora from 'ora';

const spinner = ora('Loading unicorns').start();

setTimeout(() => {
	spinner.color = 'yellow';
	spinner.text = 'Loading rainbows';
}, 1000);
```

## API

### ora(text)
### ora(options)

If a string is provided, it is treated as a shortcut for [`options.text`](#text).

#### options

Type: `object`

##### text

Type: `string`

The text to display next to the spinner.

##### prefixText

Type: `string | () => string`

Text or a function that returns text to display before the spinner. No prefix text will be displayed if set to an empty string.

##### suffixText

Type: `string | () => string`

Text or a function that returns text to display after the spinner text. No suffix text will be displayed if set to an empty string.

##### spinner

Type: `string | object`\
Default: `'dots'` <img src="screenshot-spinner.gif" width="14">

The name of one of the [provided spinners](#spinners). See `example.js` in this repo if you want to test out different spinners. On Windows (except for Windows Terminal), it will always use the `line` spinner as the Windows command-line doesn't have proper Unicode support.

Or an object like:

```js
{
	frames: ['-', '+', '-'],
	interval: 80 // Optional
}
```

##### color

Type: `string`\
Default: `'cyan'`\
Values: `'black' | 'red' | 'green' | 'yellow' | 'blue' | 'magenta' | 'cyan' | 'white' | 'gray'`

The color of the spinner.

##### hideCursor

Type: `boolean`\
Default: `true`

Set to `false` to stop Ora from hiding the cursor.

##### indent

Type: `number`\
Default: `0`

Indent the spinner with the given number of spaces.

##### interval

Type: `number`\
Default: Provided by the spinner or `100`

Interval between each frame.

Spinners provide their own recommended interval, so you don't really need to specify this.

##### stream

Type: `stream.Writable`\
Default: `process.stderr`

Stream to write the output.

You could for example set this to `process.stdout` instead.

##### isEnabled

Type: `boolean`

Force enable/disable the spinner. If not specified, the spinner will be enabled if the `stream` is being run inside a TTY context (not spawned or piped) and/or not in a CI environment.

Note that `{isEnabled: false}` doesn't mean it won't output anything. It just means it won't output the spinner, colors, and other ansi escape codes. It will still log text.

##### isSilent

Type: `boolean`\
Default: `false`

Disable the spinner and all log text. All output is suppressed and `isEnabled` will be considered `false`.

##### discardStdin

Type: `boolean`\
Default: `true`

Discard stdin input (except Ctrl+C) while running if it's TTY. This prevents the spinner from twitching on input, outputting broken lines on <kbd>Enter</kbd> key presses, and prevents buffering of input while the spinner is running.

This has no effect on Windows as there is no good way to implement discarding stdin properly there.

### Instance

#### .text <sup>get/set</sup>

Change the text displayed after the spinner.

#### .prefixText <sup>get/set</sup>

Change the text before the spinner.

No prefix text will be displayed if set to an empty string.

#### .suffixText <sup>get/set</sup>

Change the text after the spinner text.

No suffix text will be displayed if set to an empty string.

#### .color <sup>get/set</sup>

Change the spinner color.

#### .spinner <sup>get/set</sup>

Change the spinner.

#### .indent <sup>get/set</sup>

Change the spinner indent.

#### .isSpinning <sup>get</sup>

A boolean indicating whether the instance is currently spinning.

#### .interval <sup>get</sup>

The interval between each frame.

The interval is decided by the chosen spinner.

#### .start(text?)

Start the spinner. Returns the instance. Set the current text if `text` is provided.

#### .stop()

Stop and clear the spinner. Returns the instance.

#### .succeed(text?)

Stop the spinner, change it to a green `✔` and persist the current text, or `text` if provided. Returns the instance. See the GIF below.

#### .fail(text?)

Stop the spinner, change it to a red `✖` and persist the current text, or `text` if provided. Returns the instance. See the GIF below.

#### .warn(text?)

Stop the spinner, change it to a yellow `⚠` and persist the current text, or `text` if provided. Returns the instance.

#### .info(text?)

Stop the spinner, change it to a blue `ℹ` and persist the current text, or `text` if provided. Returns the instance.

#### .stopAndPersist(options?)

Stop the spinner and change the symbol or text. Returns the instance. See the GIF below.

##### options

Type: `object`

###### symbol

Type: `string`\
Default: `' '`

Symbol to replace the spinner with.

###### text

Type: `string`\
Default: Current `'text'`

Text to be persisted after the symbol.

###### prefixText

Type: `string | () => string`\
Default: Current `prefixText`

Text or a function that returns text to be persisted before the symbol. No prefix text will be displayed if set to an empty string.

###### suffixText

Type: `string | () => string`\
Default: Current `suffixText`

Text or a function that returns text to be persisted after the text after the symbol. No suffix text will be displayed if set to an empty string.

<img src="screenshot-2.gif" width="480">

#### .clear()

Clear the spinner. Returns the instance.

#### .render()

Manually render a new frame. Returns the instance.

#### .frame()

Get a new frame.

### oraPromise(action, text)
### oraPromise(action, options)

Starts a spinner for a promise or promise-returning function. The spinner is stopped with `.succeed()` if the promise fulfills or with `.fail()` if it rejects. Returns the promise.

```js
import {oraPromise} from 'ora';

await oraPromise(somePromise);
```

#### action

Type: `Promise | ((spinner: ora.Ora) => Promise)`

#### options

Type: `object`

All of the [options](#options) plus the following:

##### successText

Type: `string | ((result: T) => string) | undefined`

The new text of the spinner when the promise is resolved.

Keeps the existing text if `undefined`.

##### failText

Type: `string | ((error: Error) => string) | undefined`

The new text of the spinner when the promise is rejected.

Keeps the existing text if `undefined`.

### spinners

Type: `Record<string, Spinner>`

All [provided spinners](https://github.com/sindresorhus/cli-spinners/blob/main/spinners.json).

## FAQ

### How do I change the color of the text?

Use [`chalk`](https://github.com/chalk/chalk) or [`yoctocolors`](https://github.com/sindresorhus/yoctocolors):

```js
import ora from 'ora';
import chalk from 'chalk';

const spinner = ora(`Loading ${chalk.red('unicorns')}`).start();
```

### Why does the spinner freeze?

JavaScript is single-threaded, so any synchronous operations will block the spinner's animation. To avoid this, prefer using asynchronous operations.

## Related

- [yocto-spinner](https://github.com/sindresorhus/yocto-spinner) - Tiny terminal spinner
- [cli-spinners](https://github.com/sindresorhus/cli-spinners) - Spinners for use in the terminal

**Ports**

- [CLISpinner](https://github.com/kiliankoe/CLISpinner) - Terminal spinner library for Swift
- [halo](https://github.com/ManrajGrover/halo) - Python port
- [spinners](https://github.com/FGRibreau/spinners) - Terminal spinners for Rust
- [marquee-ora](https://github.com/joeycozza/marquee-ora) - Scrolling marquee spinner for Ora
- [briandowns/spinner](https://github.com/briandowns/spinner) - Terminal spinner/progress indicator for Go
- [tj/go-spin](https://github.com/tj/go-spin) - Terminal spinner package for Go
- [observablehq.com/@victordidenko/ora](https://observablehq.com/@victordidenko/ora) - Ora port to Observable notebooks
- [kia](https://github.com/HarryPeach/kia) - Simple terminal spinners for Deno 🦕
