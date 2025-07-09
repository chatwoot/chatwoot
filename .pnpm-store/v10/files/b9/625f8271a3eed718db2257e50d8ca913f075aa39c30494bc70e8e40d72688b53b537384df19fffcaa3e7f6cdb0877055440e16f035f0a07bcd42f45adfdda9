import { getActiveSpan, getRootSpan, spanToJSON, SPAN_STATUS_ERROR } from '@sentry/core';
import { logger } from '@sentry/utils';
import { DEBUG_BUILD } from '../debug-build.js';
import { WINDOW } from '../helpers.js';

/**
 * Add a listener that cancels and finishes a transaction when the global
 * document is hidden.
 */
function registerBackgroundTabDetection() {
  if (WINDOW && WINDOW.document) {
    WINDOW.document.addEventListener('visibilitychange', () => {
      const activeSpan = getActiveSpan();
      if (!activeSpan) {
        return;
      }

      const rootSpan = getRootSpan(activeSpan);

      if (WINDOW.document.hidden && rootSpan) {
        const cancelledStatus = 'cancelled';

        const { op, status } = spanToJSON(rootSpan);

        if (DEBUG_BUILD) {
          logger.log(`[Tracing] Transaction: ${cancelledStatus} -> since tab moved to the background, op: ${op}`);
        }

        // We should not set status if it is already set, this prevent important statuses like
        // error or data loss from being overwritten on transaction.
        if (!status) {
          rootSpan.setStatus({ code: SPAN_STATUS_ERROR, message: cancelledStatus });
        }

        rootSpan.setAttribute('sentry.cancellation_reason', 'document.hidden');
        rootSpan.end();
      }
    });
  } else {
    DEBUG_BUILD && logger.warn('[Tracing] Could not set up background tab detection due to lack of global document');
  }
}

export { registerBackgroundTabDetection };
//# sourceMappingURL=backgroundtab.js.map
