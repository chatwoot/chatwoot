import { __assign } from "tslib";
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable max-lines */
import { getCurrentHub } from '@sentry/core';
import { Severity } from '@sentry/types';
import { addInstrumentationHandler, getEventDescription, getGlobalObject, htmlTreeAsString, parseUrl, safeJoin, severityFromString, } from '@sentry/utils';
/**
 * Default Breadcrumbs instrumentations
 * TODO: Deprecated - with v6, this will be renamed to `Instrument`
 */
var Breadcrumbs = /** @class */ (function () {
    /**
     * @inheritDoc
     */
    function Breadcrumbs(options) {
        /**
         * @inheritDoc
         */
        this.name = Breadcrumbs.id;
        this._options = __assign({ console: true, dom: true, fetch: true, history: true, sentry: true, xhr: true }, options);
    }
    /**
     * Create a breadcrumb of `sentry` from the events themselves
     */
    Breadcrumbs.prototype.addSentryBreadcrumb = function (event) {
        if (!this._options.sentry) {
            return;
        }
        getCurrentHub().addBreadcrumb({
            category: "sentry." + (event.type === 'transaction' ? 'transaction' : 'event'),
            event_id: event.event_id,
            level: event.level,
            message: getEventDescription(event),
        }, {
            event: event,
        });
    };
    /**
     * Instrument browser built-ins w/ breadcrumb capturing
     *  - Console API
     *  - DOM API (click/typing)
     *  - XMLHttpRequest API
     *  - Fetch API
     *  - History API
     */
    Breadcrumbs.prototype.setupOnce = function () {
        if (this._options.console) {
            addInstrumentationHandler('console', _consoleBreadcrumb);
        }
        if (this._options.dom) {
            addInstrumentationHandler('dom', _domBreadcrumb(this._options.dom));
        }
        if (this._options.xhr) {
            addInstrumentationHandler('xhr', _xhrBreadcrumb);
        }
        if (this._options.fetch) {
            addInstrumentationHandler('fetch', _fetchBreadcrumb);
        }
        if (this._options.history) {
            addInstrumentationHandler('history', _historyBreadcrumb);
        }
    };
    /**
     * @inheritDoc
     */
    Breadcrumbs.id = 'Breadcrumbs';
    return Breadcrumbs;
}());
export { Breadcrumbs };
/**
 * A HOC that creaes a function that creates breadcrumbs from DOM API calls.
 * This is a HOC so that we get access to dom options in the closure.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _domBreadcrumb(dom) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _innerDomBreadcrumb(handlerData) {
        var target;
        var keyAttrs = typeof dom === 'object' ? dom.serializeAttribute : undefined;
        if (typeof keyAttrs === 'string') {
            keyAttrs = [keyAttrs];
        }
        // Accessing event.target can throw (see getsentry/raven-js#838, #768)
        try {
            target = handlerData.event.target
                ? htmlTreeAsString(handlerData.event.target, keyAttrs)
                : htmlTreeAsString(handlerData.event, keyAttrs);
        }
        catch (e) {
            target = '<unknown>';
        }
        if (target.length === 0) {
            return;
        }
        getCurrentHub().addBreadcrumb({
            category: "ui." + handlerData.name,
            message: target,
        }, {
            event: handlerData.event,
            name: handlerData.name,
            global: handlerData.global,
        });
    }
    return _innerDomBreadcrumb;
}
/**
 * Creates breadcrumbs from console API calls
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _consoleBreadcrumb(handlerData) {
    var breadcrumb = {
        category: 'console',
        data: {
            arguments: handlerData.args,
            logger: 'console',
        },
        level: severityFromString(handlerData.level),
        message: safeJoin(handlerData.args, ' '),
    };
    if (handlerData.level === 'assert') {
        if (handlerData.args[0] === false) {
            breadcrumb.message = "Assertion failed: " + (safeJoin(handlerData.args.slice(1), ' ') || 'console.assert');
            breadcrumb.data.arguments = handlerData.args.slice(1);
        }
        else {
            // Don't capture a breadcrumb for passed assertions
            return;
        }
    }
    getCurrentHub().addBreadcrumb(breadcrumb, {
        input: handlerData.args,
        level: handlerData.level,
    });
}
/**
 * Creates breadcrumbs from XHR API calls
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _xhrBreadcrumb(handlerData) {
    if (handlerData.endTimestamp) {
        // We only capture complete, non-sentry requests
        if (handlerData.xhr.__sentry_own_request__) {
            return;
        }
        var _a = handlerData.xhr.__sentry_xhr__ || {}, method = _a.method, url = _a.url, status_code = _a.status_code, body = _a.body;
        getCurrentHub().addBreadcrumb({
            category: 'xhr',
            data: {
                method: method,
                url: url,
                status_code: status_code,
            },
            type: 'http',
        }, {
            xhr: handlerData.xhr,
            input: body,
        });
        return;
    }
}
/**
 * Creates breadcrumbs from fetch API calls
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _fetchBreadcrumb(handlerData) {
    // We only capture complete fetch requests
    if (!handlerData.endTimestamp) {
        return;
    }
    if (handlerData.fetchData.url.match(/sentry_key/) && handlerData.fetchData.method === 'POST') {
        // We will not create breadcrumbs for fetch requests that contain `sentry_key` (internal sentry requests)
        return;
    }
    if (handlerData.error) {
        getCurrentHub().addBreadcrumb({
            category: 'fetch',
            data: handlerData.fetchData,
            level: Severity.Error,
            type: 'http',
        }, {
            data: handlerData.error,
            input: handlerData.args,
        });
    }
    else {
        getCurrentHub().addBreadcrumb({
            category: 'fetch',
            data: __assign(__assign({}, handlerData.fetchData), { status_code: handlerData.response.status }),
            type: 'http',
        }, {
            input: handlerData.args,
            response: handlerData.response,
        });
    }
}
/**
 * Creates breadcrumbs from history API calls
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _historyBreadcrumb(handlerData) {
    var global = getGlobalObject();
    var from = handlerData.from;
    var to = handlerData.to;
    var parsedLoc = parseUrl(global.location.href);
    var parsedFrom = parseUrl(from);
    var parsedTo = parseUrl(to);
    // Initial pushState doesn't provide `from` information
    if (!parsedFrom.path) {
        parsedFrom = parsedLoc;
    }
    // Use only the path component of the URL if the URL matches the current
    // document (almost all the time when using pushState)
    if (parsedLoc.protocol === parsedTo.protocol && parsedLoc.host === parsedTo.host) {
        to = parsedTo.relative;
    }
    if (parsedLoc.protocol === parsedFrom.protocol && parsedLoc.host === parsedFrom.host) {
        from = parsedFrom.relative;
    }
    getCurrentHub().addBreadcrumb({
        category: 'navigation',
        data: {
            from: from,
            to: to,
        },
    });
}
//# sourceMappingURL=breadcrumbs.js.map