# Tinypool - the node.js worker pool 🧵

> Piscina: A fast, efficient Node.js Worker Thread Pool implementation

Tinypool is a fork of piscina. What we try to achieve in this library, is to eliminate some dependencies and features that our target users don't need (currently, our main user will be Vitest). Tinypool's install size (38KB) can then be smaller than Piscina's install size (6MB). If you need features like [utilization](https://github.com/piscinajs/piscina#property-utilization-readonly) or [NAPI](https://github.com/piscinajs/piscina#thread-priority-on-linux-systems), [Piscina](https://github.com/piscinajs/piscina) is a better choice for you. We think that Piscina is an amazing library, and we may try to upstream some of the dependencies optimization in this fork.

- ✅ Smaller install size, 38KB
- ✅ Minimal
- ✅ No dependencies
- ✅ Physical cores instead of Logical cores with [physical-cpu-count](https://www.npmjs.com/package/physical-cpu-count)
- ✅ Supports `worker_threads` and `child_process`
- ❌ No utilization
- ❌ No NAPI

- Written in TypeScript, and ESM support only. For Node.js 18.x and higher.

_In case you need more tiny libraries like tinypool or tinyspy, please consider submitting an [RFC](https://github.com/tinylibs/rfcs)_

## Example

### Using `node:worker_threads`

#### Basic usage

```js
// main.mjs
import Tinypool from 'tinypool'

const pool = new Tinypool({
  filename: new URL('./worker.mjs', import.meta.url).href,
})
const result = await pool.run({ a: 4, b: 6 })
console.log(result) // Prints 10

// Make sure to destroy pool once it's not needed anymore
// This terminates all pool's idle workers
await pool.destroy()
```

```js
// worker.mjs
export default ({ a, b }) => {
  return a + b
}
```

#### Main thread <-> worker thread communication

<details>
  <summary>See code</summary>

```js
// main.mjs
import Tinypool from 'tinypool'
import { MessageChannel } from 'node:worker_threads'

const pool = new Tinypool({
  filename: new URL('./worker.mjs', import.meta.url).href,
})
const { port1, port2 } = new MessageChannel()
const promise = pool.run({ port: port1 }, { transferList: [port1] })

port2.on('message', (message) => console.log('Main thread received:', message))
setTimeout(() => port2.postMessage('Hello from main thread!'), 1000)

await promise

port1.close()
port2.close()
```

```js
// worker.mjs
export default ({ port }) => {
  return new Promise((resolve) => {
    port.on('message', (message) => {
      console.log('Worker received:', message)

      port.postMessage('Hello from worker thread!')
      resolve()
    })
  })
}
```

</details>

### Using `node:child_process`

#### Basic usage

<details>
  <summary>See code</summary>

```js
// main.mjs
import Tinypool from 'tinypool'

const pool = new Tinypool({
  runtime: 'child_process',
  filename: new URL('./worker.mjs', import.meta.url).href,
})
const result = await pool.run({ a: 4, b: 6 })
console.log(result) // Prints 10
```

```js
// worker.mjs
export default ({ a, b }) => {
  return a + b
}
```

</details>

#### Main process <-> worker process communication

<details>
  <summary>See code</summary>

```js
// main.mjs
import Tinypool from 'tinypool'

const pool = new Tinypool({
  runtime: 'child_process',
  filename: new URL('./worker.mjs', import.meta.url).href,
})

const messages = []
const listeners = []
const channel = {
  onMessage: (listener) => listeners.push(listener),
  postMessage: (message) => messages.push(message),
}

const promise = pool.run({}, { channel })

// Send message to worker
setTimeout(
  () => listeners.forEach((listener) => listener('Hello from main process')),
  1000
)

// Wait for task to finish
await promise

console.log(messages)
// [{ received: 'Hello from main process', response: 'Hello from worker' }]
```

```js
// worker.mjs
export default async function run() {
  return new Promise((resolve) => {
    process.on('message', (message) => {
      // Ignore Tinypool's internal messages
      if (message?.__tinypool_worker_message__) return

      process.send({ received: message, response: 'Hello from worker' })
      resolve()
    })
  })
}
```

</details>

## API

We have a similar API to Piscina, so for more information, you can read Piscina's detailed [documentation](https://github.com/piscinajs/piscina#piscina---the-nodejs-worker-pool) and apply the same techniques here.

### Tinypool specific APIs

#### Pool constructor options

- `isolateWorkers`: Disabled by default. Always starts with a fresh worker when running tasks to isolate the environment.
- `terminateTimeout`: Disabled by default. If terminating a worker takes `terminateTimeout` amount of milliseconds to execute, an error is raised.
- `maxMemoryLimitBeforeRecycle`: Disabled by default. When defined, the worker's heap memory usage is compared against this value after task has been finished. If the current memory usage exceeds this limit, worker is terminated and a new one is started to take its place. This option is useful when your tasks leak memory and you don't want to enable `isolateWorkers` option.
- `runtime`: Used to pick worker runtime. Default value is `worker_threads`.
  - `worker_threads`: Runs workers in [`node:worker_threads`](https://nodejs.org/api/worker_threads.html). For `main thread <-> worker thread` communication you can use [`MessagePort`](https://nodejs.org/api/worker_threads.html#class-messageport) in the `pool.run()` method's [`transferList` option](https://nodejs.org/api/worker_threads.html#portpostmessagevalue-transferlist). See [example](#main-thread---worker-thread-communication).
  - `child_process`: Runs workers in [`node:child_process`](https://nodejs.org/api/child_process.html). For `main thread <-> worker process` communication you can use `TinypoolChannel` in the `pool.run()` method's `channel` option. For filtering out the Tinypool's internal messages see `TinypoolWorkerMessage`. See [example](#main-process---worker-process-communication).

#### Pool methods

- `cancelPendingTasks()`: Gracefully cancels all pending tasks without stopping or interfering with on-going tasks. This method is useful when your tasks may have side effects and should not be terminated forcefully during task execution. If your tasks don't have any side effects you may want to use [`{ signal }`](https://github.com/piscinajs/piscina#cancelable-tasks) option for forcefully terminating all tasks, including the on-going ones, instead.
- `recycleWorkers(options)`: Waits for all current tasks to finish and re-creates all workers. Can be used to force isolation imperatively even when `isolateWorkers` is disabled. Accepts `{ runtime }` option as argument.

#### Exports

- `workerId`: Each worker now has an id ( <= `maxThreads`) that can be imported from `tinypool` in the worker itself (or `process.__tinypool_state__.workerId`).

## Authors

| <a href="https://github.com/Aslemammad"> <img width='150' src="https://avatars.githubusercontent.com/u/37929992?v=4" /><br> Mohammad Bagher </a> |
| ------------------------------------------------------------------------------------------------------------------------------------------------ |

## Sponsors

Your sponsorship can make a huge difference in continuing our work in open source!

<p align="center">
  <a href="https://cdn.jsdelivr.net/gh/aslemammad/static/sponsors.svg">
    <img src='https://cdn.jsdelivr.net/gh/aslemammad/static/sponsors.svg'/>
  </a>
</p>

## Credits

[The Vitest team](https://vitest.dev/) for giving me the chance of creating and maintaing this project for vitest.

[Piscina](https://github.com/piscinajs/piscina), because Tinypool is not more than a friendly fork of piscina.
