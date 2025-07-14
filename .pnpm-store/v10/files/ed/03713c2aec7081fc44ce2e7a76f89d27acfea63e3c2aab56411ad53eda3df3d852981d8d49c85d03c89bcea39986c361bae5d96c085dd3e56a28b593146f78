import Enquirer from 'enquirer';
import { Observable } from 'rxjs';
import { Writable, Readable } from 'stream';
import { WriteStream } from 'fs';
import * as colorette from 'colorette';

/**
 * Give event map a set of indexes to not make it go crazy when some events are missing from it.
 * They are optional after all.
 */
declare class BaseEventMap {
    [k: string]: any;
}
/**
 * Parameters for the given event in the {@link EventMap}.
 */
type EventData<Event extends string, Map extends Record<string, unknown>> = Event extends keyof Map ? Map[Event] : never;
/**
 * An event map of given events that defined the parameters and return types for firing a certain event.
 */
type EventMap<Events extends string> = Partial<Record<Events, unknown>>;

declare class EventManager<Event extends string = string, Map extends Partial<Record<Event, unknown>> = Partial<Record<Event, any>>> {
    private readonly emitter;
    emit<E extends Event = Event>(dispatch: E, args?: EventData<E, Map>): void;
    on<E extends Event = Event>(dispatch: E, handler: (data: EventData<E, Map>) => void): void;
    once<E extends Event = Event>(dispatch: E, handler: (data: EventData<E, Map>) => void): void;
    off<E extends Event = Event>(dispatch: E, handler?: (data: EventData<E, Map>) => void): void;
    complete(): void;
}

/**
 * Indicates an UNICODE characters is coming up.
 */
declare const ANSI_ESCAPE = "\u001B[";
/**
 * Generic ANSI escape characters for terminal based operations.
 */
declare const ANSI_ESCAPE_CODES: {
    CURSOR_HIDE: string;
    CURSOR_SHOW: string;
};

/**
 * Environment variables for Listr.
 */
declare enum ListrEnvironmentVariables {
    DISABLE_COLOR = "LISTR_DISABLE_COLOR",
    FORCE_UNICODE = "LISTR_FORCE_UNICODE",
    FORCE_COLOR = "FORCE_COLOR"
}

/**
 * The actual error type that is collected and to help identify where the error is triggered from.
 */
declare enum ListrErrorTypes {
    /** Task has failed and will try to retry. */
    WILL_RETRY = "WILL_RETRY",
    /** Task has failed and will try to rollback. */
    WILL_ROLLBACK = "WILL_ROLLBACK",
    /** Task has failed, ran the rollback action but the rollback action itself has failed. */
    HAS_FAILED_TO_ROLLBACK = "HAS_FAILED_TO_ROLLBACK",
    /** Task has failed. */
    HAS_FAILED = "HAS_FAILED",
    /** Task has failed, but exitOnError is set to false, so will ignore this error. */
    HAS_FAILED_WITHOUT_ERROR = "HAS_FAILED_WITHOUT_ERROR"
}

/**
 * Events that are triggered by Listr.
 *
 * These are stateful and singleton events by being attached to the main Listr class and propagating to the subtasks.
 *
 * @see {@link https://listr2.kilic.dev/listr/events.html}
 */
declare enum ListrEventType {
    /** Indicates that underlying renderer should refresh the current render. */
    SHOULD_REFRESH_RENDER = "SHOUD_REFRESH_RENDER"
}

/**
 * Internal events that are fired from the Task.
 *
 * @see {@link https://listr2.kilic.dev/task/events.html}
 */
declare enum ListrTaskEventType {
    /** Title has changed for the current Task. */
    TITLE = "TITLE",
    /**
     * State has changed for the current Task.
     *
     * @see {@link module:listr2.ListrTaskState}
     */
    STATE = "STATE",
    /** The current Task has been marked as enabled. */
    ENABLED = "ENABLED",
    /** The current Task is currently processing subtasks. */
    SUBTASK = "SUBTASK",
    /** The current Task is now processing a prompt. */
    PROMPT = "PROMPT",
    /** The current Task is now dumping output. */
    OUTPUT = "OUTPUT",
    /**
     * The current Task is now dumping a message.
     *
     * @see {module:Listr2.ListrTaskMessage}
     */
    MESSAGE = "MESSAGE",
    /** The current Task is closed and no further action in expected. */
    CLOSED = "CLOSED"
}

/**
 * Tasks can be in various states during the execution.
 *
 * Whenever a state change occurs, the task will emit a {@link module:listr2.ListrTaskEventType.STATE} with the appropriate state.
 */
declare enum ListrTaskState {
    /** Task has not started yet, waiting for pick-up. */
    WAITING = "WAITING",
    /** Task has started. */
    STARTED = "STARTED",
    /** Task has been completed. */
    COMPLETED = "COMPLETED",
    /** Task has failed. */
    FAILED = "FAILED",
    /** Task has been skipped. */
    SKIPPED = "SKIPPED",
    /** Task is currently trying to rollback. */
    ROLLING_BACK = "ROLLING_BACK",
    /** Task has rolledback successfully after failing. */
    ROLLED_BACK = "ROLLED_BACK",
    /** Task is currently retrying. */
    RETRY = "RETRY",
    /** Task is currently paused. */
    PAUSED = "PAUSED",
    /** Task is currently trying to process a prompt. */
    PROMPT = "PROMPT",
    /** Task has successfully processed the prompt. */
    PROMPT_COMPLETED = "PROMPT_COMPLETED"
}

/**
 * Tests to see if the object is an RxJS {@link Observable}
 * @param obj the object to test
 */
declare function isObservable<T>(obj: any): obj is {
    subscribe: T;
    next: any;
    error: any;
    complete: any;
};

declare function isUnicodeSupported(): boolean;

declare function cleanseAnsi(chunk: string): string;

declare const color: colorette.Colorette;

declare function indent(string: string, count: number): string;

declare const FIGURES_MAIN: {
    warning: string;
    cross: string;
    arrowDown: string;
    tick: string;
    arrowRight: string;
    pointer: string;
    checkboxOn: string;
    arrowLeft: string;
    squareSmallFilled: string;
    pointerSmall: string;
};
type Figures = typeof FIGURES_MAIN;
declare const figures: Figures;

declare function splat(message: string, ...splat: any[]): string;

/**
 * Creates a new Listr2 logger.
 *
 * This logger is used throughout the renderers for consistency.
 *
 * @see {@link https://listr2.kilic.dev/renderer/logger.html}
 */
declare class ListrLogger<Levels extends string = string> {
    options?: ListrLoggerOptions<Levels>;
    readonly process: ProcessOutput;
    constructor(options?: ListrLoggerOptions<Levels>);
    log(level: Levels, message: string | any[], options?: LoggerFieldOptions): void;
    toStdout(message: string | any[], options?: LoggerFieldOptions, eol?: boolean): void;
    toStderr(message: string | any[], options?: LoggerFieldOptions, eol?: boolean): void;
    wrap(message: string, options?: LoggerFormatOptions): string;
    splat(...args: Parameters<typeof splat>): ReturnType<typeof splat>;
    suffix(message: string, ...suffixes: LoggerField[]): string;
    prefix(message: string, ...prefixes: LoggerField[]): string;
    fields(message: string, options?: LoggerFieldOptions<true>): string;
    icon(level: Levels, icon?: string | false): string;
    protected format(level: Levels, message: string | any[], options?: LoggerFieldOptions): string;
    protected style(level: Levels, message: string): string;
    protected applyFormat(message: string, options?: LoggerFormatOptions): string;
    protected spacing(message: string | undefined): string;
}

/**
 * Options for the logger
 */
interface ListrLoggerOptions<Levels extends string> extends ProcessOutputRendererOptions, ListrLoggerStyleMap<Levels | string> {
    /**
     * Use icons for the log levels.
     */
    useIcons?: boolean;
    /**
     * Apply fields and templates as presets before and after each message.
     */
    fields?: LoggerFieldOptions<true>;
    /**
     * Send the designated levels to `process.stderr`.
     */
    toStderr?: (Levels | string)[];
}
/**
 * Inject your custom style map consisting of icons and coloring for the ListrLogger.
 *
 * @see {@link https://listr2.kilic.dev/renderer/logger.html}
 */
interface ListrLoggerStyleMap<Levels extends string> {
    /**
     * Coloring of the levels.
     *
     * @see {@link https://listr2.kilic.dev/renderer/logger.html#style}
     */
    color?: Partial<Record<Levels, LoggerFormat>>;
    /**
     * Icons of the levels.
     *
     * @see {@link https://listr2.kilic.dev/renderer/logger.html#style}
     */
    icon?: Partial<Record<Levels, string>>;
}
interface LoggerFieldOptions<MultipleOnly extends boolean = false> {
    /**
     * Prefix fields for the log entry.
     */
    prefix?: MultipleOnly extends false ? LoggerField | LoggerField[] : LoggerField[];
    /**
     * Suffix fields for the log entry.
     */
    suffix?: MultipleOnly extends false ? LoggerField | LoggerField[] : LoggerField[];
}
type LoggerFormat = (message?: string) => string;
interface LoggerFieldFn<Args extends any[] = any[]> {
    /**
     * The value of the given field.
     */
    field: ((...args: Args) => string) | string;
    /**
     * Condition to display the given field.
     */
    condition?: ((...args: Args) => boolean) | boolean;
    /**
     * Formatting/coloring of the field.
     */
    format?: (...args: Args) => LoggerFormat;
    /**
     * Args to pass to other functions whenever this field is triggered.
     */
    args?: Args;
}
type LoggerField<Args extends any[] = any[]> = LoggerFieldFn<Args> | string;
interface RendererLoggerOptions<Levels extends string> {
    /**
     * Inject your custom implementation of the ListrLogger.
     *
     * @see {@link https://listr2.kilic.dev/renderer/logger.html}
     */
    logger?: ListrLogger<Levels>;
}
interface LoggerFormatOptions {
    format?: LoggerFormat;
}

/** Default ListrLogLevels for the logger */
declare enum ListrLogLevels {
    STARTED = "STARTED",
    COMPLETED = "COMPLETED",
    FAILED = "FAILED",
    SKIPPED = "SKIPPED",
    OUTPUT = "OUTPUT",
    TITLE = "TITLE",
    ROLLBACK = "ROLLBACK",
    RETRY = "RETRY",
    PROMPT = "PROMPT",
    PAUSED = "PAUSED"
}
declare const LISTR_LOGGER_STYLE: ListrLoggerStyleMap<ListrLogLevels>;
declare const LISTR_LOGGER_STDERR_LEVELS: ListrLogLevels[];

interface ProcessOutputBufferEntry {
    time: number;
    entry: string;
    stream?: NodeJS.WriteStream;
}
interface ProcessOutputBufferOptions {
    limit?: number;
    stream?: NodeJS.WriteStream;
}

declare class ProcessOutputBuffer {
    private readonly options?;
    private buffer;
    private readonly decoder;
    constructor(options?: ProcessOutputBufferOptions);
    get all(): ProcessOutputBufferEntry[];
    get last(): ProcessOutputBufferEntry;
    get length(): number;
    write(data: Uint8Array | string, ...args: [(string | undefined)?, ((err?: Error) => void)?] | [((err?: Error) => void)?]): ReturnType<NodeJS.WriteStream['write']>;
    reset(): void;
}

declare class ProcessOutputStream {
    private stream;
    private readonly method;
    private readonly buffer;
    constructor(stream: NodeJS.WriteStream);
    get out(): NodeJS.WriteStream;
    hijack(): void;
    release(): ProcessOutputBufferEntry[];
    write(...args: Parameters<NodeJS.WriteStream['write']>): ReturnType<NodeJS.WriteStream['write']>;
}

interface ProcessOutputRendererOptions {
    /**
     * Pass your implementation of process output class to write to stdout and stderr.
     *
     * @default 'ProcessOutput'
     * @global global option that can not be temperated with subtasks
     */
    processOutput?: ProcessOutput;
}
/**
 * Customize the behavior of the ProcessOutput.
 */
interface ProcessOutputOptions {
    /**
     * After the `ProcessOutput.release()` which streams should be dumped.
     *
     * @defaultValue `[ 'stdout', 'stderr' ]`
     */
    dump?: (keyof ProcessOutputStreamMap)[];
    /**
     * After the `ProcessOutput.release()` whether to leave empty line or not.
     *
     * @defaultValue `true`
     */
    leaveEmptyLine?: boolean;
}
type ProcessOutputStreamMap = Record<'stdout' | 'stderr', ProcessOutputStream>;

/**
 * Creates a new Listr2 process-output controller.
 *
 * This is used to control the flow to `process.stdout` and `process.stderr` for all renderers.
 *
 * @see {@link https://listr2.kilic.dev/renderer/process-output.html}
 */
declare class ProcessOutput {
    private readonly options?;
    readonly stream: ProcessOutputStreamMap;
    protected active: boolean;
    constructor(stdout?: NodeJS.WriteStream, stderr?: NodeJS.WriteStream, options?: ProcessOutputOptions);
    get stdout(): NodeJS.WriteStream;
    get stderr(): NodeJS.WriteStream;
    hijack(): void;
    release(): void;
    toStdout(buffer: string, eol?: boolean): boolean;
    toStderr(buffer: string, eol?: boolean): boolean;
}

declare function createWritable(cb: (chunk: string) => void): NodeJS.WritableStream;

declare class Spinner {
    protected readonly spinner: string[];
    private id?;
    private spinnerPosition;
    spin(): void;
    fetch(): string;
    isRunning(): boolean;
    start(cb?: () => void, interval?: number): void;
    stop(): void;
}

interface BasePromptOptions {
    message: string | (() => string) | (() => Promise<string>);
    initial?: boolean | number | number[] | string | (() => string) | (() => Promise<string>);
    required?: boolean;
    stdin?: NodeJS.ReadStream;
    stdout?: NodeJS.WriteStream;
    header?: string;
    footer?: string;
    skip?: (value: any) => boolean | Promise<boolean>;
    format?: (value: any) => any | Promise<any>;
    result?: (value: any) => any | Promise<any>;
    validate?: (value: any, state: any) => boolean | Promise<boolean> | string | Promise<string> | Promise<string | boolean>;
    onSubmit?: (name: any, value: any, prompt: Enquirer.Prompt) => boolean | Promise<boolean>;
    onCancel?: (name: any, value: any, prompt: Enquirer.Prompt) => boolean | Promise<boolean>;
}
interface BasePromptOptionsWithName extends BasePromptOptions {
    name: string | (() => string);
}
interface ArrayPromptOptions extends BasePromptOptions {
    choices: string[] | BasePromptOptionsWithName[];
    maxChoices?: number;
    multiple?: boolean;
    initial?: number | number[];
    delay?: number;
    separator?: boolean;
    sort?: boolean;
    linebreak?: boolean;
    edgeLength?: number;
    align?: 'left' | 'right';
    scroll?: boolean;
    hint?: string;
}
interface BooleanPromptOptions extends BasePromptOptions {
    initial?: boolean | (() => string) | (() => Promise<string>);
}
interface StringPromptOptions extends BasePromptOptions {
    initial?: string;
    multiline?: boolean;
}
interface ScalePromptOptions extends ArrayPromptOptions {
    scale: StringPromptOptions[];
    margin?: [number, number, number, number];
}
interface NumberPromptOptions extends BasePromptOptions {
    min?: number;
    max?: number;
    delay?: number;
    float?: boolean;
    round?: boolean;
    major?: number;
    minor?: number;
    initial?: number;
}
interface SnippetPromptOptions extends BasePromptOptions {
    newline?: string;
    fields: Partial<BasePromptOptionsWithName>[];
    template: string;
}
interface SortPromptOptions extends BasePromptOptions {
    hint?: string;
    drag?: boolean;
    numbered?: boolean;
}
interface SurveyPromptOptions extends ArrayPromptOptions {
    scale: BasePromptOptionsWithName[];
    margin: [number, number, number, number];
}
interface QuizPromptOptions extends ArrayPromptOptions {
    correctChoice: number;
}
interface TogglePromptOptions extends BasePromptOptions {
    enabled?: string;
    disabled?: string;
}
interface PromptCancelOptions {
    throw?: boolean;
}
/** Returns all the prompt options depending on the type selected. */
type PromptOptions<T extends boolean = false> = Unionize<{
    [K in PromptTypes]-?: T extends true ? {
        type: K;
    } & PromptOptionsType<K> & {
        name: string | (() => string);
    } : {
        type: K;
    } & PromptOptionsType<K>;
}> | ({
    type: string;
} & T extends true ? PromptOptionsType<string> & {
    name: string | (() => string);
} : PromptOptionsType<string>);
type Unionize<T extends Record<PropertyKey, unknown>> = {
    [P in keyof T]: T[P];
}[keyof T];
type PromptTypes = 'AutoComplete' | 'BasicAuth' | 'Confirm' | 'Editable' | 'Form' | 'Input' | 'Invisible' | 'List' | 'MultiSelect' | 'Numeral' | 'Password' | 'Quiz' | 'Scale' | 'Select' | 'Snippet' | 'Sort' | 'Survey' | 'Text' | 'Toggle';
type PromptOptionsType<T> = T extends keyof PromptOptionsMap ? PromptOptionsMap[T] : T extends string ? BasePromptOptions & Record<PropertyKey, unknown> : any;
declare class PromptOptionsMap implements Record<PromptTypes, Record<PropertyKey, any>> {
    AutoComplete: ArrayPromptOptions;
    BasicAuth: StringPromptOptions;
    Confirm: BooleanPromptOptions;
    Editable: ArrayPromptOptions;
    Form: ArrayPromptOptions;
    Input: StringPromptOptions;
    Invisible: StringPromptOptions;
    List: ArrayPromptOptions;
    MultiSelect: ArrayPromptOptions;
    Numeral: NumberPromptOptions;
    Password: StringPromptOptions;
    Quiz: QuizPromptOptions;
    Scale: ScalePromptOptions;
    Select: ArrayPromptOptions;
    Snippet: SnippetPromptOptions;
    Sort: SortPromptOptions;
    Survey: SurveyPromptOptions;
    Text: StringPromptOptions;
    Toggle: TogglePromptOptions;
}
interface PromptSettings {
    error?: boolean;
    stdout?: WriteStream | Writable;
    enquirer?: Enquirer;
}
interface PromptInstance extends Omit<BasePromptOptions, 'onCancel' | 'onSubmit'> {
    submit: () => void;
    cancel: (err?: string) => void;
}

/**
 * Create a new prompt with Enquirer externally.
 * This extends enquirer so you dont have to give a name to single prompts and such so it is also
 * useful to use externally.
 * @param this
 * @param options
 * @param settings
 */
declare function createPrompt(this: any, options: PromptOptions | PromptOptions<true>[], settings?: PromptSettings): Promise<any>;

declare function getRendererClass(renderer: ListrRendererValue): ListrRendererFactory;
declare function getRenderer<Renderer extends ListrRendererValue, FallbackRenderer extends ListrRendererValue>(options: {
    renderer: Renderer;
    rendererOptions: ListrGetRendererOptions<Renderer>;
    fallbackRenderer: FallbackRenderer;
    fallbackRendererOptions: ListrGetRendererOptions<FallbackRenderer>;
    fallbackRendererCondition?: ListrOptions['fallbackRendererCondition'];
    silentRendererCondition?: ListrOptions['silentRendererCondition'];
}): SupportedRenderer<ListrRendererFactory>;

/**
 * This function asserts the given value as a function or itself.
 * If the value itself is a function it will evaluate it with the passed in arguments,
 * elsewise it will directly return itself.
 */
declare function assertFunctionOrSelf<T>(functionOrSelf: T, ...args: T extends (...args: any[]) => any ? Parameters<T> : never): T extends (...args: any[]) => any ? ReturnType<T> : T;

/**
 * Deep clones a object in the easiest manner.
 */
declare function cloneObject<T extends Record<PropertyKey, any>>(obj: T): T;

declare class Concurrency {
    private concurrency;
    private count;
    private queue;
    constructor(options: {
        concurrency: number;
    });
    add<T>(fn: () => Promise<T>): Promise<T>;
    private flush;
    private run;
}

declare function delay(time: number): Promise<void>;

/**
 * The original Task that is defined by the user is wrapped with the TaskWrapper to provide additional functionality.
 *
 * @see {@link https://listr2.kilic.dev/task/task.html}
 */
declare class TaskWrapper<Ctx, Renderer extends ListrRendererFactory> {
    task: Task<Ctx, ListrRendererFactory>;
    private options;
    constructor(task: Task<Ctx, ListrRendererFactory>, options: ListrBaseClassOptions<Ctx, any, any>);
    get title(): string;
    /**
     * Title of the current task.
     *
     * @see {@link https://listr2.kilic.dev/task/title.html}
     */
    set title(title: string | any[]);
    get output(): string;
    /**
     * Send output from the current task to the renderer.
     *
     * @see {@link https://listr2.kilic.dev/task/output.html}
     */
    set output(output: string | any[]);
    /** Send an output to the output channel as prompt. */
    private set promptOutput(value);
    /**
     * Creates a new set of Listr subtasks.
     *
     * @see {@link https://listr2.kilic.dev/task/subtasks.html}
     */
    newListr<NewCtx = Ctx>(task: ListrTask<NewCtx, Renderer> | ListrTask<NewCtx, Renderer>[] | ((parent: Omit<this, 'skip' | 'enabled'>) => ListrTask<NewCtx, Renderer> | ListrTask<NewCtx, Renderer>[]), options?: ListrSubClassOptions<NewCtx, Renderer>): Listr<NewCtx, any, any>;
    /**
     * Report an error that has to be collected and handled.
     *
     * @see {@link https://listr2.kilic.dev/task/error-handling.html}
     */
    report(error: Error, type: ListrErrorTypes): void;
    /**
     * Skip the current task.
     *
     * @see {@link https://listr2.kilic.dev/task/skip.html}
     */
    skip(message?: string, ...metadata: any[]): void;
    /**
     * Check whether this task is currently in a retry state.
     *
     * @see {@link https://listr2.kilic.dev/task/retry.html}
     */
    isRetrying(): Task<Ctx, Renderer>['retry'];
    /**
     * Create a new prompt for getting user input through `enquirer`.
     *
     * - `enquirer` is a optional peer dependency and has to be already installed separately.
     *
     * @see {@link https://listr2.kilic.dev/task/prompt.html}
     */
    prompt<T = any>(options: PromptOptions | PromptOptions<true>[]): Promise<T>;
    /**
     * Cancel the current active prompt, if there is any.
     *
     * @see {@link https://listr2.kilic.dev/task/prompt.html}
     */
    cancelPrompt(options?: PromptCancelOptions): void;
    /**
     * Generates a fake stdout for your use case, where it will be tunnelled through Listr to handle the rendering process.
     *
     * @see {@link https://listr2.kilic.dev/renderer/process-output.html}
     */
    stdout(type?: ListrTaskEventType.OUTPUT | ListrTaskEventType.PROMPT): NodeJS.WritableStream;
    /** Run this task. */
    run(ctx: Ctx): Promise<void>;
}

declare class ListrTaskEventManager extends EventManager<ListrTaskEventType, ListrTaskEventMap> {
}

/**
 * Creates and handles a runnable instance of the Task.
 */
declare class Task<Ctx, Renderer extends ListrRendererFactory> extends ListrTaskEventManager {
    listr: Listr<Ctx, any, any>;
    task: ListrTask<Ctx, any>;
    options: ListrOptions;
    rendererOptions: ListrGetRendererOptions<Renderer>;
    /** Unique id per task, can be used for identifying a Task. */
    id: string;
    /** The current state of the task. */
    state: ListrTaskState;
    /** Subtasks of the current task. */
    subtasks: Task<Ctx, Renderer>[];
    /** Title of the task. */
    title?: string;
    /** Initial/Untouched version of the title for using whenever task has a reset. */
    readonly initialTitle?: string;
    /** Output channel for the task. */
    output?: string;
    /** Current state of the retry process whenever the task is retrying. */
    retry?: ListrTaskRetry;
    /**
     * A channel for messages.
     *
     * This requires a separate channel for messages like error, skip or runtime messages to further utilize in the renderers.
     */
    message: ListrTaskMessage;
    /** Per-task options for the current renderer of the task. */
    rendererTaskOptions: ListrGetRendererTaskOptions<Renderer>;
    /** Current prompt instance or prompt error whenever the task is prompting. */
    prompt: ListrTaskPrompt;
    /** Parent task of the current task. */
    parent?: Task<Ctx, Renderer>;
    /** Enable flag of this task. */
    private enabled;
    /** User provided Task callback function to run. */
    private taskFn;
    /** Marks the task as closed. This is different from finalized since this is not really related to task itself. */
    private closed;
    constructor(listr: Listr<Ctx, any, any>, task: ListrTask<Ctx, any>, options: ListrOptions, rendererOptions: ListrGetRendererOptions<Renderer>);
    /**
     * Update the current state of the Task and emit the neccassary events.
     */
    set state$(state: ListrTaskState);
    /**
     * Update the current output of the Task and emit the neccassary events.
     */
    set output$(data: string);
    /**
     * Update the current prompt output of the Task and emit the neccassary events.
     */
    set promptOutput$(data: string);
    /**
     * Update or extend the current message of the Task and emit the neccassary events.
     */
    set message$(data: Task<Ctx, Renderer>['message']);
    /**
     * Update the current title of the Task and emit the neccassary events.
     */
    set title$(title: string);
    /**
     * Current task path in the hierarchy.
     */
    get path(): string[];
    /**
     * Checks whether the current task with the given context should be set as enabled.
     */
    check(ctx: Ctx): Promise<boolean>;
    /** Returns whether this task has subtasks. */
    hasSubtasks(): boolean;
    /** Returns whether this task is finalized in someform. */
    hasFinalized(): boolean;
    /** Returns whether this task is in progress. */
    isPending(): boolean;
    /** Returns whether this task has started. */
    isStarted(): boolean;
    /** Returns whether this task is skipped. */
    isSkipped(): boolean;
    /** Returns whether this task has been completed. */
    isCompleted(): boolean;
    /** Returns whether this task has been failed. */
    hasFailed(): boolean;
    /** Returns whether this task has an active rollback task going on. */
    isRollingBack(): boolean;
    /** Returns whether the rollback action was successful. */
    hasRolledBack(): boolean;
    /** Returns whether this task has an actively retrying task going on. */
    isRetrying(): boolean;
    /** Returns whether this task has some kind of reset like retry and rollback going on. */
    hasReset(): boolean;
    /** Returns whether enabled function resolves to true. */
    isEnabled(): boolean;
    /** Returns whether this task actually has a title. */
    hasTitle(): boolean;
    /** Returns whether this task has a prompt inside. */
    isPrompt(): boolean;
    /** Returns whether this task is currently paused. */
    isPaused(): boolean;
    /** Returns whether this task is closed. */
    isClosed(): boolean;
    /** Pause the given task for certain time. */
    pause(time: number): Promise<void>;
    /** Run the current task. */
    run(context: Ctx, wrapper: TaskWrapper<Ctx, Renderer>): Promise<void>;
    private close;
}

declare class ListrEventManager extends EventManager<ListrEventType, ListrEventMap> {
}

declare enum ListrDefaultRendererLogLevels {
    SKIPPED_WITH_COLLAPSE = "SKIPPED_WITH_COLLAPSE",
    SKIPPED_WITHOUT_COLLAPSE = "SKIPPED_WITHOUT_COLLAPSE",
    OUTPUT = "OUTPUT",
    OUTPUT_WITH_BOTTOMBAR = "OUTPUT_WITH_BOTTOMBAR",
    PENDING = "PENDING",
    COMPLETED = "COMPLETED",
    COMPLETED_WITH_FAILED_SUBTASKS = "COMPLETED_WITH_FAILED_SUBTASKS",
    COMPLETED_WITH_FAILED_SISTER_TASKS = "COMPLETED_WITH_SISTER_TASKS_FAILED",
    RETRY = "RETRY",
    ROLLING_BACK = "ROLLING_BACK",
    ROLLED_BACK = "ROLLED_BACK",
    FAILED = "FAILED",
    FAILED_WITH_FAILED_SUBTASKS = "FAILED_WITH_SUBTASKS",
    WAITING = "WAITING",
    PAUSED = "PAUSED"
}
declare const LISTR_DEFAULT_RENDERER_STYLE: ListrLoggerStyleMap<ListrDefaultRendererLogLevels>;

declare class DefaultRenderer implements ListrRenderer {
    private readonly tasks;
    private readonly options;
    private readonly events;
    static nonTTY: boolean;
    static rendererOptions: ListrDefaultRendererOptions;
    static rendererTaskOptions: ListrDefaultRendererTaskOptions;
    private bottom;
    private prompt;
    private activePrompt;
    private readonly spinner;
    private readonly logger;
    private updater;
    private truncate;
    private wrap;
    private readonly cache;
    constructor(tasks: ListrDefaultRendererTask[], options: ListrDefaultRendererOptions, events: ListrEventManager);
    isBottomBar(task: ListrDefaultRendererTask): boolean;
    render(): Promise<void>;
    update(): void;
    end(): void;
    create(options?: {
        tasks?: boolean;
        bottomBar?: boolean;
        prompt?: boolean;
    }): string;
    protected style(task: ListrDefaultRendererTask, output?: boolean): string;
    protected format(message: string, icon: string, level: number): string[];
    private renderer;
    private renderBottomBar;
    private renderPrompt;
    private calculate;
    private reset;
    private dump;
    private indent;
}

type PresetTimer = LoggerFieldFn<[number]>;
interface RendererPresetTimer {
    /**
     * Show duration for the tasks.
     */
    timer?: PresetTimer;
}

declare const PRESET_TIMER: PresetTimer;

/**
 * A basic function to parse minutes and tasks passed given a duration.
 * Useful for renderers to show the task time.
 */
declare function parseTimer(duration: number): string;

type PresetTimestamp = LoggerFieldFn;
interface RendererPresetTimestamp {
    /**
     * Show timestamp for each event that has been logged.
     */
    timestamp?: PresetTimestamp;
}

declare const PRESET_TIMESTAMP: PresetTimestamp;

declare function parseTimestamp(): string;

type ListrDefaultRendererOptionsStyle = ListrLoggerStyleMap<ListrDefaultRendererLogLevels>;
type ListrDefaultRendererTask = Task<any, typeof DefaultRenderer>;
interface ListrDefaultRendererOptions extends RendererPresetTimer, RendererLoggerOptions<ListrDefaultRendererLogLevels>, ListrLoggerStyleMap<ListrDefaultRendererLogLevels> {
    /**
     * Indentation per-level.
     *
     * - This is a global option that can only be changed through the main Listr class.
     *
     * @defaultValue `2`
     */
    indentation?: number;
    /**
     * Formats the output in to the given lines of `process.stdout.columns`.
     *
     * - This is a global option that can only be changed through the main Listr class.
     *
     * @defaultValue `'wrap'`
     */
    formatOutput?: 'truncate' | 'wrap';
    /**
     * Clear all the output generated by the renderer when the Listr completes the execution successfully.
     *
     * - This is a global option that can only be changed through the main Listr class.
     *
     * @defaultValue `false`
     */
    clearOutput?: boolean;
    /**
     * Only update the render whenever there is a incoming request through the hook.
     *
     * - This is a global option that can only be changed through the main Listr class.
     * - Useful for snapshot tests, where this will disable showing spinner and only update the screen if something else has happened in the task worthy to show.
     *
     * @defaultValue `false`
     */
    lazy?: boolean;
    /**
     * Remove empty lines from the output section for decluterring multiple line output.
     *
     * @defaultValue `true`
     */
    removeEmptyLines?: boolean;
    /**
     * Spinner visually indicates that a task is running.
     *
     * - You can always implement your own spinner, if the current one does not please you visually.
     */
    spinner?: Spinner;
    /**
     * Show the subtasks of the current task.
     *
     * @defaultValue `true`
     */
    showSubtasks?: boolean;
    /**
     * Collapse subtasks after current task completes its execution.
     *
     * @defaultValue `true`
     */
    collapseSubtasks?: boolean;
    /**
     * Show skip messages or show the original title of the task.
     *
     * - `true` will output the given skip message if there is any.
     * - `false` will keep the current task title intact. This will also disable `collapseSkips`.
     *
     * @defaultValue `true`
     */
    showSkipMessage?: boolean;
    /**
     * Collapse skip messages into a single message and overwrite the task title.
     *
     * - `true` will collapse skiped tasks.
     * - `false` will show the skip message as a data output under the current task title.
     *
     * @defaultValue `true`
     */
    collapseSkips?: boolean;
    /**
     * Suffix skip messages to clearly indicate the task has been skipped with in `collapseSkips` mode.
     *
     * - `true` will add `[SKIPPED]` as a suffix.
     * - `false` will not add a suffix.
     *
     * @defaultValue `false`
     */
    suffixSkips?: boolean;
    /**
     * Show the error message or show the original title of the task.
     *
     * - `true` will output the current error encountered with the task if there is any.
     * - `false` will keep the current task title intact. This will also disable `collapseErrors`.
     *
     * @defaultValue `true`
     */
    showErrorMessage?: boolean;
    /**
     * Collapse error messages into a single message and overwrite the task title.
     *
     * - `true` will collapse the error message.
     * - `false` will show the error message as a data output under the current task title.
     *
     * @defaultValue `true`
     */
    collapseErrors?: boolean;
    /**
     * Suffix retry messages to clearly indicate the task is currently retrying.
     *
     * - `true` will add `[RETRY:COUNT]` as a suffix.
     * - `false` will not add a suffix.
     *
     * @defaultValue `false`
     */
    suffixRetries?: boolean;
    /**
     * Show duration for the pauses.
     *
     * @defaultValue `PRESET_TIMER`
     */
    pausedTimer?: PresetTimer;
}
interface ListrDefaultRendererTaskOptions extends RendererPresetTimer {
    /**
     * Write task output to the bottom bar instead of the gap under the task title itself.
     * This can be useful for stream of data coming in and is the default mode for tasks without a title.
     *
     * - `true` only keep 1 line of the latest data outputted by the task.
     * - `number` will keep the defined amount of data as the last lines.
     * - `false` will not use bottom bar if task has a title.
     *
     * @defaultValue `false`
     */
    bottomBar?: boolean | number;
    /**
     * Keep output of the task after task finishes.
     *
     * - This can be enabled for both normal task output under the title and bottom bar.
     *
     * @defaultValue false
     */
    persistentOutput?: boolean;
}
interface ListrDefaultRendererCache {
    output: ListrRendererCacheMap<string[]>;
    rendererOptions: ListrRendererCacheMap<ListrDefaultRendererOptions>;
    rendererTaskOptions: ListrRendererCacheMap<ListrDefaultRendererTaskOptions>;
}

declare class SilentRenderer implements ListrRenderer {
    tasks: ListrSilentRendererTask[];
    options: ListrSilentRendererOptions;
    static nonTTY: boolean;
    static rendererOptions: ListrSilentRendererOptions;
    static rendererTaskOptions: ListrSilentRendererTaskOptions;
    constructor(tasks: ListrSilentRendererTask[], options: ListrSilentRendererOptions);
    render(): void;
    end(): void;
}

type ListrSilentRendererTask = Task<any, typeof SilentRenderer>;
type ListrSilentRendererOptions = never;
type ListrSilentRendererTaskOptions = never;

declare class SimpleRenderer implements ListrRenderer {
    private readonly tasks;
    private options;
    static nonTTY: boolean;
    static rendererOptions: ListrSimpleRendererOptions;
    static rendererTaskOptions: ListrSimpleRendererTaskOptions;
    private readonly logger;
    private readonly cache;
    constructor(tasks: ListrSimpleRendererTask[], options: ListrSimpleRendererOptions);
    end(): void;
    render(): void;
    private renderer;
    private calculate;
    private reset;
}

type ListrSimpleRendererTask = Task<any, typeof SimpleRenderer>;
interface ListrSimpleRendererOptions extends RendererPresetTimer, RendererPresetTimestamp, RendererLoggerOptions<ListrLogLevels>, ListrLoggerStyleMap<ListrLogLevels> {
    /**
     * Show duration for the pauses.
     *
     * @defaultValue `PRESET_TIMER`
     */
    pausedTimer?: PresetTimer;
}
interface ListrSimpleRendererTaskOptions extends RendererPresetTimer {
}
interface ListrSimpleRendererCache {
    rendererOptions: ListrRendererCacheMap<ListrSimpleRendererOptions>;
    rendererTaskOptions: ListrRendererCacheMap<ListrSimpleRendererTaskOptions>;
}

declare class TestRenderer implements ListrRenderer {
    private readonly tasks;
    private readonly options;
    static nonTTY: boolean;
    static rendererOptions: ListrTestRendererOptions;
    static rendererTaskOptions: ListrTestRendererTaskOptions;
    private readonly logger;
    private serializer;
    constructor(tasks: ListrTestRendererTask[], options: ListrTestRendererOptions);
    render(): void;
    end(): void;
    private renderer;
}

interface TestRendererSerializerOutput<T extends ListrTaskEventType> {
    event: T;
    data: ListrTaskEventMap[T];
    task?: Partial<Record<TestRendererSerializerTaskKeys, unknown>>;
}
type TestRendererSerializerTaskKeys = Extract<keyof Task<any, typeof TestRenderer>, 'hasSubtasks' | 'hasFinalized' | 'isPending' | 'isStarted' | 'isSkipped' | 'isCompleted' | 'hasFailed' | 'isRollingBack' | 'hasRolledBack' | 'isRetrying' | 'hasReset' | 'isEnabled' | 'hasTitle' | 'isPrompt' | 'isPaused' | 'title' | 'path'>;

type ListrTestRendererTask = Task<any, typeof TestRenderer>;
interface ListrTestRendererOptions extends RendererLoggerOptions<ListrLogLevels> {
    /**
     * Log subtasks.
     *
     * @defaultValue `true`
     */
    subtasks?: boolean;
    /**
     * Log given task states.
     */
    state?: ListrTaskState[];
    /**
     * Log output.
     */
    output?: boolean;
    /**
     * Log prompt.
     */
    prompt?: boolean;
    /**
     * Log title changes.
     */
    title?: boolean;
    /**
     * Log given messages.
     */
    messages?: (keyof ListrTaskMessage)[];
    /**
     * Log given messages to stderr instead of stdout.
     */
    messagesToStderr?: (keyof ListrTaskMessage)[];
    /**
     * Serialize the given properties of the task inside the logs.
     */
    task?: false | TestRendererSerializerTaskKeys[];
}
type ListrTestRendererTaskOptions = never;

declare class TestRendererSerializer {
    options?: ListrTestRendererOptions;
    constructor(options?: ListrTestRendererOptions);
    serialize<T extends ListrTaskEventType>(event: T, data: ListrTaskEventMap[T], task?: ListrTestRendererTask): string;
    generate<T extends ListrTaskEventType>(event: T, data: ListrTaskEventMap[T], task?: ListrTestRendererTask): TestRendererSerializerOutput<T>;
}

declare class VerboseRenderer implements ListrRenderer {
    private readonly tasks;
    private readonly options;
    static nonTTY: boolean;
    static rendererOptions: ListrVerboseRendererOptions;
    static rendererTaskOptions: ListrVerboseRendererTaskOptions;
    private logger;
    private readonly cache;
    constructor(tasks: ListrVerboseRendererTask[], options: ListrVerboseRendererOptions);
    render(): void;
    end(): void;
    private renderer;
    private calculate;
    private reset;
}

type ListrVerboseRendererTask = Task<any, typeof VerboseRenderer>;
interface ListrVerboseRendererOptions extends RendererPresetTimer, RendererPresetTimestamp, RendererLoggerOptions<ListrLogLevels>, ListrLoggerStyleMap<ListrLogLevels> {
    /**
     * Log the title changes of the task.
     *
     * @default `false`
     */
    logTitleChange?: boolean;
    /**
     * Show duration for the pauses.
     *
     * @defaultValue `PRESET_TIMER`
     */
    pausedTimer?: PresetTimer;
}
interface ListrVerboseRendererTaskOptions extends RendererPresetTimer {
}
interface ListrVerboseRendererCache {
    rendererOptions: ListrRendererCacheMap<ListrVerboseRendererOptions>;
    rendererTaskOptions: ListrRendererCacheMap<ListrVerboseRendererTaskOptions>;
}

/** Name of the default renderer. */
type ListrDefaultRendererValue = 'default';
/** Type of default renderer. */
type ListrDefaultRenderer = typeof DefaultRenderer;
/** Name of simple renderer. */
type ListrSimpleRendererValue = 'simple';
/** Type of simple renderer. */
type ListrSimpleRenderer = typeof SimpleRenderer;
/** Name of verbose renderer. */
type ListrVerboseRendererValue = 'verbose';
/** Type of verbose renderer. */
type ListrVerboseRenderer = typeof VerboseRenderer;
/** Name of test renderer. */
type ListrTestRendererValue = 'test';
/** Type of test renderer. */
type ListrTestRenderer = typeof TestRenderer;
/** Name of silent renderer. */
type ListrSilentRendererValue = 'silent';
/** Type of silent renderer. */
type ListrSilentRenderer = typeof SilentRenderer;
/** The default prefered renderer. */
type ListrPrimaryRendererValue = ListrDefaultRendererValue;
/** The default fallback renderer. */
type ListrSecondaryRendererValue = ListrSimpleRendererValue;
/**
 * Listr2 can process either the integrated renderers as string aliases,
 * or utilize a compatible style renderer that extends the ListrRenderer abstract class.
 */
type ListrRendererValue = ListrSilentRendererValue | ListrDefaultRendererValue | ListrSimpleRendererValue | ListrVerboseRendererValue | ListrTestRendererValue | ListrRendererFactory;
/**
 * Returns the class type from friendly names of the renderers.
 */
type ListrGetRendererClassFromValue<T extends ListrRendererValue> = T extends ListrDefaultRendererValue ? ListrDefaultRenderer : T extends ListrSimpleRendererValue ? ListrSimpleRenderer : T extends ListrVerboseRendererValue ? ListrVerboseRenderer : T extends ListrTestRendererValue ? ListrTestRenderer : T extends ListrSilentRenderer ? ListrSilentRenderer : T extends ListrRendererFactory ? T : never;
/**
 * Returns the friendly names from the type of renderer classes.
 */
type ListrGetRendererValueFromClass<T extends ListrRendererFactory> = T extends DefaultRenderer ? ListrDefaultRendererValue : T extends SimpleRenderer ? ListrSimpleRendererValue : T extends VerboseRenderer ? ListrVerboseRendererValue : T extends TestRenderer ? ListrTestRendererValue : T extends SilentRenderer ? ListrSilentRenderer : T extends ListrRendererFactory ? T : never;
/**
 * Returns renderer global options depending on the renderer type.
 */
type ListrGetRendererOptions<T extends ListrRendererValue> = T extends ListrRendererValue ? ListrGetRendererClassFromValue<T>['rendererOptions'] : never;
/**
 * Returns renderer per-task options depending on the renderer type.
 */
type ListrGetRendererTaskOptions<T extends ListrRendererValue> = T extends ListrRendererValue ? ListrGetRendererClassFromValue<T>['rendererTaskOptions'] : never;
/** Selection and options of the primary preferred renderer. */
interface ListrPrimaryRendererOptions<T extends ListrRendererValue> {
    /** Default renderer preferred. */
    renderer?: T;
    /** Renderer options depending on the current renderer. */
    rendererOptions?: ListrGetRendererOptions<T>;
}
/** Selection and options of the preferred fallback renderer. */
interface ListrSecondaryRendererOptions<T extends ListrRendererValue> {
    /** Fallback renderer preferred. */
    fallbackRenderer?: T;
    /** Renderer options depending on the fallback renderer. */
    fallbackRendererOptions?: ListrGetRendererOptions<T>;
}
/** Renderer options for the parent Listr class, including setup for selecting default and fallback renderers.  */
type ListrRendererOptions<Renderer extends ListrRendererValue, FallbackRenderer extends ListrRendererValue> = ListrPrimaryRendererOptions<Renderer> & ListrSecondaryRendererOptions<FallbackRenderer>;
/**
 * The definition of a ListrRenderer.
 *
 * @see {@link https://listr2.kilic.dev/renderer/renderer.html}
 */
declare class ListrRenderer {
    /** designate renderer global options that is specific to the current renderer */
    static rendererOptions: Record<PropertyKey, any>;
    /** designate renderer per task options that is specific to the current renderer  */
    static rendererTaskOptions: Record<PropertyKey, any>;
    /** designate whether this renderer can work in non-tty environments */
    static nonTTY: boolean;
    /** A function to what to do on render */
    render: () => void | Promise<void>;
    /** A function to what to do on end of the render */
    end: (err?: Error) => void;
    /** create a new renderer */
    constructor(tasks: readonly Task<any, ListrRendererFactory>[], options: typeof ListrRenderer.rendererOptions, events?: ListrEventManager);
}
/** Factory of compatible Listr renderers. */
type ListrRendererFactory = typeof ListrRenderer;
/** Renderer selection for current Listr. */
interface SupportedRenderer<Renderer extends ListrRendererFactory> {
    renderer: Renderer;
    options?: ListrGetRendererOptions<Renderer>;
}
type ListrRendererCacheMap<T> = Map<Task<any, any>['id'], T>;

/** Listr context. */
type ListrContext = any | undefined;
/**
 * Options to set the behavior of Listr.
 */
interface ListrOptions<Ctx = ListrContext> {
    /**
     * Inject a context through this options wrapper.
     *
     * @defaultValue `{}`
     * @see {@link https://listr2.kilic.dev/listr/context.html}
     */
    ctx?: Ctx;
    /**
     * Concurrency limits how many tasks will be running in parallel.
     *
     * - `false` will only run a single task at a time.
     * - `true` will set it to `Infinity` to run all the tasks in parallel.
     * - Given a `number` it will limit the concurrency to that number.
     *
     * @defaultValue `false`
     */
    concurrent?: boolean | number;
    /**
     * Determine the default behavior of exiting on errors.
     *
     * - `true` will exit the current Listr whenever it encounters an error.
     * - `false` will continue the execution of current Listr if it encounters an error.
     *
     * @defaultValue `true`
     */
    exitOnError?: boolean;
    /**
     * Determine the behavior of exiting after rollback actions.
     *
     * This is independent of `exitOnError`, since failure of a rollback can be a more critical operation comparing to
     * failing a single task.
     *
     * - `true` will stop the execution whenever a rollback happens.
     * - `false` will continue after successfully recovering from a rollback.
     *
     * @defaultValue `true`
     */
    exitAfterRollback?: boolean;
    /**
     * Collects errors inside the `Listr.errors`.
     *
     * - `false` will collect no errors.
     * - `minimal` will only collect the error message and the location.
     * - `full` will clone the current context and task in to the error instance.
     *
     * @defaultValue `false`
     * @see {@link https://listr2.kilic.dev/task/error-handling.html#collected-errors}
     */
    collectErrors?: false | 'minimal' | 'full';
    /**
     * Listr will track SIGINIT signal to update the renderer one last time before failing, therefore it needs to
     * register exit listeners.
     *
     * @defaultValue true
     */
    registerSignalListeners?: boolean;
    /**
     * Determine the certain condition required to use the fallback renderer.
     *
     * @defaultValue handled internally
     */
    fallbackRendererCondition?: boolean | (() => boolean);
    /**
     * Determine the certain condition required to use the silent renderer.
     *
     * @defaultValue handled internally
     */
    silentRendererCondition?: boolean | (() => boolean);
    /**
     * Disable the color output coming from Listr for all renderers.
     *
     * @defaultValue `false`
     */
    disableColor?: boolean;
    /**
     * Force use color, even though the underlying library detects your current output may not be compatible.
     *
     * @defaultValue `false`
     */
    forceColor?: boolean;
    /**
     * Forces TTY stdout even though your current output may not be compatible.
     *
     * @defaultValue `false`
     */
    forceTTY?: boolean;
    /**
     * Forces unicode icons even though your current output may not be compatible.
     *
     * @defaultValue `false`
     */
    forceUnicode?: boolean;
    /**
     * Inject data directly to TaskWrapper.
     */
    injectWrapper?: {
        /**
         * Inject an `enquirer` instance for using with prompts.
         */
        enquirer?: Enquirer<object>;
    };
}
/**
 * Parent Listr has more options where you can also change global settings.
 *
 * Any subtasks will respect those options so they will be stripped of that properties.
 */
interface ListrBaseClassOptions<Ctx = ListrContext, Renderer extends ListrRendererValue = ListrPrimaryRendererValue, FallbackRenderer extends ListrRendererValue = ListrSecondaryRendererValue> extends ListrOptions<Ctx>, ListrPrimaryRendererOptions<Renderer>, ListrSecondaryRendererOptions<FallbackRenderer> {
}
/**
 * Subtasks has reduced set options where the missing ones are explicitly set by the base class.
 */
interface ListrSubClassOptions<Ctx = ListrContext, Renderer extends ListrRendererValue = ListrPrimaryRendererValue> extends Omit<ListrOptions<Ctx>, 'registerSignalListeners' | 'fallbackRendererCondition' | 'silentRendererCondition' | 'disableColor' | 'forceColor' | 'forceTTY' | 'forceUnicode'>, Omit<ListrPrimaryRendererOptions<Renderer>, 'renderer'> {
}

/**
 * Internal error handling mechanism for Listr collects the errors and details for a failed task.
 *
 * @see {@link https://listr2.kilic.dev/task/error-handling.html}
 */
declare class ListrError<Ctx extends ListrContext = ListrContext> extends Error {
    error: Error;
    type: ListrErrorTypes;
    task: Task<Ctx, ListrRendererFactory>;
    path: string[];
    ctx: Ctx;
    constructor(error: Error, type: ListrErrorTypes, task: Task<Ctx, ListrRendererFactory>);
}

/**
 * Event map for Listr.
 *
 * @see {@link https://listr2.kilic.dev/listr/events.html}
 * @see {@link module:listr2.ListrEventType}
 */
declare class ListrEventMap extends BaseEventMap implements EventMap<ListrEventType> {
    [ListrEventType.SHOULD_REFRESH_RENDER]: never;
}

/**
 * Internal error coming from renderer.
 */
declare class ListrRendererError extends Error {
}

/**
 * Internal error handling mechanism for Listr prompts to identify the failing cause is coming from a prompt.
 *
 * @see {@link https://listr2.kilic.dev/task/prompts.html}
 */
declare class PromptError extends Error {
}

/**
 * Defines the task, conditions and options to run a specific task in the Listr.
 * This defines the external API for the task where {@link TaskWrapper} is used internally.
 *
 * @see {@link https://listr2.kilic.dev/task/task.html}
 */
interface ListrTask<Ctx = ListrContext, Renderer extends ListrRendererFactory = any> {
    /**
     * Title of the task.
     *
     * Give this task a title to enchance it on the preferred renderer.
     *
     * - Tasks without a title will be hidden from view in renderers and will act as a background task.
     *
     * @see {@link https://listr2.kilic.dev/task/title.html}
     */
    title?: string | any[];
    /**
     * The task itself in the form of a `Function`, `Promise`, `Listr`, `Observable` or `Stream`.
     *
     * - Task will be executed, whenever the provided criterion is met with the current state and whenever the time for that specific task has come.
     *
     * @see {@link https://listr2.kilic.dev/task/task.html}
     */
    task: ListrTaskFn<Ctx, Renderer>;
    /**
     * Enable a task depending on the context.
     *
     * - The callback function will be evaluated before all the tasks start to check which tasks has been enabled.
     * - The callback function will be evaluated again before the task starts.
     *
     * @see {@link https://listr2.kilic.dev/task/enable.html}
     */
    enabled?: boolean | ((ctx: Ctx) => boolean | Promise<boolean>);
    /**
     * Skip this task depending on the context.
     *
     * - The callback function will be evaluated once before the task starts.
     *
     * @see {@link https://listr2.kilic.dev/task/skip.html}
     */
    skip?: boolean | string | ((ctx: Ctx) => boolean | string | Promise<boolean | string>);
    /**
     * Retries a task with the given amounts whenever a task fails.
     *
     * @see {@link https://listr2.kilic.dev/task/retry.html}
     */
    retry?: number | {
        tries: number;
        delay?: number;
    };
    /**
     * The callback function that you provide will run whenever the attached task fails and
     * give you the ability to revert your changes, before failing.
     *
     * @see {@link https://listr2.kilic.dev/task/rollback.html}
     */
    rollback?: ListrTaskFn<Ctx, Renderer>;
    /**
     * Determine the default behavior of exiting on errors for this attached task.
     */
    exitOnError?: boolean | ((ctx: Ctx) => boolean | Promise<boolean>);
    /**
     * Per-task options, that depends on the selected renderer.
     *
     * - Options of the current preferred renderer can be changed on task level.
     * - These options depend on the implementation of the preferred renderer.
     * - Whenever the preferred renderer has no options it will be displayed as never.
     *
     * **This option will be deprecated in a future major release in favor of having options for both the default and the fallback renderer.**
     */
    options?: ListrGetRendererTaskOptions<Renderer>;
}
/**
 * Result of the processed task can be any of the supported types.
 */
type ListrTaskResult<Ctx> = string | Promise<any> | Listr<Ctx, ListrRendererValue, any> | Readable | NodeJS.ReadableStream | Observable<any>;
/**
 * The callback function from the user that defines the task.
 */
type ListrTaskFn<Ctx, Renderer extends ListrRendererFactory> = (ctx: Ctx, task: TaskWrapper<Ctx, Renderer>) => void | ListrTaskResult<Ctx>;
/**
 * Tasks can have attached prompts to them.
 *
 * - Whenever the prompt is running this should be with full with the instance of current prompt.
 * - Whenever the prompt fails/cancelled it is tracked here as well due to some internal complication with `enquirer`.
 */
type ListrTaskPrompt = PromptInstance | PromptError;
/**
 * Tasks can retry themselves when defined.
 *
 * - This holds the value of the current error and the current retry attempt.
 */
interface ListrTaskRetry {
    count: number;
    error?: Error;
}
/**
 * Task can provide additional information depending on the current state of the Task.
 *
 * TaskMessage is used to propagate these messages to the renderers for displaying them to the end-user.
 */
interface ListrTaskMessage {
    /** Elapsed time of the current task, whenever the Task completes. */
    duration?: number;
    /** Error message from the current task, whenever the Task fails. */
    error?: string;
    /** Skip message from the current task, whenever the Task skips. */
    skip?: string;
    /** Rollback message from the current task, whenever the Task finishes rollback. */
    rollback?: string;
    /** Retry message from the current task, whenever the Task tries to retry. */
    retry?: ListrTaskRetry;
    /** Holds the time as epoch time of when will this task continue to execute. */
    paused?: number;
}

/**
 * Event map for Task.
 *
 * @see {@link https://listr2.kilic.dev/task/events.html}
 * @see {@link module:listr2.ListrTaskEventType}
 */
declare class ListrTaskEventMap extends BaseEventMap implements EventMap<ListrTaskEventType> {
    [ListrTaskEventType.STATE]: ListrTaskState;
    [ListrTaskEventType.ENABLED]: boolean;
    [ListrTaskEventType.SUBTASK]: Task<any, any>[];
    [ListrTaskEventType.TITLE]: string;
    [ListrTaskEventType.OUTPUT]: string;
    [ListrTaskEventType.MESSAGE]: ListrTaskMessage;
    [ListrTaskEventType.PROMPT]: string;
    [ListrTaskEventType.CLOSED]: never;
}

/**
 * Create a new task list with Listr.
 *
 * @see {@link https://listr2.kilic.dev/listr/listr.html}
 */
declare class Listr<Ctx = ListrContext, Renderer extends ListrRendererValue = ListrPrimaryRendererValue, FallbackRenderer extends ListrRendererValue = ListrSecondaryRendererValue> {
    task: ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>> | ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>>[];
    options?: ListrBaseClassOptions<Ctx, Renderer, FallbackRenderer>;
    parentTask?: Task<any, any>;
    tasks: Task<Ctx, ListrGetRendererClassFromValue<Renderer>>[];
    errors: ListrError<Ctx>[];
    ctx: Ctx;
    events: ListrEventManager;
    path: string[];
    rendererClass: ListrRendererFactory;
    rendererClassOptions: ListrGetRendererOptions<ListrRendererFactory>;
    private concurrency;
    private renderer;
    constructor(task: ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>> | ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>>[], options?: ListrBaseClassOptions<Ctx, Renderer, FallbackRenderer>, parentTask?: Task<any, any>);
    add(tasks: ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>> | ListrTask<Ctx, ListrGetRendererClassFromValue<Renderer>>[]): void;
    run(context?: Ctx): Promise<Ctx>;
    private generate;
    private runTask;
}

/**
 * Creates a new Listr2 task manager.
 *
 * Useful for creating a single instance of Listr2 with pre-set settings.
 *
 * @see {@link https://listr2.kilic.dev/listr/manager.html}
 */
declare class Manager<Ctx = ListrContext, Renderer extends ListrRendererValue = ListrPrimaryRendererValue, FallbackRenderer extends ListrRendererValue = ListrSecondaryRendererValue> {
    options?: ListrBaseClassOptions<Ctx, Renderer, FallbackRenderer>;
    errors: ListrError[];
    tasks: ListrTask<ListrContext, ListrGetRendererClassFromValue<Renderer>>[];
    constructor(options?: ListrBaseClassOptions<Ctx, Renderer, FallbackRenderer>);
    get ctx(): Ctx;
    set ctx(ctx: Ctx);
    add<InjectCtx = Ctx>(tasks: ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>[] | ((ctx?: InjectCtx) => ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>[]), options?: ListrSubClassOptions<InjectCtx, Renderer>): void;
    runAll<InjectCtx = Ctx>(options?: ListrBaseClassOptions<InjectCtx, Renderer, FallbackRenderer>): Promise<InjectCtx>;
    newListr<InjectCtx, InjectRenderer extends ListrRendererValue = Renderer, InjectFallbackRenderer extends ListrRendererValue = FallbackRenderer>(tasks: ListrTask<InjectCtx, ListrGetRendererClassFromValue<InjectRenderer>>[], options?: ListrBaseClassOptions<InjectCtx, InjectRenderer, InjectFallbackRenderer>): Listr<InjectCtx, InjectRenderer, InjectFallbackRenderer>;
    indent<InjectCtx = Ctx>(tasks: ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>[] | ((ctx?: InjectCtx) => ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>[]), options?: ListrBaseClassOptions<InjectCtx, Renderer, FallbackRenderer>, taskOptions?: Omit<ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>, 'task'>): ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>;
    run<InjectCtx = Ctx>(tasks: ListrTask<InjectCtx, ListrGetRendererClassFromValue<Renderer>>[], options?: ListrBaseClassOptions<InjectCtx, Renderer, FallbackRenderer>): Promise<InjectCtx>;
}

export { ANSI_ESCAPE, ANSI_ESCAPE_CODES, BaseEventMap, Concurrency, DefaultRenderer, EventData, EventManager, EventMap, Figures, LISTR_DEFAULT_RENDERER_STYLE, LISTR_LOGGER_STDERR_LEVELS, LISTR_LOGGER_STYLE, Listr, ListrBaseClassOptions, ListrContext, ListrDefaultRenderer, ListrDefaultRendererCache, ListrDefaultRendererLogLevels, ListrDefaultRendererOptions, ListrDefaultRendererOptionsStyle, ListrDefaultRendererTask, ListrDefaultRendererTaskOptions, ListrDefaultRendererValue, ListrEnvironmentVariables, ListrError, ListrErrorTypes, ListrEventManager, ListrEventMap, ListrEventType, ListrGetRendererClassFromValue, ListrGetRendererOptions, ListrGetRendererTaskOptions, ListrGetRendererValueFromClass, ListrLogLevels, ListrLogger, ListrLoggerOptions, ListrLoggerStyleMap, ListrOptions, ListrPrimaryRendererOptions, ListrPrimaryRendererValue, ListrRenderer, ListrRendererCacheMap, ListrRendererError, ListrRendererFactory, ListrRendererOptions, ListrRendererValue, ListrSecondaryRendererOptions, ListrSecondaryRendererValue, ListrSilentRenderer, ListrSilentRendererOptions, ListrSilentRendererTask, ListrSilentRendererTaskOptions, ListrSilentRendererValue, ListrSimpleRenderer, ListrSimpleRendererCache, ListrSimpleRendererOptions, ListrSimpleRendererTask, ListrSimpleRendererTaskOptions, ListrSimpleRendererValue, ListrSubClassOptions, ListrTask, ListrTaskEventManager, ListrTaskEventMap, ListrTaskEventType, ListrTaskFn, ListrTaskMessage, Task as ListrTaskObject, ListrTaskPrompt, ListrTaskResult, ListrTaskRetry, ListrTaskState, TaskWrapper as ListrTaskWrapper, ListrTestRenderer, ListrTestRendererOptions, ListrTestRendererTask, ListrTestRendererTaskOptions, ListrTestRendererValue, ListrVerboseRenderer, ListrVerboseRendererCache, ListrVerboseRendererOptions, ListrVerboseRendererTask, ListrVerboseRendererTaskOptions, ListrVerboseRendererValue, LoggerField, LoggerFieldFn, LoggerFieldOptions, LoggerFormat, LoggerFormatOptions, Manager, PRESET_TIMER, PRESET_TIMESTAMP, PresetTimer, PresetTimestamp, ProcessOutput, ProcessOutputBuffer, ProcessOutputBufferEntry, ProcessOutputBufferOptions, ProcessOutputOptions, ProcessOutputRendererOptions, ProcessOutputStream, ProcessOutputStreamMap, PromptCancelOptions, PromptError, PromptInstance, PromptOptions, PromptOptionsMap, PromptOptionsType, PromptSettings, PromptTypes, RendererLoggerOptions, RendererPresetTimer, RendererPresetTimestamp, SilentRenderer, SimpleRenderer, Spinner, SupportedRenderer, TestRenderer, TestRendererSerializer, TestRendererSerializerOutput, TestRendererSerializerTaskKeys, Unionize, VerboseRenderer, assertFunctionOrSelf, cleanseAnsi, cloneObject, color, createPrompt, createWritable, delay, figures, getRenderer, getRendererClass, indent, isObservable, isUnicodeSupported, parseTimer, parseTimestamp, splat };
