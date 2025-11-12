import process from 'node:process';
import stringWidth from 'string-width';
import chalk from 'chalk';
import widestLine from 'widest-line';
import cliBoxes from 'cli-boxes';
import camelCase from 'camelcase';
import ansiAlign from 'ansi-align';
import wrapAnsi from 'wrap-ansi';

const NEWLINE = '\n';
const PAD = ' ';
const NONE = 'none';

const terminalColumns = () => {
	const {env, stdout, stderr} = process;

	if (stdout?.columns) {
		return stdout.columns;
	}

	if (stderr?.columns) {
		return stderr.columns;
	}

	if (env.COLUMNS) {
		return Number.parseInt(env.COLUMNS, 10);
	}

	return 80;
};

const getObject = detail => typeof detail === 'number' ? {
	top: detail,
	right: detail * 3,
	bottom: detail,
	left: detail * 3,
} : {
	top: 0,
	right: 0,
	bottom: 0,
	left: 0,
	...detail,
};

const getBorderWidth = borderStyle => borderStyle === NONE ? 0 : 2;

const getBorderChars = borderStyle => {
	const sides = [
		'topLeft',
		'topRight',
		'bottomRight',
		'bottomLeft',
		'left',
		'right',
		'top',
		'bottom',
	];

	let characters;

	// Create empty border style
	if (borderStyle === NONE) {
		borderStyle = {};
		for (const side of sides) {
			borderStyle[side] = '';
		}
	}

	if (typeof borderStyle === 'string') {
		characters = cliBoxes[borderStyle];

		if (!characters) {
			throw new TypeError(`Invalid border style: ${borderStyle}`);
		}
	} else {
		// Ensure retro-compatibility
		if (typeof borderStyle?.vertical === 'string') {
			borderStyle.left = borderStyle.vertical;
			borderStyle.right = borderStyle.vertical;
		}

		// Ensure retro-compatibility
		if (typeof borderStyle?.horizontal === 'string') {
			borderStyle.top = borderStyle.horizontal;
			borderStyle.bottom = borderStyle.horizontal;
		}

		for (const side of sides) {
			if (borderStyle[side] === null || typeof borderStyle[side] !== 'string') {
				throw new TypeError(`Invalid border style: ${side}`);
			}
		}

		characters = borderStyle;
	}

	return characters;
};

const makeTitle = (text, horizontal, alignment) => {
	let title = '';

	const textWidth = stringWidth(text);

	switch (alignment) {
		case 'left': {
			title = text + horizontal.slice(textWidth);
			break;
		}

		case 'right': {
			title = horizontal.slice(textWidth) + text;
			break;
		}

		default: {
			horizontal = horizontal.slice(textWidth);

			if (horizontal.length % 2 === 1) { // This is needed in case the length is odd
				horizontal = horizontal.slice(Math.floor(horizontal.length / 2));
				title = horizontal.slice(1) + text + horizontal; // We reduce the left part of one character to avoid the bar to go beyond its limit
			} else {
				horizontal = horizontal.slice(horizontal.length / 2);
				title = horizontal + text + horizontal;
			}

			break;
		}
	}

	return title;
};

const makeContentText = (text, {padding, width, textAlignment, height}) => {
	text = ansiAlign(text, {align: textAlignment});
	let lines = text.split(NEWLINE);
	const textWidth = widestLine(text);

	const max = width - padding.left - padding.right;

	if (textWidth > max) {
		const newLines = [];
		for (const line of lines) {
			const createdLines = wrapAnsi(line, max, {hard: true});
			const alignedLines = ansiAlign(createdLines, {align: textAlignment});
			const alignedLinesArray = alignedLines.split('\n');
			const longestLength = Math.max(...alignedLinesArray.map(s => stringWidth(s)));

			for (const alignedLine of alignedLinesArray) {
				let paddedLine;
				switch (textAlignment) {
					case 'center': {
						paddedLine = PAD.repeat((max - longestLength) / 2) + alignedLine;
						break;
					}

					case 'right': {
						paddedLine = PAD.repeat(max - longestLength) + alignedLine;
						break;
					}

					default: {
						paddedLine = alignedLine;
						break;
					}
				}

				newLines.push(paddedLine);
			}
		}

		lines = newLines;
	}

	if (textAlignment === 'center' && textWidth < max) {
		lines = lines.map(line => PAD.repeat((max - textWidth) / 2) + line);
	} else if (textAlignment === 'right' && textWidth < max) {
		lines = lines.map(line => PAD.repeat(max - textWidth) + line);
	}

	const paddingLeft = PAD.repeat(padding.left);
	const paddingRight = PAD.repeat(padding.right);

	lines = lines.map(line => {
		const newLine = paddingLeft + line + paddingRight;

		return newLine + PAD.repeat(width - stringWidth(newLine));
	});

	if (padding.top > 0) {
		lines = [...Array.from({length: padding.top}).fill(PAD.repeat(width)), ...lines];
	}

	if (padding.bottom > 0) {
		lines = [...lines, ...Array.from({length: padding.bottom}).fill(PAD.repeat(width))];
	}

	if (height && lines.length > height) {
		lines = lines.slice(0, height);
	} else if (height && lines.length < height) {
		lines = [...lines, ...Array.from({length: height - lines.length}).fill(PAD.repeat(width))];
	}

	return lines.join(NEWLINE);
};

const boxContent = (content, contentWidth, options) => {
	const colorizeBorder = border => {
		const newBorder = options.borderColor ? getColorFunction(options.borderColor)(border) : border;
		return options.dimBorder ? chalk.dim(newBorder) : newBorder;
	};

	const colorizeContent = content => options.backgroundColor ? getBGColorFunction(options.backgroundColor)(content) : content;

	const chars = getBorderChars(options.borderStyle);
	const columns = terminalColumns();
	let marginLeft = PAD.repeat(options.margin.left);

	if (options.float === 'center') {
		const marginWidth = Math.max((columns - contentWidth - getBorderWidth(options.borderStyle)) / 2, 0);
		marginLeft = PAD.repeat(marginWidth);
	} else if (options.float === 'right') {
		const marginWidth = Math.max(columns - contentWidth - options.margin.right - getBorderWidth(options.borderStyle), 0);
		marginLeft = PAD.repeat(marginWidth);
	}

	let result = '';

	if (options.margin.top) {
		result += NEWLINE.repeat(options.margin.top);
	}

	if (options.borderStyle !== NONE || options.title) {
		result += colorizeBorder(marginLeft + chars.topLeft + (options.title ? makeTitle(options.title, chars.top.repeat(contentWidth), options.titleAlignment) : chars.top.repeat(contentWidth)) + chars.topRight) + NEWLINE;
	}

	const lines = content.split(NEWLINE);

	result += lines.map(line => marginLeft + colorizeBorder(chars.left) + colorizeContent(line) + colorizeBorder(chars.right)).join(NEWLINE);

	if (options.borderStyle !== NONE) {
		result += NEWLINE + colorizeBorder(marginLeft + chars.bottomLeft + chars.bottom.repeat(contentWidth) + chars.bottomRight);
	}

	if (options.margin.bottom) {
		result += NEWLINE.repeat(options.margin.bottom);
	}

	return result;
};

const sanitizeOptions = options => {
	// If fullscreen is enabled, max-out unspecified width/height
	if (options.fullscreen && process?.stdout) {
		let newDimensions = [process.stdout.columns, process.stdout.rows];

		if (typeof options.fullscreen === 'function') {
			newDimensions = options.fullscreen(...newDimensions);
		}

		options.width ||= newDimensions[0];

		options.height ||= newDimensions[1];
	}

	// If width is provided, make sure it's not below 1
	options.width &&= Math.max(1, options.width - getBorderWidth(options.borderStyle));

	// If height is provided, make sure it's not below 1
	options.height &&= Math.max(1, options.height - getBorderWidth(options.borderStyle));

	return options;
};

const formatTitle = (title, borderStyle) => borderStyle === NONE ? title : ` ${title} `;

const determineDimensions = (text, options) => {
	options = sanitizeOptions(options);
	const widthOverride = options.width !== undefined;
	const columns = terminalColumns();
	const borderWidth = getBorderWidth(options.borderStyle);
	const maxWidth = columns - options.margin.left - options.margin.right - borderWidth;

	const widest = widestLine(wrapAnsi(text, columns - borderWidth, {hard: true, trim: false})) + options.padding.left + options.padding.right;

	// If title and width are provided, title adheres to fixed width
	if (options.title && widthOverride) {
		options.title = options.title.slice(0, Math.max(0, options.width - 2));
		options.title &&= formatTitle(options.title, options.borderStyle);
	} else if (options.title) {
		options.title = options.title.slice(0, Math.max(0, maxWidth - 2));

		// Recheck if title isn't empty now
		if (options.title) {
			options.title = formatTitle(options.title, options.borderStyle);
			// If the title is larger than content, box adheres to title width
			if (stringWidth(options.title) > widest) {
				options.width = stringWidth(options.title);
			}
		}
	}

	// If fixed width is provided, use it or content width as reference
	options.width ||= widest;

	if (!widthOverride) {
		if ((options.margin.left && options.margin.right) && options.width > maxWidth) {
			// Let's assume we have margins: left = 3, right = 5, in total = 8
			const spaceForMargins = columns - options.width - borderWidth;
			// Let's assume we have space = 4
			const multiplier = spaceForMargins / (options.margin.left + options.margin.right);
			// Here: multiplier = 4/8 = 0.5
			options.margin.left = Math.max(0, Math.floor(options.margin.left * multiplier));
			options.margin.right = Math.max(0, Math.floor(options.margin.right * multiplier));
			// Left: 3 * 0.5 = 1.5 -> 1
			// Right: 6 * 0.5 = 3
		}

		// Re-cap width considering the margins after shrinking
		options.width = Math.min(options.width, columns - borderWidth - options.margin.left - options.margin.right);
	}

	// Prevent padding overflow
	if (options.width - (options.padding.left + options.padding.right) <= 0) {
		options.padding.left = 0;
		options.padding.right = 0;
	}

	if (options.height && options.height - (options.padding.top + options.padding.bottom) <= 0) {
		options.padding.top = 0;
		options.padding.bottom = 0;
	}

	return options;
};

const isHex = color => color.match(/^#(?:[0-f]{3}){1,2}$/i);
const isColorValid = color => typeof color === 'string' && (chalk[color] ?? isHex(color));
const getColorFunction = color => isHex(color) ? chalk.hex(color) : chalk[color];
const getBGColorFunction = color => isHex(color) ? chalk.bgHex(color) : chalk[camelCase(['bg', color])];

export default function boxen(text, options) {
	options = {
		padding: 0,
		borderStyle: 'single',
		dimBorder: false,
		textAlignment: 'left',
		float: 'left',
		titleAlignment: 'left',
		...options,
	};

	// This option is deprecated
	if (options.align) {
		options.textAlignment = options.align;
	}

	if (options.borderColor && !isColorValid(options.borderColor)) {
		throw new Error(`${options.borderColor} is not a valid borderColor`);
	}

	if (options.backgroundColor && !isColorValid(options.backgroundColor)) {
		throw new Error(`${options.backgroundColor} is not a valid backgroundColor`);
	}

	options.padding = getObject(options.padding);
	options.margin = getObject(options.margin);

	options = determineDimensions(text, options);

	text = makeContentText(text, options);

	return boxContent(text, options.width, options);
}

export {default as _borderStyles} from 'cli-boxes';
