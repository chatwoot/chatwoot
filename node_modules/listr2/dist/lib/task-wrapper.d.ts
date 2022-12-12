/// <reference types="node" />
import { ListrError } from '../interfaces/listr-error.interface';
import { ListrBaseClassOptions, ListrSubClassOptions, ListrTask } from '../interfaces/listr.interface';
import { ListrRendererFactory } from '../interfaces/renderer.interface';
import { Task } from './task';
import { Listr } from '../listr';
import { PromptOptions } from '../utils/prompt.interface';
/**
 * Extend the task to have more functionality while accesing from the outside.
 */
export declare class TaskWrapper<Ctx, Renderer extends ListrRendererFactory> {
    task: Task<Ctx, ListrRendererFactory>;
    errors: ListrError[];
    private options;
    constructor(task: Task<Ctx, ListrRendererFactory>, errors: ListrError[], options: ListrBaseClassOptions<Ctx, any, any>);
    /** Change the title of the current task. */
    set title(data: string);
    /** Get the title of the current task. */
    get title(): string;
    /** Send a output to the output channel. */
    set output(data: string);
    /** Get the output from the output channel. */
    get output(): string;
    /** Create a new subtask with given renderer selection from the parent task. */
    newListr(task: ListrTask<Ctx, Renderer> | ListrTask<Ctx, Renderer>[] | ((parent: this) => ListrTask<Ctx, Renderer> | ListrTask<Ctx, Renderer>[]), options?: ListrSubClassOptions<Ctx, Renderer>): Listr<Ctx, any, any>;
    /** Report a error in process for error collection. */
    report(error: Error | ListrError): void;
    /** Skip current task. */
    skip(message?: string): void;
    /** Get the number of retrying, else returns false */
    isRetrying(): Task<Ctx, Renderer>['retry'];
    /**
     * Create a new Enquirer prompt using prompt options.
     *
     * Since process.stdout is controlled by Listr, this will passthrough all Enquirer data through internal stdout.
     */
    prompt<T = any>(options: PromptOptions | PromptOptions<true>[]): Promise<T>;
    /** Cancels the current prompt attach to this task. */
    cancelPrompt(throwError?: boolean): void;
    /**
     * Pass stream of data to internal stdout.
     *
     * Since Listr2 takes control of process.stdout utilizing the default renderer, any data outputted to process.stdout
     * will corupt its looks.
     *
     * This returns a fake stream to pass any stream inside Listr as task data.
     */
    stdout(): NodeJS.WriteStream & NodeJS.WritableStream;
    /** Run this task. */
    run(ctx: Ctx): Promise<void>;
}
