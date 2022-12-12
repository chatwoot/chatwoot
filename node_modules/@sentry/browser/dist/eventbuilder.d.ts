import { Event, EventHint, Exception, Severity, StackFrame } from '@sentry/types';
/**
 * This function creates an exception from an TraceKitStackTrace
 * @param stacktrace TraceKitStackTrace that will be converted to an exception
 * @hidden
 */
export declare function exceptionFromError(ex: Error): Exception;
/**
 * @hidden
 */
export declare function eventFromPlainObject(exception: Record<string, unknown>, syntheticException?: Error, isUnhandledRejection?: boolean): Event;
/**
 * @hidden
 */
export declare function eventFromError(ex: Error): Event;
/** Parses stack frames from an error */
export declare function parseStackFrames(ex: Error & {
    framesToPop?: number;
    stacktrace?: string;
}): StackFrame[];
/**
 * Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
 * @hidden
 */
export declare function eventFromException(exception: unknown, hint?: EventHint, attachStacktrace?: boolean): PromiseLike<Event>;
/**
 * Builds and Event from a Message
 * @hidden
 */
export declare function eventFromMessage(message: string, level?: Severity, hint?: EventHint, attachStacktrace?: boolean): PromiseLike<Event>;
/**
 * @hidden
 */
export declare function eventFromUnknownInput(exception: unknown, syntheticException?: Error, attachStacktrace?: boolean, isUnhandledRejection?: boolean): Event;
/**
 * @hidden
 */
export declare function eventFromString(input: string, syntheticException?: Error, attachStacktrace?: boolean): Event;
//# sourceMappingURL=eventbuilder.d.ts.map