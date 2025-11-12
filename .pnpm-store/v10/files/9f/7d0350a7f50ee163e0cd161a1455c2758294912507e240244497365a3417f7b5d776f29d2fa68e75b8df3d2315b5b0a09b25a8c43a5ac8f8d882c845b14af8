Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils = require('@sentry/utils');
const debugBuild = require('./debug-build.js');
const eventbuilder = require('./eventbuilder.js');
const helpers = require('./helpers.js');
const userfeedback = require('./userfeedback.js');

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
class BrowserClient extends core.BaseClient {
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
    const sdkSource = helpers.WINDOW.SENTRY_SDK_SOURCE || utils.getSDKSource();
    core.applySdkMetadata(opts, 'browser', ['browser'], sdkSource);

    super(opts);

    if (opts.sendClientReports && helpers.WINDOW.document) {
      helpers.WINDOW.document.addEventListener('visibilitychange', () => {
        if (helpers.WINDOW.document.visibilityState === 'hidden') {
          this._flushOutcomes();
        }
      });
    }
  }

  /**
   * @inheritDoc
   */
   eventFromException(exception, hint) {
    return eventbuilder.eventFromException(this._options.stackParser, exception, hint, this._options.attachStacktrace);
  }

  /**
   * @inheritDoc
   */
   eventFromMessage(
    message,
    level = 'info',
    hint,
  ) {
    return eventbuilder.eventFromMessage(this._options.stackParser, message, level, hint, this._options.attachStacktrace);
  }

  /**
   * Sends user feedback to Sentry.
   *
   * @deprecated Use `captureFeedback` instead.
   */
   captureUserFeedback(feedback) {
    if (!this._isEnabled()) {
      debugBuild.DEBUG_BUILD && utils.logger.warn('SDK not enabled, will not capture user feedback.');
      return;
    }

    const envelope = userfeedback.createUserFeedbackEnvelope(feedback, {
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

exports.BrowserClient = BrowserClient;
//# sourceMappingURL=client.js.map
