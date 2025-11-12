import { StackFrame, StackParser } from './stack-trace';
import { SeverityLevel } from '../../types';
type ErrorConversionArgs = {
    event: string | Event;
    error?: Error;
};
type ErrorMetadata = {
    handled?: boolean;
    synthetic?: boolean;
    syntheticException?: Error;
    overrideExceptionType?: string;
    defaultExceptionType?: string;
    defaultExceptionMessage?: string;
};
export interface ErrorProperties {
    $exception_list: Exception[];
    $exception_level?: SeverityLevel;
    $exception_DOMException_code?: string;
    $exception_personURL?: string;
}
export interface Exception {
    type?: string;
    value?: string;
    mechanism?: {
        /**
         * In theory, whether or not the exception has been handled by the user. In practice, whether or not we see it before
         * it hits the global error/rejection handlers, whether through explicit handling by the user or auto instrumentation.
         */
        handled?: boolean;
        type?: string;
        source?: string;
        /**
         * True when `captureException` is called with anything other than an instance of `Error` (or, in the case of browser,
         * an instance of `ErrorEvent`, `DOMError`, or `DOMException`). causing us to create a synthetic error in an attempt
         * to recreate the stacktrace.
         */
        synthetic?: boolean;
    };
    module?: string;
    thread_id?: number;
    stacktrace?: {
        frames?: StackFrame[];
        type: 'raw';
    };
}
export declare function parseStackFrames(ex: Error & {
    stacktrace?: string;
}, framesToPop?: number): StackFrame[];
export declare function applyChunkIds(frames: StackFrame[], parser: StackParser): StackFrame[];
/**
 * There are cases where stacktrace.message is an Event object
 * https://github.com/getsentry/sentry-javascript/issues/1949
 * In this specific case we try to extract stacktrace.message.error.message
 */
export declare function extractMessage(err: Error & {
    message: {
        error?: Error;
    };
}): string;
export declare function errorToProperties({ error, event }: ErrorConversionArgs, metadata?: ErrorMetadata): ErrorProperties;
export declare function unhandledRejectionToProperties([ev]: [ev: PromiseRejectionEvent]): ErrorProperties;
export {};
