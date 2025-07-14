import {type SpinnerName} from 'cli-spinners';

export type Spinner = {
	readonly interval?: number;
	readonly frames: string[];
};

export type Color =
	| 'black'
	| 'red'
	| 'green'
	| 'yellow'
	| 'blue'
	| 'magenta'
	| 'cyan'
	| 'white'
	| 'gray';

export type PrefixTextGenerator = () => string;

export type SuffixTextGenerator = () => string;

export type Options = {
	/**
	The text to display next to the spinner.
	*/
	readonly text?: string;

	/**
	Text or a function that returns text to display before the spinner. No prefix text will be displayed if set to an empty string.
	*/
	readonly prefixText?: string | PrefixTextGenerator;

	/**
	Text or a function that returns text to display after the spinner text. No suffix text will be displayed if set to an empty string.
	*/
	readonly suffixText?: string | SuffixTextGenerator;

	/**
	The name of one of the provided spinners. See [`example.js`](https://github.com/BendingBender/ora/blob/main/example.js) in this repo if you want to test out different spinners. On Windows (expect for Windows Terminal), it will always use the line spinner as the Windows command-line doesn't have proper Unicode support.

	@default 'dots'

	Or an object like:

	@example
	```
	{
		frames: ['-', '+', '-'],
		interval: 80 // Optional
	}
	```
	*/
	readonly spinner?: SpinnerName | Spinner;

	/**
	The color of the spinner.

	@default 'cyan'
	*/
	readonly color?: Color;

	/**
	Set to `false` to stop Ora from hiding the cursor.

	@default true
	*/
	readonly hideCursor?: boolean;

	/**
	Indent the spinner with the given number of spaces.

	@default 0
	*/
	readonly indent?: number;

	/**
	Interval between each frame.

	Spinners provide their own recommended interval, so you don't really need to specify this.

	Default: Provided by the spinner or `100`.
	*/
	readonly interval?: number;

	/**
	Stream to write the output.

	You could for example set this to `process.stdout` instead.

	@default process.stderr
	*/
	readonly stream?: NodeJS.WritableStream;

	/**
	Force enable/disable the spinner. If not specified, the spinner will be enabled if the `stream` is being run inside a TTY context (not spawned or piped) and/or not in a CI environment.

	Note that `{isEnabled: false}` doesn't mean it won't output anything. It just means it won't output the spinner, colors, and other ansi escape codes. It will still log text.
	*/
	readonly isEnabled?: boolean;

	/**
	Disable the spinner and all log text. All output is suppressed and `isEnabled` will be considered `false`.

	@default false
	*/
	readonly isSilent?: boolean;

	/**
	Discard stdin input (except Ctrl+C) while running if it's TTY. This prevents the spinner from twitching on input, outputting broken lines on `Enter` key presses, and prevents buffering of input while the spinner is running.

	This has no effect on Windows as there's no good way to implement discarding stdin properly there.

	@default true
	*/
	readonly discardStdin?: boolean;
};

export type PersistOptions = {
	/**
	Symbol to replace the spinner with.

	@default ' '
	*/
	readonly symbol?: string;

	/**
	Text to be persisted after the symbol.

	Default: Current `text`.
	*/
	readonly text?: string;

	/**
	Text or a function that returns text to be persisted before the symbol. No prefix text will be displayed if set to an empty string.

	Default: Current `prefixText`.
	*/
	readonly prefixText?: string | PrefixTextGenerator;

	/**
	Text or a function that returns text to be persisted after the text after the symbol. No suffix text will be displayed if set to an empty string.

	Default: Current `suffixText`.
	*/
	readonly suffixText?: string | SuffixTextGenerator;
};

export type PromiseOptions<T> = {
	/**
	The new text of the spinner when the promise is resolved.

	Keeps the existing text if `undefined`.
	*/
	successText?: string | ((result: T) => string) | undefined;

	/**
	The new text of the spinner when the promise is rejected.

	Keeps the existing text if `undefined`.
	*/
	failText?: string | ((error: Error) => string) | undefined;
} & Options;

// eslint-disable-next-line @typescript-eslint/consistent-type-definitions
export interface Ora {
	/**
	Change the text after the spinner.
	*/
	text: string;

	/**
	Change the text or function that returns text before the spinner.

	No prefix text will be displayed if set to an empty string.
	*/
	prefixText: string;

	/**
	Change the text or function that returns text after the spinner text.

	No suffix text will be displayed if set to an empty string.
	*/
	suffixText: string;

	/**
	Change the spinner color.
	*/
	color: Color;

	/**
	Change the spinner indent.
	*/
	indent: number;

	/**
	Get the spinner.
	*/
	get spinner(): Spinner;

	/**
	Set the spinner.
	*/
	set spinner(spinner: SpinnerName | Spinner);

	/**
	A boolean indicating whether the instance is currently spinning.
	*/
	get isSpinning(): boolean;

	/**
	The interval between each frame.

	The interval is decided by the chosen spinner.
	*/
	get interval(): number;

	/**
	Start the spinner.

	@param text - Set the current text.
	@returns The spinner instance.
	*/
	start(text?: string): this;

	/**
	Stop and clear the spinner.

	@returns The spinner instance.
	*/
	stop(): this;

	/**
	Stop the spinner, change it to a green `✔` and persist the current text, or `text` if provided.

	@param text - Will persist text if provided.
	@returns The spinner instance.
	*/
	succeed(text?: string): this;

	/**
	Stop the spinner, change it to a red `✖` and persist the current text, or `text` if provided.

	@param text - Will persist text if provided.
	@returns The spinner instance.
	*/
	fail(text?: string): this;

	/**
	Stop the spinner, change it to a yellow `⚠` and persist the current text, or `text` if provided.

	@param text - Will persist text if provided.
	@returns The spinner instance.
	*/
	warn(text?: string): this;

	/**
	Stop the spinner, change it to a blue `ℹ` and persist the current text, or `text` if provided.

	@param text - Will persist text if provided.
	@returns The spinner instance.
	*/
	info(text?: string): this;

	/**
	Stop the spinner and change the symbol or text.

	@returns The spinner instance.
	*/
	stopAndPersist(options?: PersistOptions): this;

	/**
	Clear the spinner.

	@returns The spinner instance.
	*/
	clear(): this;

	/**
	Manually render a new frame.

	@returns The spinner instance.
	*/
	render(): this;

	/**
	Get a new frame.

	@returns The spinner instance text.
	*/
	frame(): string;
}

/**
Elegant terminal spinner.

@param options - If a string is provided, it is treated as a shortcut for `options.text`.

@example
```
import ora from 'ora';

const spinner = ora('Loading unicorns').start();

setTimeout(() => {
	spinner.color = 'yellow';
	spinner.text = 'Loading rainbows';
}, 1000);
```
*/
export default function ora(options?: string | Options): Ora;

/**
Starts a spinner for a promise or promise-returning function. The spinner is stopped with `.succeed()` if the promise fulfills or with `.fail()` if it rejects.

@param action - The promise to start the spinner for or a promise-returning function.
@param options - If a string is provided, it is treated as a shortcut for `options.text`.
@returns The given promise.

@example
```
import {oraPromise} from 'ora';

await oraPromise(somePromise);
```
*/
export function oraPromise<T>(
	action: PromiseLike<T> | ((spinner: Ora) => PromiseLike<T>),
	options?: string | PromiseOptions<T>
): Promise<T>;

export {default as spinners} from 'cli-spinners';
