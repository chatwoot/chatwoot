Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = require("@sentry/utils");
var flags_1 = require("./flags");
var utils_2 = require("./utils");
/**
 * Configures global error listeners
 */
function registerErrorInstrumentation() {
    utils_1.addInstrumentationHandler('error', errorCallback);
    utils_1.addInstrumentationHandler('unhandledrejection', errorCallback);
}
exports.registerErrorInstrumentation = registerErrorInstrumentation;
/**
 * If an error or unhandled promise occurs, we mark the active transaction as failed
 */
function errorCallback() {
    var activeTransaction = utils_2.getActiveTransaction();
    if (activeTransaction) {
        var status_1 = 'internal_error';
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log("[Tracing] Transaction: " + status_1 + " -> Global error occured");
        activeTransaction.setStatus(status_1);
    }
}
//# sourceMappingURL=errors.js.map