'use strict';
const chalk = require('chalk');
const format = require('date-fns/format');

exports.log = (options, output) => {
	const timestamp = format(new Date(), options.dateFormat);

	console.log(chalk.dim(`[${timestamp}]`) + ` ${output}`);
};
