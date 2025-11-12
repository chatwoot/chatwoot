import { BaseClient, applySdkMetadata } from '@sentry/core';
import { getSDKSource, logger } from '@sentry/utils';
import { DEBUG_BUILD } from './debug-build.js';
import { eventFromException, eventFromMessage } from './eventbuilder.js';
import { WINDOW } from './helpers.js';
import { createUserFeedbackEnvelope } from './userfeedback.js';

/**
 * Configuration options for the Sentry Browser SDK.
 * @see @sentry/types Options for more information.
 */

/**
 * The Sentry Browser SDK Client.
 *
 * @see BrowserOptions for documentation on configuration options.
 * @see SentryClient for usage documentation.
 */
class BrowserClient extends BaseClient {
  /**
   * Creates a new Browser SDK instance.
   *
   * @param options Configuration options for this SDK.
   */
   constructor(options) {
    const opts = {
      // We default this to true, as it is the safer scenario
      parentSpanIsAlwaysRootSpan: true,
      ...options,
    };
    const sdkSource = WINDOW.SENTRY_SDK_SOURCE || getSDKSource();
    applySdkMetadata(opts, 'browser', ['browser'], sdkSource);

    super(opts);

    if (opts.sendClientReports && WINDOW.document) {
      WINDOW.document.addEventListener('visibilitychange', () => {
        if (WINDOW.document.visibilityState === 'hidden') {
          this._flushOutcomes();
        }
      });
    }
  }

  /**
   * @inheritDoc
   */
   eventFromException(exception, hint) {
    return eventFromException(this._options.stackParser, exception, hint, this._options.attachStacktrace);
  }

  /**
   * @inheritDoc
   */
   eventFromMessage(
    message,
    level = 'info',
    hint,
  ) {
    return eventFromMessage(this._options.stackParser, message, level, hint, this._options.attachStacktrace);
  }

  /**
   * Sends user feedback to Sentry.
   *
   * @deprecated Use `captureFeedback` instead.
   */
   captureUserFeedback(feedback) {
    if (!this._isEnabled()) {
      DEBUG_BUILD && logger.warn('SDK not enabled, will not capture user feedback.');
      return;
    }

    const envelope = createUserFeedbackEnvelope(feedback, {
      metadata: this.getSdkMetadata(),
      dsn: this.getDsn(),
      tunnel: this.getOptions().tunnel,
    });

    // sendEnvelope should not throw
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    this.sendEnvelope(envelope);
  }

  /**
   * @inheritDoc
   */
   _prepareEvent(event, hint, scope) {
    event.platform = event.platform || 'javascript';
    return super._prepareEvent(event, hint, scope);
  }
}

export { BrowserClient };
//# sourceMappingURL=client.js.map
