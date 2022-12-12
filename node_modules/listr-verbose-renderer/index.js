'use strict';
const figures = require('figures');
const cliCursor = require('cli-cursor');
const utils = require('./lib/utils');

const renderHelper = (task, event, options) => {
	const log = utils.log.bind(undefined, options);

	if (event.type === 'STATE') {
		const message = task.isPending() ? 'started' : task.state;

		log(`${task.title} [${message}]`);

		if (task.isSkipped() && task.output) {
			log(`${figures.arrowRight} ${task.output}`);
		}
	} else if (event.type === 'DATA') {
		log(`${figures.arrowRight} ${event.data}`);
	} else if (event.type === 'TITLE') {
		log(`${task.title} [title changed]`);
	}
};

const render = (tasks, options) => {
	for (const task of tasks) {
		task.subscribe(
			event => {
				if (event.type === 'SUBTASKS') {
					render(task.subtasks, options);
					return;
				}

				renderHelper(task, event, options);
			},
			err => {
				console.log(err);
			}
		);
	}
};

class VerboseRenderer {
	constructor(tasks, options) {
		this._tasks = tasks;
		this._options = Object.assign({
			dateFormat: 'HH:mm:ss'
		}, options);
	}

	static get nonTTY() {
		return true;
	}

	render() {
		cliCursor.hide();
		render(this._tasks, this._options);
	}

	end() {
		cliCursor.show();
	}
}

module.exports = VerboseRenderer;
