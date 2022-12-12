import { __assign } from "tslib";
import { Severity } from '@sentry/types';
import { addExceptionMechanism, addExceptionTypeValue, createStackParser, extractExceptionKeysForMessage, isDOMError, isDOMException, isError, isErrorEvent, isEvent, isPlainObject, normalizeToSize, resolvedSyncPromise, } from '@sentry/utils';
import { chromeStackParser, geckoStackParser, opera10StackParser, opera11StackParser, winjsStackParser, } from './stack-parsers';
/**
 * This function creates an exception from an TraceKitStackTrace
 * @param stacktrace TraceKitStackTrace that will be converted to an exception
 * @hidden
 */
export function exceptionFromError(ex) {
    // Get the frames first since Opera can lose the stack if we touch anything else first
    var frames = parseStackFrames(ex);
    var exception = {
        type: ex && ex.name,
        value: extractMessage(ex),
    };
    if (frames.length) {
        exception.stacktrace = { frames: frames };
    }
    if (exception.type === undefined && exception.value === '') {
        exception.value = 'Unrecoverable error caught';
    }
    return exception;
}
/**
 * @hidden
 */
export function eventFromPlainObject(exception, syntheticException, isUnhandledRejection) {
    var event = {
        exception: {
            values: [
                {
                    type: isEvent(exception) ? exception.constructor.name : isUnhandledRejection ? 'UnhandledRejection' : 'Error',
                    value: "Non-Error " + (isUnhandledRejection ? 'promise rejection' : 'exception') + " captured with keys: " + extractExceptionKeysForMessage(exception),
                },
            ],
        },
        extra: {
            __serialized__: normalizeToSize(exception),
        },
    };
    if (syntheticException) {
        var frames_1 = parseStackFrames(syntheticException);
        if (frames_1.length) {
            event.stacktrace = { frames: frames_1 };
        }
    }
    return event;
}
/**
 * @hidden
 */
export function eventFromError(ex) {
    return {
        exception: {
            values: [exceptionFromError(ex)],
        },
    };
}
/** Parses stack frames from an error */
export function parseStackFrames(ex) {
    // Access and store the stacktrace property before doing ANYTHING
    // else to it because Opera is not very good at providing it
    // reliably in other circumstances.
    var stacktrace = ex.stacktrace || ex.stack || '';
    var popSize = getPopSize(ex);
    try {
        return createStackParser(opera10StackParser, opera11StackParser, chromeStackParser, winjsStackParser, geckoStackParser)(stacktrace, popSize);
    }
    catch (e) {
        // no-empty
    }
    return [];
}
// Based on our own mapping pattern - https://github.com/getsentry/sentry/blob/9f08305e09866c8bd6d0c24f5b0aabdd7dd6c59c/src/sentry/lang/javascript/errormapping.py#L83-L108
var reactMinifiedRegexp = /Minified React error #\d+;/i;
function getPopSize(ex) {
    if (ex) {
        if (typeof ex.framesToPop === 'number') {
            return ex.framesToPop;
        }
        if (reactMinifiedRegexp.test(ex.message)) {
            return 1;
        }
    }
    return 0;
}
/**
 * There are cases where stacktrace.message is an Event object
 * https://github.com/getsentry/sentry-javascript/issues/1949
 * In this specific case we try to extract stacktrace.message.error.message
 */
function extractMessage(ex) {
    var message = ex && ex.message;
    if (!message) {
        return 'No error message';
    }
    if (message.error && typeof message.error.message === 'string') {
        return message.error.message;
    }
    return message;
}
/**
 * Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
 * @hidden
 */
export function eventFromException(exception, hint, attachStacktrace) {
    var syntheticException = (hint && hint.syntheticException) || undefined;
    var event = eventFromUnknownInput(exception, syntheticException, attachStacktrace);
    addExceptionMechanism(event); // defaults to { type: 'generic', handled: true }
    event.level = Severity.Error;
    if (hint && hint.event_id) {
        event.event_id = hint.event_id;
    }
    return resolvedSyncPromise(event);
}
/**
 * Builds and Event from a Message
 * @hidden
 */
export function eventFromMessage(message, level, hint, attachStacktrace) {
    if (level === void 0) { level = Severity.Info; }
    var syntheticException = (hint && hint.syntheticException) || undefined;
    var event = eventFromString(message, syntheticException, attachStacktrace);
    event.level = level;
    if (hint && hint.event_id) {
        event.event_id = hint.event_id;
    }
    return resolvedSyncPromise(event);
}
/**
 * @hidden
 */
export function eventFromUnknownInput(exception, syntheticException, attachStacktrace, isUnhandledRejection) {
    var event;
    if (isErrorEvent(exception) && exception.error) {
        // If it is an ErrorEvent with `error` property, extract it to get actual Error
        var errorEvent = exception;
        return eventFromError(errorEvent.error);
    }
    // If it is a `DOMError` (which is a legacy API, but still supported in some browsers) then we just extract the name
    // and message, as it doesn't provide anything else. According to the spec, all `DOMExceptions` should also be
    // `Error`s, but that's not the case in IE11, so in that case we treat it the same as we do a `DOMError`.
    //
    // https://developer.mozilla.org/en-US/docs/Web/API/DOMError
    // https://developer.mozilla.org/en-US/docs/Web/API/DOMException
    // https://webidl.spec.whatwg.org/#es-DOMException-specialness
    if (isDOMError(exception) || isDOMException(exception)) {
        var domException = exception;
        if ('stack' in exception) {
            event = eventFromError(exception);
        }
        else {
            var name_1 = domException.name || (isDOMError(domException) ? 'DOMError' : 'DOMException');
            var message = domException.message ? name_1 + ": " + domException.message : name_1;
            event = eventFromString(message, syntheticException, attachStacktrace);
            addExceptionTypeValue(event, message);
        }
        if ('code' in domException) {
            event.tags = __assign(__assign({}, event.tags), { 'DOMException.code': "" + domException.code });
        }
        return event;
    }
    if (isError(exception)) {
        // we have a real Error object, do nothing
        return eventFromError(exception);
    }
    if (isPlainObject(exception) || isEvent(exception)) {
        // If it's a plain object or an instance of `Event` (the built-in JS kind, not this SDK's `Event` type), serialize
        // it manually. This will allow us to group events based on top-level keys which is much better than creating a new
        // group on any key/value change.
        var objectException = exception;
        event = eventFromPlainObject(objectException, syntheticException, isUnhandledRejection);
        addExceptionMechanism(event, {
            synthetic: true,
        });
        return event;
    }
    // If none of previous checks were valid, then it means that it's not:
    // - an instance of DOMError
    // - an instance of DOMException
    // - an instance of Event
    // - an instance of Error
    // - a valid ErrorEvent (one with an error property)
    // - a plain Object
    //
    // So bail out and capture it as a simple message:
    event = eventFromString(exception, syntheticException, attachStacktrace);
    addExceptionTypeValue(event, "" + exception, undefined);
    addExceptionMechanism(event, {
        synthetic: true,
    });
    return event;
}
/**
 * @hidden
 */
export function eventFromString(input, syntheticException, attachStacktrace) {
    var event = {
        message: input,
    };
    if (attachStacktrace && syntheticException) {
        var frames_2 = parseStackFrames(syntheticException);
        if (frames_2.length) {
            event.stacktrace = { frames: frames_2 };
        }
    }
    return event;
}
//# sourceMappingURL=eventbuilder.js.map