import chalk from 'chalk';
import isUnicodeSupported from 'is-unicode-supported';

const main = {
	info: chalk.blue('ℹ'),
	success: chalk.green('✔'),
	warning: chalk.yellow('⚠'),
	error: chalk.red('✖'),
};

const fallback = {
	info: chalk.blue('i'),
	success: chalk.green('√'),
	warning: chalk.yellow('‼'),
	error: chalk.red('×'),
};

const logSymbols = isUnicodeSupported() ? main : fallback;

export default logSymbols;
