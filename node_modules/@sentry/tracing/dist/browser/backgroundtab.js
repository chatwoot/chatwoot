Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = require("@sentry/utils");
var constants_1 = require("../constants");
var flags_1 = require("../flags");
var utils_2 = require("../utils");
var global = utils_1.getGlobalObject();
/**
 * Add a listener that cancels and finishes a transaction when the global
 * document is hidden.
 */
function registerBackgroundTabDetection() {
    if (global && global.document) {
        global.document.addEventListener('visibilitychange', function () {
            var activeTransaction = utils_2.getActiveTransaction();
            if (global.document.hidden && activeTransaction) {
                var statusType = 'cancelled';
                flags_1.IS_DEBUG_BUILD &&
                    utils_1.logger.log("[Tracing] Transaction: " + statusType + " -> since tab moved to the background, op: " + activeTransaction.op);
                // We should not set status if it is already set, this prevent important statuses like
                // error or data loss from being overwritten on transaction.
                if (!activeTransaction.status) {
                    activeTransaction.setStatus(statusType);
                }
                activeTransaction.setTag('visibilitychange', 'document.hidden');
                activeTransaction.setTag(constants_1.FINISH_REASON_TAG, constants_1.IDLE_TRANSACTION_FINISH_REASONS[2]);
                activeTransaction.finish();
            }
        });
    }
    else {
        flags_1.IS_DEBUG_BUILD && utils_1.logger.warn('[Tracing] Could not set up background tab detection due to lack of global document');
    }
}
exports.registerBackgroundTabDetection = registerBackgroundTabDetection;
//# sourceMappingURL=backgroundtab.js.map