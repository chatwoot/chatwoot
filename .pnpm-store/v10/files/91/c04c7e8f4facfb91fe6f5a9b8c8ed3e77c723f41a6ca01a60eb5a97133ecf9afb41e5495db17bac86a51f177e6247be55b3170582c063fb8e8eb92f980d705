import {type LiteralUnion} from 'type-fest';
import {type BoxStyle, type Boxes as CLIBoxes} from 'cli-boxes';

/**
All box styles.
*/
type Boxes = {
	readonly none: BoxStyle;
} & CLIBoxes;

/**
Characters used for custom border.

@example
```
// attttb
// l    r
// dbbbbc

const border: CustomBorderStyle = {
	topLeft: 'a',
	topRight: 'b',
	bottomRight: 'c',
	bottomLeft: 'd',
	left: 'l',
	right: 'r',
	top: 't',
	bottom: 'b',
};
```
*/
export type CustomBorderStyle = {
	/**
	@deprecated Use `top` and `bottom` instead.
	*/
	horizontal?: string;

	/**
	@deprecated Use `left` and `right` instead.
	*/
	vertical?: string;
} & BoxStyle;

/**
Spacing used for `padding` and `margin`.
*/
export type Spacing = {
	readonly top?: number;
	readonly right?: number;
	readonly bottom?: number;
	readonly left?: number;
};

export type Options = {
	/**
	Color of the box border.
	*/
	readonly borderColor?: LiteralUnion<
	| 'black'
	| 'red'
	| 'green'
	| 'yellow'
	| 'blue'
	| 'magenta'
	| 'cyan'
	| 'white'
	| 'gray'
	| 'grey'
	| 'blackBright'
	| 'redBright'
	| 'greenBright'
	| 'yellowBright'
	| 'blueBright'
	| 'magentaBright'
	| 'cyanBright'
	| 'whiteBright',
	string
	>;

	/**
	Style of the box border.

	@default 'single'
	*/
	readonly borderStyle?: keyof Boxes | CustomBorderStyle;

	/**
	Reduce opacity of the border.

	@default false
	*/
	readonly dimBorder?: boolean;

	/**
	Space between the text and box border.

	@default 0
	*/
	readonly padding?: number | Spacing;

	/**
	Space around the box.

	@default 0
	*/
	readonly margin?: number | Spacing;

	/**
	Float the box on the available terminal screen space.

	@default 'left'
	*/
	readonly float?: 'left' | 'right' | 'center';

	/**
	Color of the background.
	*/
	readonly backgroundColor?: LiteralUnion<
	| 'black'
	| 'red'
	| 'green'
	| 'yellow'
	| 'blue'
	| 'magenta'
	| 'cyan'
	| 'white'
	| 'blackBright'
	| 'redBright'
	| 'greenBright'
	| 'yellowBright'
	| 'blueBright'
	| 'magentaBright'
	| 'cyanBright'
	| 'whiteBright',
	string
	>;

	/**
	Align the text in the box based on the widest line.

	@default 'left'
	@deprecated Use `textAlignment` instead.
	*/
	readonly align?: 'left' | 'right' | 'center';

	/**
	Align the text in the box based on the widest line.

	@default 'left'
	*/
	readonly textAlignment?: 'left' | 'right' | 'center';

	/**
	Display a title at the top of the box.
	If needed, the box will horizontally expand to fit the title.

	@example
	```
	console.log(boxen('foo bar', {title: 'example'}));
	// ┌ example ┐
	// │foo bar  │
	// └─────────┘
	```
	*/
	readonly title?: string;

	/**
	Align the title in the top bar.

	@default 'left'

	@example
	```
	console.log(boxen('foo bar foo bar', {title: 'example', titleAlignment: 'center'}));
	// ┌─── example ───┐
	// │foo bar foo bar│
	// └───────────────┘

	console.log(boxen('foo bar foo bar', {title: 'example', titleAlignment: 'right'}));
	// ┌────── example ┐
	// │foo bar foo bar│
	// └───────────────┘
	```
	*/
	readonly titleAlignment?: 'left' | 'right' | 'center';

	/**
	Set a fixed width for the box.

	__Note__: This disables terminal overflow handling and may cause the box to look broken if the user's terminal is not wide enough.

	@example
	```
	import boxen from 'boxen';

	console.log(boxen('foo bar', {width: 15}));
	// ┌─────────────┐
	// │foo bar      │
	// └─────────────┘
	```
	*/
	readonly width?: number;

	/**
	Set a fixed height for the box.

	__Note__: This option will crop overflowing content.

	@example
	```
	import boxen from 'boxen';

	console.log(boxen('foo bar', {height: 5}));
	// ┌───────┐
	// │foo bar│
	// │       │
	// │       │
	// └───────┘
	```
	*/
	readonly height?: number;

	/**
	__boolean__: Whether or not to fit all available space within the terminal.

	__function__: Pass a callback function to control box dimensions.

	@example
	```
	import boxen from 'boxen';

	console.log(boxen('foo bar', {
		fullscreen: (width, height) => [width, height - 1],
	}));
	```
	*/
	readonly fullscreen?: boolean | ((width: number, height: number) => [width: number, height: number]);
};

/**
Creates a box in the terminal.

@param text - The text inside the box.
@returns The box.

@example
```
import boxen from 'boxen';

console.log(boxen('unicorn', {padding: 1}));
// ┌─────────────┐
// │             │
// │   unicorn   │
// │             │
// └─────────────┘

console.log(boxen('unicorn', {padding: 1, margin: 1, borderStyle: 'double'}));
//
// ╔═════════════╗
// ║             ║
// ║   unicorn   ║
// ║             ║
// ╚═════════════╝
//
```
*/
export default function boxen(text: string, options?: Options): string;
