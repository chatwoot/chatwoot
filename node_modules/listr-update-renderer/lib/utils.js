'use strict';
const chalk = require('chalk');
const logSymbols = require('log-symbols');
const figures = require('figures');
const elegantSpinner = require('elegant-spinner');

const pointer = chalk.yellow(figures.pointer);
const skipped = chalk.yellow(figures.arrowDown);

exports.isDefined = x => x !== null && x !== undefined;

exports.getSymbol = (task, options) => {
	if (!task.spinner) {
		task.spinner = elegantSpinner();
	}

	if (task.isPending()) {
		return options.showSubtasks !== false && task.subtasks.length > 0 ? pointer : chalk.yellow(task.spinner());
	}

	if (task.isCompleted()) {
		return logSymbols.success;
	}

	if (task.hasFailed()) {
		return task.subtasks.length > 0 ? pointer : logSymbols.error;
	}

	if (task.isSkipped()) {
		return skipped;
	}

	return ' ';
};
