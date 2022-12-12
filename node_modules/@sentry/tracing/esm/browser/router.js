import { addInstrumentationHandler, getGlobalObject, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from '../flags';
var global = getGlobalObject();
/**
 * Default function implementing pageload and navigation transactions
 */
export function instrumentRoutingWithDefaults(customStartTransaction, startTransactionOnPageLoad, startTransactionOnLocationChange) {
    if (startTransactionOnPageLoad === void 0) { startTransactionOnPageLoad = true; }
    if (startTransactionOnLocationChange === void 0) { startTransactionOnLocationChange = true; }
    if (!global || !global.location) {
        IS_DEBUG_BUILD && logger.warn('Could not initialize routing instrumentation due to invalid location');
        return;
    }
    var startingUrl = global.location.href;
    var activeTransaction;
    if (startTransactionOnPageLoad) {
        activeTransaction = customStartTransaction({ name: global.location.pathname, op: 'pageload' });
    }
    if (startTransactionOnLocationChange) {
        addInstrumentationHandler('history', function (_a) {
            var to = _a.to, from = _a.from;
            /**
             * This early return is there to account for some cases where a navigation transaction starts right after
             * long-running pageload. We make sure that if `from` is undefined and a valid `startingURL` exists, we don't
             * create an uneccessary navigation transaction.
             *
             * This was hard to duplicate, but this behavior stopped as soon as this fix was applied. This issue might also
             * only be caused in certain development environments where the usage of a hot module reloader is causing
             * errors.
             */
            if (from === undefined && startingUrl && startingUrl.indexOf(to) !== -1) {
                startingUrl = undefined;
                return;
            }
            if (from !== to) {
                startingUrl = undefined;
                if (activeTransaction) {
                    IS_DEBUG_BUILD && logger.log("[Tracing] Finishing current transaction with op: " + activeTransaction.op);
                    // If there's an open transaction on the scope, we need to finish it before creating an new one.
                    activeTransaction.finish();
                }
                activeTransaction = customStartTransaction({ name: global.location.pathname, op: 'navigation' });
            }
        });
    }
}
//# sourceMappingURL=router.js.map