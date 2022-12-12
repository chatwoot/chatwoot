import { addInstrumentationHandler, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from './flags';
import { getActiveTransaction } from './utils';
/**
 * Configures global error listeners
 */
export function registerErrorInstrumentation() {
    addInstrumentationHandler('error', errorCallback);
    addInstrumentationHandler('unhandledrejection', errorCallback);
}
/**
 * If an error or unhandled promise occurs, we mark the active transaction as failed
 */
function errorCallback() {
    var activeTransaction = getActiveTransaction();
    if (activeTransaction) {
        var status_1 = 'internal_error';
        IS_DEBUG_BUILD && logger.log("[Tracing] Transaction: " + status_1 + " -> Global error occured");
        activeTransaction.setStatus(status_1);
    }
}
//# sourceMappingURL=errors.js.map