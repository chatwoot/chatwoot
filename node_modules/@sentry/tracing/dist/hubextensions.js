Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var hub_1 = require("@sentry/hub");
var utils_1 = require("@sentry/utils");
var errors_1 = require("./errors");
var flags_1 = require("./flags");
var idletransaction_1 = require("./idletransaction");
var transaction_1 = require("./transaction");
var utils_2 = require("./utils");
/** Returns all trace headers that are currently on the top scope. */
function traceHeaders() {
    var scope = this.getScope();
    if (scope) {
        var span = scope.getSpan();
        if (span) {
            return {
                'sentry-trace': span.toTraceparent(),
            };
        }
    }
    return {};
}
/**
 * Makes a sampling decision for the given transaction and stores it on the transaction.
 *
 * Called every time a transaction is created. Only transactions which emerge with a `sampled` value of `true` will be
 * sent to Sentry.
 *
 * @param transaction: The transaction needing a sampling decision
 * @param options: The current client's options, so we can access `tracesSampleRate` and/or `tracesSampler`
 * @param samplingContext: Default and user-provided data which may be used to help make the decision
 *
 * @returns The given transaction with its `sampled` value set
 */
function sample(transaction, options, samplingContext) {
    // nothing to do if tracing is not enabled
    if (!utils_2.hasTracingEnabled(options)) {
        transaction.sampled = false;
        return transaction;
    }
    // if the user has forced a sampling decision by passing a `sampled` value in their transaction context, go with that
    if (transaction.sampled !== undefined) {
        transaction.setMetadata({
            transactionSampling: { method: 'explicitly_set' },
        });
        return transaction;
    }
    // we would have bailed already if neither `tracesSampler` nor `tracesSampleRate` were defined, so one of these should
    // work; prefer the hook if so
    var sampleRate;
    if (typeof options.tracesSampler === 'function') {
        sampleRate = options.tracesSampler(samplingContext);
        transaction.setMetadata({
            transactionSampling: {
                method: 'client_sampler',
                // cast to number in case it's a boolean
                rate: Number(sampleRate),
            },
        });
    }
    else if (samplingContext.parentSampled !== undefined) {
        sampleRate = samplingContext.parentSampled;
        transaction.setMetadata({
            transactionSampling: { method: 'inheritance' },
        });
    }
    else {
        sampleRate = options.tracesSampleRate;
        transaction.setMetadata({
            transactionSampling: {
                method: 'client_rate',
                // cast to number in case it's a boolean
                rate: Number(sampleRate),
            },
        });
    }
    // Since this is coming from the user (or from a function provided by the user), who knows what we might get. (The
    // only valid values are booleans or numbers between 0 and 1.)
    if (!isValidSampleRate(sampleRate)) {
        flags_1.IS_DEBUG_BUILD && utils_1.logger.warn('[Tracing] Discarding transaction because of invalid sample rate.');
        transaction.sampled = false;
        return transaction;
    }
    // if the function returned 0 (or false), or if `tracesSampleRate` is 0, it's a sign the transaction should be dropped
    if (!sampleRate) {
        flags_1.IS_DEBUG_BUILD &&
            utils_1.logger.log("[Tracing] Discarding transaction because " + (typeof options.tracesSampler === 'function'
                ? 'tracesSampler returned 0 or false'
                : 'a negative sampling decision was inherited or tracesSampleRate is set to 0'));
        transaction.sampled = false;
        return transaction;
    }
    // Now we roll the dice. Math.random is inclusive of 0, but not of 1, so strict < is safe here. In case sampleRate is
    // a boolean, the < comparison will cause it to be automatically cast to 1 if it's true and 0 if it's false.
    transaction.sampled = Math.random() < sampleRate;
    // if we're not going to keep it, we're done
    if (!transaction.sampled) {
        flags_1.IS_DEBUG_BUILD &&
            utils_1.logger.log("[Tracing] Discarding transaction because it's not included in the random sample (sampling rate = " + Number(sampleRate) + ")");
        return transaction;
    }
    flags_1.IS_DEBUG_BUILD && utils_1.logger.log("[Tracing] starting " + transaction.op + " transaction - " + transaction.name);
    return transaction;
}
/**
 * Checks the given sample rate to make sure it is valid type and value (a boolean, or a number between 0 and 1).
 */
function isValidSampleRate(rate) {
    // we need to check NaN explicitly because it's of type 'number' and therefore wouldn't get caught by this typecheck
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if (utils_1.isNaN(rate) || !(typeof rate === 'number' || typeof rate === 'boolean')) {
        flags_1.IS_DEBUG_BUILD &&
            utils_1.logger.warn("[Tracing] Given sample rate is invalid. Sample rate must be a boolean or a number between 0 and 1. Got " + JSON.stringify(rate) + " of type " + JSON.stringify(typeof rate) + ".");
        return false;
    }
    // in case sampleRate is a boolean, it will get automatically cast to 1 if it's true and 0 if it's false
    if (rate < 0 || rate > 1) {
        flags_1.IS_DEBUG_BUILD &&
            utils_1.logger.warn("[Tracing] Given sample rate is invalid. Sample rate must be between 0 and 1. Got " + rate + ".");
        return false;
    }
    return true;
}
/**
 * Creates a new transaction and adds a sampling decision if it doesn't yet have one.
 *
 * The Hub.startTransaction method delegates to this method to do its work, passing the Hub instance in as `this`, as if
 * it had been called on the hub directly. Exists as a separate function so that it can be injected into the class as an
 * "extension method."
 *
 * @param this: The Hub starting the transaction
 * @param transactionContext: Data used to configure the transaction
 * @param CustomSamplingContext: Optional data to be provided to the `tracesSampler` function (if any)
 *
 * @returns The new transaction
 *
 * @see {@link Hub.startTransaction}
 */
function _startTransaction(transactionContext, customSamplingContext) {
    var client = this.getClient();
    var options = (client && client.getOptions()) || {};
    var transaction = new transaction_1.Transaction(transactionContext, this);
    transaction = sample(transaction, options, tslib_1.__assign({ parentSampled: transactionContext.parentSampled, transactionContext: transactionContext }, customSamplingContext));
    if (transaction.sampled) {
        transaction.initSpanRecorder(options._experiments && options._experiments.maxSpans);
    }
    return transaction;
}
/**
 * Create new idle transaction.
 */
function startIdleTransaction(hub, transactionContext, idleTimeout, onScope, customSamplingContext) {
    var client = hub.getClient();
    var options = (client && client.getOptions()) || {};
    var transaction = new idletransaction_1.IdleTransaction(transactionContext, hub, idleTimeout, onScope);
    transaction = sample(transaction, options, tslib_1.__assign({ parentSampled: transactionContext.parentSampled, transactionContext: transactionContext }, customSamplingContext));
    if (transaction.sampled) {
        transaction.initSpanRecorder(options._experiments && options._experiments.maxSpans);
    }
    return transaction;
}
exports.startIdleTransaction = startIdleTransaction;
/**
 * @private
 */
function _addTracingExtensions() {
    var carrier = hub_1.getMainCarrier();
    if (!carrier.__SENTRY__) {
        return;
    }
    carrier.__SENTRY__.extensions = carrier.__SENTRY__.extensions || {};
    if (!carrier.__SENTRY__.extensions.startTransaction) {
        carrier.__SENTRY__.extensions.startTransaction = _startTransaction;
    }
    if (!carrier.__SENTRY__.extensions.traceHeaders) {
        carrier.__SENTRY__.extensions.traceHeaders = traceHeaders;
    }
}
exports._addTracingExtensions = _addTracingExtensions;
/**
 * @private
 */
function _autoloadDatabaseIntegrations() {
    var carrier = hub_1.getMainCarrier();
    if (!carrier.__SENTRY__) {
        return;
    }
    var packageToIntegrationMapping = {
        mongodb: function () {
            var integration = utils_1.dynamicRequire(module, './integrations/node/mongo');
            return new integration.Mongo();
        },
        mongoose: function () {
            var integration = utils_1.dynamicRequire(module, './integrations/node/mongo');
            return new integration.Mongo({ mongoose: true });
        },
        mysql: function () {
            var integration = utils_1.dynamicRequire(module, './integrations/node/mysql');
            return new integration.Mysql();
        },
        pg: function () {
            var integration = utils_1.dynamicRequire(module, './integrations/node/postgres');
            return new integration.Postgres();
        },
    };
    var mappedPackages = Object.keys(packageToIntegrationMapping)
        .filter(function (moduleName) { return !!utils_1.loadModule(moduleName); })
        .map(function (pkg) {
        try {
            return packageToIntegrationMapping[pkg]();
        }
        catch (e) {
            return undefined;
        }
    })
        .filter(function (p) { return p; });
    if (mappedPackages.length > 0) {
        carrier.__SENTRY__.integrations = tslib_1.__spread((carrier.__SENTRY__.integrations || []), mappedPackages);
    }
}
/**
 * This patches the global object and injects the Tracing extensions methods
 */
function addExtensionMethods() {
    _addTracingExtensions();
    // Detect and automatically load specified integrations.
    if (utils_1.isNodeEnv()) {
        _autoloadDatabaseIntegrations();
    }
    // If an error happens globally, we should make sure transaction status is set to error.
    errors_1.registerErrorInstrumentation();
}
exports.addExtensionMethods = addExtensionMethods;
//# sourceMappingURL=hubextensions.js.map