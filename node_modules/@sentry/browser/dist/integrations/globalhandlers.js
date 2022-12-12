Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
var core_1 = require("@sentry/core");
var types_1 = require("@sentry/types");
var utils_1 = require("@sentry/utils");
var eventbuilder_1 = require("../eventbuilder");
var flags_1 = require("../flags");
var helpers_1 = require("../helpers");
/** Global handlers */
var GlobalHandlers = /** @class */ (function () {
    /** JSDoc */
    function GlobalHandlers(options) {
        /**
         * @inheritDoc
         */
        this.name = GlobalHandlers.id;
        /**
         * Stores references functions to installing handlers. Will set to undefined
         * after they have been run so that they are not used twice.
         */
        this._installFunc = {
            onerror: _installGlobalOnErrorHandler,
            onunhandledrejection: _installGlobalOnUnhandledRejectionHandler,
        };
        this._options = tslib_1.__assign({ onerror: true, onunhandledrejection: true }, options);
    }
    /**
     * @inheritDoc
     */
    GlobalHandlers.prototype.setupOnce = function () {
        Error.stackTraceLimit = 50;
        var options = this._options;
        // We can disable guard-for-in as we construct the options object above + do checks against
        // `this._installFunc` for the property.
        // eslint-disable-next-line guard-for-in
        for (var key in options) {
            var installFunc = this._installFunc[key];
            if (installFunc && options[key]) {
                globalHandlerLog(key);
                installFunc();
                this._installFunc[key] = undefined;
            }
        }
    };
    /**
     * @inheritDoc
     */
    GlobalHandlers.id = 'GlobalHandlers';
    return GlobalHandlers;
}());
exports.GlobalHandlers = GlobalHandlers;
/** JSDoc */
function _installGlobalOnErrorHandler() {
    utils_1.addInstrumentationHandler('error', 
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function (data) {
        var _a = tslib_1.__read(getHubAndAttachStacktrace(), 2), hub = _a[0], attachStacktrace = _a[1];
        if (!hub.getIntegration(GlobalHandlers)) {
            return;
        }
        var msg = data.msg, url = data.url, line = data.line, column = data.column, error = data.error;
        if (helpers_1.shouldIgnoreOnError() || (error && error.__sentry_own_request__)) {
            return;
        }
        var event = error === undefined && utils_1.isString(msg)
            ? _eventFromIncompleteOnError(msg, url, line, column)
            : _enhanceEventWithInitialFrame(eventbuilder_1.eventFromUnknownInput(error || msg, undefined, attachStacktrace, false), url, line, column);
        event.level = types_1.Severity.Error;
        addMechanismAndCapture(hub, error, event, 'onerror');
    });
}
/** JSDoc */
function _installGlobalOnUnhandledRejectionHandler() {
    utils_1.addInstrumentationHandler('unhandledrejection', 
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function (e) {
        var _a = tslib_1.__read(getHubAndAttachStacktrace(), 2), hub = _a[0], attachStacktrace = _a[1];
        if (!hub.getIntegration(GlobalHandlers)) {
            return;
        }
        var error = e;
        // dig the object of the rejection out of known event types
        try {
            // PromiseRejectionEvents store the object of the rejection under 'reason'
            // see https://developer.mozilla.org/en-US/docs/Web/API/PromiseRejectionEvent
            if ('reason' in e) {
                error = e.reason;
            }
            // something, somewhere, (likely a browser extension) effectively casts PromiseRejectionEvents
            // to CustomEvents, moving the `promise` and `reason` attributes of the PRE into
            // the CustomEvent's `detail` attribute, since they're not part of CustomEvent's spec
            // see https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent and
            // https://github.com/getsentry/sentry-javascript/issues/2380
            else if ('detail' in e && 'reason' in e.detail) {
                error = e.detail.reason;
            }
        }
        catch (_oO) {
            // no-empty
        }
        if (helpers_1.shouldIgnoreOnError() || (error && error.__sentry_own_request__)) {
            return true;
        }
        var event = utils_1.isPrimitive(error)
            ? _eventFromRejectionWithPrimitive(error)
            : eventbuilder_1.eventFromUnknownInput(error, undefined, attachStacktrace, true);
        event.level = types_1.Severity.Error;
        addMechanismAndCapture(hub, error, event, 'onunhandledrejection');
        return;
    });
}
/**
 * Create an event from a promise rejection where the `reason` is a primitive.
 *
 * @param reason: The `reason` property of the promise rejection
 * @returns An Event object with an appropriate `exception` value
 */
function _eventFromRejectionWithPrimitive(reason) {
    return {
        exception: {
            values: [
                {
                    type: 'UnhandledRejection',
                    // String() is needed because the Primitive type includes symbols (which can't be automatically stringified)
                    value: "Non-Error promise rejection captured with value: " + String(reason),
                },
            ],
        },
    };
}
/**
 * This function creates a stack from an old, error-less onerror handler.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _eventFromIncompleteOnError(msg, url, line, column) {
    var ERROR_TYPES_RE = /^(?:[Uu]ncaught (?:exception: )?)?(?:((?:Eval|Internal|Range|Reference|Syntax|Type|URI|)Error): )?(.*)$/i;
    // If 'message' is ErrorEvent, get real message from inside
    var message = utils_1.isErrorEvent(msg) ? msg.message : msg;
    var name = 'Error';
    var groups = message.match(ERROR_TYPES_RE);
    if (groups) {
        name = groups[1];
        message = groups[2];
    }
    var event = {
        exception: {
            values: [
                {
                    type: name,
                    value: message,
                },
            ],
        },
    };
    return _enhanceEventWithInitialFrame(event, url, line, column);
}
/** JSDoc */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _enhanceEventWithInitialFrame(event, url, line, column) {
    // event.exception
    var e = (event.exception = event.exception || {});
    // event.exception.values
    var ev = (e.values = e.values || []);
    // event.exception.values[0]
    var ev0 = (ev[0] = ev[0] || {});
    // event.exception.values[0].stacktrace
    var ev0s = (ev0.stacktrace = ev0.stacktrace || {});
    // event.exception.values[0].stacktrace.frames
    var ev0sf = (ev0s.frames = ev0s.frames || []);
    var colno = isNaN(parseInt(column, 10)) ? undefined : column;
    var lineno = isNaN(parseInt(line, 10)) ? undefined : line;
    var filename = utils_1.isString(url) && url.length > 0 ? url : utils_1.getLocationHref();
    // event.exception.values[0].stacktrace.frames
    if (ev0sf.length === 0) {
        ev0sf.push({
            colno: colno,
            filename: filename,
            function: '?',
            in_app: true,
            lineno: lineno,
        });
    }
    return event;
}
function globalHandlerLog(type) {
    flags_1.IS_DEBUG_BUILD && utils_1.logger.log("Global Handler attached: " + type);
}
function addMechanismAndCapture(hub, error, event, type) {
    utils_1.addExceptionMechanism(event, {
        handled: false,
        type: type,
    });
    hub.captureEvent(event, {
        originalException: error,
    });
}
function getHubAndAttachStacktrace() {
    var hub = core_1.getCurrentHub();
    var client = hub.getClient();
    var attachStacktrace = client && client.getOptions().attachStacktrace;
    return [hub, attachStacktrace];
}
//# sourceMappingURL=globalhandlers.js.map