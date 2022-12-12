import { __read, __spread } from "tslib";
import { getEventDescription, isMatchingPattern, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from '../flags';
// "Script error." is hard coded into browsers for errors that it can't read.
// this is the result of a script being pulled in from an external domain and CORS.
var DEFAULT_IGNORE_ERRORS = [/^Script error\.?$/, /^Javascript error: Script error\.? on line 0$/];
/** Inbound filters configurable by the user */
var InboundFilters = /** @class */ (function () {
    function InboundFilters(_options) {
        if (_options === void 0) { _options = {}; }
        this._options = _options;
        /**
         * @inheritDoc
         */
        this.name = InboundFilters.id;
    }
    /**
     * @inheritDoc
     */
    InboundFilters.prototype.setupOnce = function (addGlobalEventProcessor, getCurrentHub) {
        addGlobalEventProcessor(function (event) {
            var hub = getCurrentHub();
            if (hub) {
                var self_1 = hub.getIntegration(InboundFilters);
                if (self_1) {
                    var client = hub.getClient();
                    var clientOptions = client ? client.getOptions() : {};
                    var options = _mergeOptions(self_1._options, clientOptions);
                    return _shouldDropEvent(event, options) ? null : event;
                }
            }
            return event;
        });
    };
    /**
     * @inheritDoc
     */
    InboundFilters.id = 'InboundFilters';
    return InboundFilters;
}());
export { InboundFilters };
/** JSDoc */
export function _mergeOptions(internalOptions, clientOptions) {
    if (internalOptions === void 0) { internalOptions = {}; }
    if (clientOptions === void 0) { clientOptions = {}; }
    return {
        allowUrls: __spread((internalOptions.whitelistUrls || []), (internalOptions.allowUrls || []), (clientOptions.whitelistUrls || []), (clientOptions.allowUrls || [])),
        denyUrls: __spread((internalOptions.blacklistUrls || []), (internalOptions.denyUrls || []), (clientOptions.blacklistUrls || []), (clientOptions.denyUrls || [])),
        ignoreErrors: __spread((internalOptions.ignoreErrors || []), (clientOptions.ignoreErrors || []), DEFAULT_IGNORE_ERRORS),
        ignoreInternal: internalOptions.ignoreInternal !== undefined ? internalOptions.ignoreInternal : true,
    };
}
/** JSDoc */
export function _shouldDropEvent(event, options) {
    if (options.ignoreInternal && _isSentryError(event)) {
        IS_DEBUG_BUILD &&
            logger.warn("Event dropped due to being internal Sentry Error.\nEvent: " + getEventDescription(event));
        return true;
    }
    if (_isIgnoredError(event, options.ignoreErrors)) {
        IS_DEBUG_BUILD &&
            logger.warn("Event dropped due to being matched by `ignoreErrors` option.\nEvent: " + getEventDescription(event));
        return true;
    }
    if (_isDeniedUrl(event, options.denyUrls)) {
        IS_DEBUG_BUILD &&
            logger.warn("Event dropped due to being matched by `denyUrls` option.\nEvent: " + getEventDescription(event) + ".\nUrl: " + _getEventFilterUrl(event));
        return true;
    }
    if (!_isAllowedUrl(event, options.allowUrls)) {
        IS_DEBUG_BUILD &&
            logger.warn("Event dropped due to not being matched by `allowUrls` option.\nEvent: " + getEventDescription(event) + ".\nUrl: " + _getEventFilterUrl(event));
        return true;
    }
    return false;
}
function _isIgnoredError(event, ignoreErrors) {
    if (!ignoreErrors || !ignoreErrors.length) {
        return false;
    }
    return _getPossibleEventMessages(event).some(function (message) {
        return ignoreErrors.some(function (pattern) { return isMatchingPattern(message, pattern); });
    });
}
function _isDeniedUrl(event, denyUrls) {
    // TODO: Use Glob instead?
    if (!denyUrls || !denyUrls.length) {
        return false;
    }
    var url = _getEventFilterUrl(event);
    return !url ? false : denyUrls.some(function (pattern) { return isMatchingPattern(url, pattern); });
}
function _isAllowedUrl(event, allowUrls) {
    // TODO: Use Glob instead?
    if (!allowUrls || !allowUrls.length) {
        return true;
    }
    var url = _getEventFilterUrl(event);
    return !url ? true : allowUrls.some(function (pattern) { return isMatchingPattern(url, pattern); });
}
function _getPossibleEventMessages(event) {
    if (event.message) {
        return [event.message];
    }
    if (event.exception) {
        try {
            var _a = (event.exception.values && event.exception.values[0]) || {}, _b = _a.type, type = _b === void 0 ? '' : _b, _c = _a.value, value = _c === void 0 ? '' : _c;
            return ["" + value, type + ": " + value];
        }
        catch (oO) {
            IS_DEBUG_BUILD && logger.error("Cannot extract message for event " + getEventDescription(event));
            return [];
        }
    }
    return [];
}
function _isSentryError(event) {
    try {
        // @ts-ignore can't be a sentry error if undefined
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        return event.exception.values[0].type === 'SentryError';
    }
    catch (e) {
        // ignore
    }
    return false;
}
function _getLastValidUrl(frames) {
    if (frames === void 0) { frames = []; }
    for (var i = frames.length - 1; i >= 0; i--) {
        var frame = frames[i];
        if (frame && frame.filename !== '<anonymous>' && frame.filename !== '[native code]') {
            return frame.filename || null;
        }
    }
    return null;
}
function _getEventFilterUrl(event) {
    try {
        if (event.stacktrace) {
            return _getLastValidUrl(event.stacktrace.frames);
        }
        var frames_1;
        try {
            // @ts-ignore we only care about frames if the whole thing here is defined
            frames_1 = event.exception.values[0].stacktrace.frames;
        }
        catch (e) {
            // ignore
        }
        return frames_1 ? _getLastValidUrl(frames_1) : null;
    }
    catch (oO) {
        IS_DEBUG_BUILD && logger.error("Cannot extract url for event " + getEventDescription(event));
        return null;
    }
}
//# sourceMappingURL=inboundfilters.js.map