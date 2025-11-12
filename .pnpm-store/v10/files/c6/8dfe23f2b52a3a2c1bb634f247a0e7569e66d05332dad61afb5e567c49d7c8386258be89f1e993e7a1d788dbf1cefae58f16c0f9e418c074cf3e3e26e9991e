import { W as WorkerGlobalState, C as ContextRPC, B as BirpcOptions, R as RuntimeRPC } from './chunks/worker.CIpff8Eg.js';
import { Awaitable } from '@vitest/utils';
import * as v8 from 'v8';
import { S as SerializedConfig } from './chunks/config.BRtC-JeT.js';
import { W as WorkerContext } from './chunks/worker.B1y96qmv.js';
import '@vitest/runner';
import 'vite-node';
import './chunks/environment.d8YfPkTm.js';
import '@vitest/snapshot';
import '@vitest/pretty-format';
import '@vitest/snapshot/environment';
import '@vitest/utils/diff';
import 'node:worker_threads';

declare function provideWorkerState(context: any, state: WorkerGlobalState): WorkerGlobalState;

declare function run(ctx: ContextRPC): Promise<void>;
declare function collect(ctx: ContextRPC): Promise<void>;

declare function runBaseTests(method: 'run' | 'collect', state: WorkerGlobalState): Promise<void>;

type WorkerRpcOptions = Pick<BirpcOptions<RuntimeRPC>, 'on' | 'post' | 'serialize' | 'deserialize'>;
interface VitestWorker {
    getRpcOptions: (ctx: ContextRPC) => WorkerRpcOptions;
    runTests: (state: WorkerGlobalState) => Awaitable<unknown>;
    collectTests: (state: WorkerGlobalState) => Awaitable<unknown>;
}

declare function createThreadsRpcOptions({ port, }: WorkerContext): WorkerRpcOptions;
declare function createForksRpcOptions(nodeV8: typeof v8): WorkerRpcOptions;
/**
 * Reverts the wrapping done by `utils/config-helpers.ts`'s `wrapSerializableConfig`
 */
declare function unwrapSerializableConfig(config: SerializedConfig): SerializedConfig;

declare function runVmTests(method: 'run' | 'collect', state: WorkerGlobalState): Promise<void>;

export { type VitestWorker, type WorkerRpcOptions, collect as collectVitestWorkerTests, createForksRpcOptions, createThreadsRpcOptions, provideWorkerState, runBaseTests, run as runVitestWorker, runVmTests, unwrapSerializableConfig };
