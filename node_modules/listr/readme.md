# listr

[![Build Status Linux](https://travis-ci.org/SamVerschueren/listr.svg?branch=master)](https://travis-ci.org/SamVerschueren/listr) [![Build status Windows](https://ci.appveyor.com/api/projects/status/y8vhpwsb98b8o4cm?svg=true)](https://ci.appveyor.com/project/SamVerschueren/listr) [![Coverage Status](https://codecov.io/gh/SamVerschueren/listr/branch/master/graph/badge.svg)](https://codecov.io/gh/SamVerschueren/listr)

> Terminal task list

<img src="media/screenshot.gif">

## Install

```
$ npm install --save listr
```


## Usage

```js
const execa = require('execa');
const Listr = require('listr');

const tasks = new Listr([
	{
		title: 'Git',
		task: () => {
			return new Listr([
				{
					title: 'Checking git status',
					task: () => execa.stdout('git', ['status', '--porcelain']).then(result => {
						if (result !== '') {
							throw new Error('Unclean working tree. Commit or stash changes first.');
						}
					})
				},
				{
					title: 'Checking remote history',
					task: () => execa.stdout('git', ['rev-list', '--count', '--left-only', '@{u}...HEAD']).then(result => {
						if (result !== '0') {
							throw new Error('Remote history differ. Please pull changes.');
						}
					})
				}
			], {concurrent: true});
		}
	},
	{
		title: 'Install package dependencies with Yarn',
		task: (ctx, task) => execa('yarn')
			.catch(() => {
				ctx.yarn = false;

				task.skip('Yarn not available, install it via `npm install -g yarn`');
			})
	},
	{
		title: 'Install package dependencies with npm',
		enabled: ctx => ctx.yarn === false,
		task: () => execa('npm', ['install'])
	},
	{
		title: 'Run tests',
		task: () => execa('npm', ['test'])
	},
	{
		title: 'Publish package',
		task: () => execa('npm', ['publish'])
	}
]);

tasks.run().catch(err => {
	console.error(err);
});
```


## Task

A `task` can return different values. If a `task` returns, it means the task was completed successfully. If a task throws an error, the task failed.

```js
const tasks = new Listr([
	{
		title: 'Success',
		task: () => 'Foo'
	},
	{
		title: 'Failure',
		task: () => {
			throw new Error('Bar')
		}
	}
]);
```


### Promises

A `task` can also be async by returning a `Promise`. If the promise resolves, the task completed successfully, if it rejects, the task failed.

```js
const tasks = new Listr([
	{
		title: 'Success',
		task: () => Promise.resolve('Foo')
	},
	{
		title: 'Failure',
		task: () => Promise.reject(new Error('Bar'))
	}
]);
```

> Tip: Always reject a promise with some kind of `Error` object.

### Observable

<img src="media/observable.gif" width="250" align="right">

A `task` can also return an `Observable`. The thing about observables is that it can emit multiple values and can be used to show the output of the
task. Please note that only the last line of the output is rendered.

```js
const {Observable} = require('rxjs');

const tasks = new Listr([
	{
		title: 'Success',
		task: () => {
			return new Observable(observer => {
				observer.next('Foo');

				setTimeout(() => {
					observer.next('Bar');
				}, 2000);

				setTimeout(() => {
					observer.complete();
				}, 4000);
			});
		}
	},
	{
		title: 'Failure',
		task: () => Promise.reject(new Error('Bar'))
	}
]);
```

You can use the `Observable` package you feel most comfortable with, like [RxJS](https://www.npmjs.com/package/rxjs) or [zen-observable](https://www.npmjs.com/package/zen-observable).

### Streams

It's also possible to return a [`ReadableStream`](https://nodejs.org/api/stream.html#stream_class_stream_readable). The stream will be converted to an `Observable` and handled as such.

```js
const fs = require('fs');
const split = require('split');

const list = new Listr([
	{
		title: 'File',
		task: () => fs.createReadStream('data.txt', 'utf8')
			.pipe(split(/\r?\n/, null, {trailing: false}))
	}
]);
```

### Skipping tasks

<img src="media/skipped.png" width="250" align="right">

Optionally specify a `skip` function to determine whether a task can be skipped.

- If the `skip` function returns a truthy value or a `Promise` that resolves to a truthy value then the task will be skipped.
- If the returned value is a string it will be displayed as the reason for skipping the task.
- If the `skip` function returns a falsey value or a `Promise` that resolves to a falsey value then the task will be executed as normal.
- If the `skip` function throws or returns a `Promise` that rejects, the task (and the whole build) will fail.

```js
const tasks = new Listr([
	{
		title: 'Task 1',
		task: () => Promise.resolve('Foo')
	},
	{
		title: 'Can be skipped',
		skip: () => {
			if (Math.random() > 0.5) {
				return 'Reason for skipping';
			}
		},
		task: () => 'Bar'
	},
	{
		title: 'Task 3',
		task: () => Promise.resolve('Bar')
	}
]);
```

> Tip: You can still skip a task while already executing the `task` function with the [task object](#task-object).

## Enabling tasks

By default, every task is enabled which means that every task will be executed. However, it's also possible to provide an `enabled` function that returns whether the task should be executed or not.

```js
const tasks = new Listr([
	{
		title: 'Install package dependencies with Yarn',
		task: (ctx, task) => execa('yarn')
			.catch(() => {
				ctx.yarn = false;

				task.skip('Yarn not available, install it via `npm install -g yarn`');
			})
	},
	{
		title: 'Install package dependencies with npm',
		enabled: ctx => ctx.yarn === false,
		task: () => execa('npm', ['install'])
	}
]);
```

In the above example, we try to run `yarn` first, if that fails we will fall back to `npm`. However, at first only the Yarn task will be visible. Because we set the `yarn` flag of the [context](https://github.com/SamVerschueren/listr#context) object to `false`, the second task will automatically be enabled and will be executed.

> Note: This does not work in combination with [concurrent](https://github.com/SamVerschueren/listr#concurrent) tasks.


## Context

A context object is passed as argument to every `skip` and `task` function. This allows you to create composable tasks and change the behaviour of your task depending on previous results.

```js
const tasks = new Listr([
	{
		title: 'Task 1',
		skip: ctx => ctx.foo === 'bar',
		task: () => Promise.resolve('Foo')
	},
	{
		title: 'Can be skipped',
		skip: () => {
			if (Math.random() > 0.5) {
				return 'Reason for skipping';
			}
		},
		task: ctx => {
			ctx.unicorn = 'rainbow';
		}
	},
	{
		title: 'Task 3',
		task: ctx => Promise.resolve(`${ctx.foo} ${ctx.bar}`)
	}
]);

tasks.run({
	foo: 'bar'
}).then(ctx => {
	console.log(ctx);
	//=> {foo: 'bar', unicorn: 'rainbow'}
});
```


## Task object

A special task object is passed as second argument to the `task` function. This task object lets you change the title while running your task, you can skip it depending on some results or you can update the task's output.

```js
const tasks = new Listr([
	{
		title: 'Install package dependencies with Yarn',
		task: (ctx, task) => execa('yarn')
			.catch(() => {
				ctx.yarn = false;

				task.title = `${task.title} (or not)`;
				task.skip('Yarn not available');
			})
	},
	{
		title: 'Install package dependencies with npm',
		skip: ctx => ctx.yarn !== false && 'Dependencies already installed with Yarn',
		task: (ctx, task) => {
			task.output = 'Installing dependencies...';

			return execa('npm', ['install'])
		}
	}
]);

tasks.run();
```


## Custom renderers

It's possible to write custom renderers for Listr. A renderer is an ES6 class that accepts the tasks that it should render, and the Listr options object. It has two methods, the `render` method which is called when it should start rendering, and the `end` method. The `end` method is called when all the tasks are completed or if a task failed. If a task failed, the error object is passed in via an argument.

```js
class CustomRenderer {

	constructor(tasks, options) { }

	static get nonTTY() {
		return false;
	}

	render() { }

	end(err) { }
}

module.exports = CustomRenderer;
```

> Note: A renderer is not passed through to the subtasks, only to the main task. It is up to you to handle that case.

The `nonTTY` property returns a boolean indicating if the renderer supports non-TTY environments. The default for this property is `false` if you do not implement it.

### Observables

Every task is an observable. The task emits three different events and every event is an object with a `type` property.

1. The state of the task has changed (`STATE`).
2. The task outputted data (`DATA`).
3. The task returns a subtask list (`SUBTASKS`).
4. The task's title changed (`TITLE`).
5. The task became enabled or disabled (`ENABLED`).

This allows you to flexibly build your UI. Let's render every task that starts executing.

```js
class CustomRenderer {

	constructor(tasks, options) {
		this._tasks = tasks;
		this._options = Object.assign({}, options);
	}

	static get nonTTY() {
		return true;
	}

	render() {
		for (const task of this._tasks) {
			task.subscribe(event => {
				if (event.type === 'STATE' && task.isPending()) {
					console.log(`${task.title} [started]`);
				}
			});
		}
	}

	end(err) { }
}

module.exports = CustomRenderer;
```

If you want more complex examples, take a look at the [update](https://github.com/SamVerschueren/listr-update-renderer) and [verbose](https://github.com/SamVerschueren/listr-verbose-renderer) renderers.


## API

### Listr([tasks], [options])

#### tasks

Type: `object[]`

List of tasks.

##### title

Type: `string`

Title of the task.

##### task

Type: `Function`

Task function.

##### skip

Type: `Function`

Skip function. Read more about [skipping tasks](#skipping-tasks).

#### options

Any renderer specific options. For instance, when using the `update-renderer`, you can pass in all of its [options](https://github.com/SamVerschueren/listr-update-renderer#options).

##### concurrent

Type: `boolean` `number`<br>
Default: `false`

Set to `true` if you want to run tasks in parallel, set to a number to control the concurrency. By default it runs tasks sequentially.

##### exitOnError

Type: `boolean`<br>
Default: `true`

Set to `false` if you don't want to stop the execution of other tasks when one or more tasks fail.

##### renderer

Type: `string` `object`<br>
Default: `default`<br>
Options: `default` `verbose` `silent`

Renderer that should be used. You can either pass in the name of the known renderer, or a class of a custom renderer.

##### nonTTYRenderer

Type: `string` `object`<br>
Default: `verbose`

The renderer that should be used if the main renderer does not support TTY environments. You can either pass in the name of the renderer, or a class of a custom renderer.

### Instance

#### add(task)

Returns the instance.

##### task

Type: `object` `object[]`

Task object or multiple task objects.

#### run([context])

Start executing the tasks. Returns a `Promise` for the context object.

##### context

Type: `object`<br>
Default: `Object.create(null)`

Initial context object.


## Related

- [ora](https://github.com/sindresorhus/ora) - Elegant terminal spinner
- [cli-spinners](https://github.com/sindresorhus/cli-spinners) - Spinners for use in the terminal


## License

MIT © [Sam Verschueren](https://github.com/SamVerschueren)
