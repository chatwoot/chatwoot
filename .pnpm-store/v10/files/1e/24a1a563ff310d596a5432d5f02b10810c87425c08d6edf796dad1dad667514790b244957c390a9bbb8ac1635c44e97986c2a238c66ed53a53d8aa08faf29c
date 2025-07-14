Object.defineProperty(exports, '__esModule', { value: true });

const feedback = require('@sentry-internal/feedback');
const lazyLoadIntegration = require('./utils/lazyLoadIntegration.js');

/** Add a widget to capture user feedback to your application. */
const feedbackSyncIntegration = feedback.buildFeedbackIntegration({
  lazyLoadIntegration: lazyLoadIntegration.lazyLoadIntegration,
  getModalIntegration: () => feedback.feedbackModalIntegration,
  getScreenshotIntegration: () => feedback.feedbackScreenshotIntegration,
});

exports.feedbackSyncIntegration = feedbackSyncIntegration;
//# sourceMappingURL=feedbackSync.js.map
