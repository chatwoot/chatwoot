import { Event, EventHint, Exception, ParameterizedString, SeverityLevel, StackParser } from '@sentry/types';
/**
 * This function creates an exception from a JavaScript Error
 */
export declare function exceptionFromError(stackParser: StackParser, ex: Error): Exception;
/**
 * Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
 * @hidden
 */
export declare function eventFromException(stackParser: StackParser, exception: unknown, hint?: EventHint, attachStacktrace?: boolean): PromiseLike<Event>;
/**
 * Builds and Event from a Message
 * @hidden
 */
export declare function eventFromMessage(stackParser: StackParser, message: ParameterizedString, level?: SeverityLevel, hint?: EventHint, attachStacktrace?: boolean): PromiseLike<Event>;
/**
 * @hidden
 */
export declare function eventFromUnknownInput(stackParser: StackParser, exception: unknown, syntheticException?: Error, attachStacktrace?: boolean, isUnhandledRejection?: boolean): Event;
//# sourceMappingURL=eventbuilder.d.ts.map
