import { __assign } from "tslib";
import { getGlobalObject, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from '../flags';
import { startIdleTransaction } from '../hubextensions';
import { DEFAULT_IDLE_TIMEOUT } from '../idletransaction';
import { extractTraceparentData, secToMs } from '../utils';
import { registerBackgroundTabDetection } from './backgroundtab';
import { MetricsInstrumentation } from './metrics';
import { defaultRequestInstrumentationOptions, instrumentOutgoingRequests, } from './request';
import { instrumentRoutingWithDefaults } from './router';
export var DEFAULT_MAX_TRANSACTION_DURATION_SECONDS = 600;
var DEFAULT_BROWSER_TRACING_OPTIONS = __assign({ idleTimeout: DEFAULT_IDLE_TIMEOUT, markBackgroundTransactions: true, maxTransactionDuration: DEFAULT_MAX_TRANSACTION_DURATION_SECONDS, routingInstrumentation: instrumentRoutingWithDefaults, startTransactionOnLocationChange: true, startTransactionOnPageLoad: true }, defaultRequestInstrumentationOptions);
/**
 * The Browser Tracing integration automatically instruments browser pageload/navigation
 * actions as transactions, and captures requests, metrics and errors as spans.
 *
 * The integration can be configured with a variety of options, and can be extended to use
 * any routing library. This integration uses {@see IdleTransaction} to create transactions.
 */
var BrowserTracing = /** @class */ (function () {
    function BrowserTracing(_options) {
        /**
         * @inheritDoc
         */
        this.name = BrowserTracing.id;
        /** Store configured idle timeout so that it can be added as a tag to transactions */
        this._configuredIdleTimeout = undefined;
        var tracingOrigins = defaultRequestInstrumentationOptions.tracingOrigins;
        // NOTE: Logger doesn't work in constructors, as it's initialized after integrations instances
        if (_options) {
            this._configuredIdleTimeout = _options.idleTimeout;
            if (_options.tracingOrigins && Array.isArray(_options.tracingOrigins) && _options.tracingOrigins.length !== 0) {
                tracingOrigins = _options.tracingOrigins;
            }
            else {
                IS_DEBUG_BUILD && (this._emitOptionsWarning = true);
            }
        }
        this.options = __assign(__assign(__assign({}, DEFAULT_BROWSER_TRACING_OPTIONS), _options), { tracingOrigins: tracingOrigins });
        var _metricOptions = this.options._metricOptions;
        this._metrics = new MetricsInstrumentation(_metricOptions && _metricOptions._reportAllChanges);
    }
    /**
     * @inheritDoc
     */
    BrowserTracing.prototype.setupOnce = function (_, getCurrentHub) {
        var _this = this;
        this._getCurrentHub = getCurrentHub;
        if (this._emitOptionsWarning) {
            IS_DEBUG_BUILD &&
                logger.warn('[Tracing] You need to define `tracingOrigins` in the options. Set an array of urls or patterns to trace.');
            IS_DEBUG_BUILD &&
                logger.warn("[Tracing] We added a reasonable default for you: " + defaultRequestInstrumentationOptions.tracingOrigins);
        }
        // eslint-disable-next-line @typescript-eslint/unbound-method
        var _a = this.options, instrumentRouting = _a.routingInstrumentation, startTransactionOnLocationChange = _a.startTransactionOnLocationChange, startTransactionOnPageLoad = _a.startTransactionOnPageLoad, markBackgroundTransactions = _a.markBackgroundTransactions, traceFetch = _a.traceFetch, traceXHR = _a.traceXHR, tracingOrigins = _a.tracingOrigins, shouldCreateSpanForRequest = _a.shouldCreateSpanForRequest;
        instrumentRouting(function (context) { return _this._createRouteTransaction(context); }, startTransactionOnPageLoad, startTransactionOnLocationChange);
        if (markBackgroundTransactions) {
            registerBackgroundTabDetection();
        }
        instrumentOutgoingRequests({ traceFetch: traceFetch, traceXHR: traceXHR, tracingOrigins: tracingOrigins, shouldCreateSpanForRequest: shouldCreateSpanForRequest });
    };
    /** Create routing idle transaction. */
    BrowserTracing.prototype._createRouteTransaction = function (context) {
        var _this = this;
        if (!this._getCurrentHub) {
            IS_DEBUG_BUILD &&
                logger.warn("[Tracing] Did not create " + context.op + " transaction because _getCurrentHub is invalid.");
            return undefined;
        }
        // eslint-disable-next-line @typescript-eslint/unbound-method
        var _a = this.options, beforeNavigate = _a.beforeNavigate, idleTimeout = _a.idleTimeout, maxTransactionDuration = _a.maxTransactionDuration;
        var parentContextFromHeader = context.op === 'pageload' ? getHeaderContext() : undefined;
        var expandedContext = __assign(__assign(__assign({}, context), parentContextFromHeader), { trimEnd: true });
        var modifiedContext = typeof beforeNavigate === 'function' ? beforeNavigate(expandedContext) : expandedContext;
        // For backwards compatibility reasons, beforeNavigate can return undefined to "drop" the transaction (prevent it
        // from being sent to Sentry).
        var finalContext = modifiedContext === undefined ? __assign(__assign({}, expandedContext), { sampled: false }) : modifiedContext;
        if (finalContext.sampled === false) {
            IS_DEBUG_BUILD && logger.log("[Tracing] Will not send " + finalContext.op + " transaction because of beforeNavigate.");
        }
        IS_DEBUG_BUILD && logger.log("[Tracing] Starting " + finalContext.op + " transaction on scope");
        var hub = this._getCurrentHub();
        var location = getGlobalObject().location;
        var idleTransaction = startIdleTransaction(hub, finalContext, idleTimeout, true, { location: location });
        idleTransaction.registerBeforeFinishCallback(function (transaction, endTimestamp) {
            _this._metrics.addPerformanceEntries(transaction);
            adjustTransactionDuration(secToMs(maxTransactionDuration), transaction, endTimestamp);
        });
        idleTransaction.setTag('idleTimeout', this._configuredIdleTimeout);
        return idleTransaction;
    };
    /**
     * @inheritDoc
     */
    BrowserTracing.id = 'BrowserTracing';
    return BrowserTracing;
}());
export { BrowserTracing };
/**
 * Gets transaction context from a sentry-trace meta.
 *
 * @returns Transaction context data from the header or undefined if there's no header or the header is malformed
 */
export function getHeaderContext() {
    var header = getMetaContent('sentry-trace');
    if (header) {
        return extractTraceparentData(header);
    }
    return undefined;
}
/** Returns the value of a meta tag */
export function getMetaContent(metaName) {
    var el = getGlobalObject().document.querySelector("meta[name=" + metaName + "]");
    return el ? el.getAttribute('content') : null;
}
/** Adjusts transaction value based on max transaction duration */
function adjustTransactionDuration(maxDuration, transaction, endTimestamp) {
    var diff = endTimestamp - transaction.startTimestamp;
    var isOutdatedTransaction = endTimestamp && (diff > maxDuration || diff < 0);
    if (isOutdatedTransaction) {
        transaction.setStatus('deadline_exceeded');
        transaction.setTag('maxTransactionDurationExceeded', 'true');
    }
}
//# sourceMappingURL=browsertracing.js.map