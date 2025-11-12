import { MessagePort, Worker } from 'worker_threads';
import { EventEmitter } from 'events';
import { AsyncResource } from 'async_hooks';

declare const kEventEmitter: unique symbol;
declare const kAsyncResource: unique symbol;
declare type EventEmitterOptions = typeof EventEmitter extends {
    new (options?: infer T): EventEmitter;
} ? T : never;
declare type AsyncResourceOptions = typeof AsyncResource extends {
    new (name: string, options?: infer T): AsyncResource;
} ? T : never;
declare type Options$1 = EventEmitterOptions & AsyncResourceOptions & {
    name?: string;
};
declare class EventEmitterReferencingAsyncResource extends AsyncResource {
    [kEventEmitter]: EventEmitter;
    constructor(ee: EventEmitter, type: string, options?: AsyncResourceOptions);
    get eventEmitter(): EventEmitter;
}
declare class EventEmitterAsyncResource extends EventEmitter {
    [kAsyncResource]: EventEmitterReferencingAsyncResource;
    constructor(options?: Options$1 | string);
    emit(event: string | symbol, ...args: any[]): boolean;
    emitDestroy(): void;
    asyncId(): number;
    triggerAsyncId(): number;
    get asyncResource(): EventEmitterReferencingAsyncResource;
    static get EventEmitterAsyncResource(): typeof EventEmitterAsyncResource;
}

interface StartupMessage {
    tinypoolStartupMessage: true;
    filename: string | null;
    name: string;
    port: MessagePort;
    sharedBuffer: Int32Array;
    useAtomics: boolean;
}
interface RequestMessage {
    taskId: number;
    task: any;
    filename: string;
    name: string;
}
interface ReadyMessage {
    ready: true;
}
interface ResponseMessage {
    taskId: number;
    result: any;
    error: unknown | null;
}
interface TinypoolPrivateData {
    workerId: number;
}
declare type TinypoolData = [TinypoolPrivateData, any];
declare const kTransferable: unique symbol;
declare const kValue: unique symbol;
declare const kQueueOptions: unique symbol;
declare function isTransferable(value: any): boolean;
declare function isMovable(value: any): boolean;
declare function markMovable(value: object): void;
interface Transferable {
    readonly [kTransferable]: object;
    readonly [kValue]: object;
}
interface Task {
    readonly [kQueueOptions]: object | null;
}
interface TaskQueue {
    readonly size: number;
    shift(): Task | null;
    remove(task: Task): void;
    push(task: Task): void;
}
declare function isTaskQueue(value: any): boolean;
declare const kRequestCountField = 0;
declare const kResponseCountField = 1;
declare const kFieldCount = 2;

declare global {
    namespace NodeJS {
        interface Process {
            __tinypool_state__: {
                isWorkerThread: boolean;
                workerData: any;
                workerId: number;
            };
        }
    }
}
interface AbortSignalEventTargetAddOptions {
    once: boolean;
}
interface AbortSignalEventTarget {
    addEventListener: (name: 'abort', listener: () => void, options?: AbortSignalEventTargetAddOptions) => void;
    removeEventListener: (name: 'abort', listener: () => void) => void;
    aborted?: boolean;
}
interface AbortSignalEventEmitter {
    off: (name: 'abort', listener: () => void) => void;
    once: (name: 'abort', listener: () => void) => void;
}
declare type AbortSignalAny = AbortSignalEventTarget | AbortSignalEventEmitter;
declare type ResourceLimits = Worker extends {
    resourceLimits?: infer T;
} ? T : {};
declare type EnvSpecifier = typeof Worker extends {
    new (filename: never, options?: {
        env: infer T;
    }): Worker;
} ? T : never;
interface Options {
    filename?: string | null;
    name?: string;
    minThreads?: number;
    maxThreads?: number;
    idleTimeout?: number;
    maxQueue?: number | 'auto';
    concurrentTasksPerWorker?: number;
    useAtomics?: boolean;
    resourceLimits?: ResourceLimits;
    argv?: string[];
    execArgv?: string[];
    env?: EnvSpecifier;
    workerData?: any;
    taskQueue?: TaskQueue;
    trackUnmanagedFds?: boolean;
    isolateWorkers?: boolean;
}
interface FilledOptions extends Options {
    filename: string | null;
    name: string;
    minThreads: number;
    maxThreads: number;
    idleTimeout: number;
    maxQueue: number;
    concurrentTasksPerWorker: number;
    useAtomics: boolean;
    taskQueue: TaskQueue;
}
interface RunOptions {
    transferList?: TransferList;
    filename?: string | null;
    signal?: AbortSignalAny | null;
    name?: string | null;
}
declare type TransferList = MessagePort extends {
    postMessage(value: any, transferList: infer T): any;
} ? T : never;
declare type TransferListItem = TransferList extends (infer T)[] ? T : never;
declare class Tinypool extends EventEmitterAsyncResource {
    #private;
    constructor(options?: Options);
    run(task: any, options?: RunOptions): Promise<any>;
    broadcastMessage(message: any): void;
    destroy(): Promise<void>;
    get options(): FilledOptions;
    get threads(): Worker[];
    get queueSize(): number;
    get completed(): number;
    get duration(): number;
    static get isWorkerThread(): boolean;
    static get workerData(): any;
    static get version(): string;
    static move(val: Transferable | TransferListItem | ArrayBufferView | ArrayBuffer | MessagePort): MessagePort | ArrayBuffer | Transferable | ArrayBufferView;
    static get transferableSymbol(): symbol;
    static get valueSymbol(): symbol;
    static get queueOptionsSymbol(): symbol;
}
declare function onBroadcastedMessage(handler: (message: any) => void): void;
declare const _workerId: number;

export { Options, ReadyMessage, RequestMessage, ResponseMessage, StartupMessage, Task, TaskQueue, Tinypool, TinypoolData, TinypoolPrivateData, Transferable, Tinypool as default, isMovable, isTaskQueue, isTransferable, kFieldCount, kQueueOptions, kRequestCountField, kResponseCountField, kTransferable, kValue, markMovable, onBroadcastedMessage, _workerId as workerId };
