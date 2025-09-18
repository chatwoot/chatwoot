import { buildFeedbackIntegration, feedbackModalIntegration, feedbackScreenshotIntegration } from '@sentry-internal/feedback';
import { lazyLoadIntegration } from './utils/lazyLoadIntegration.js';

/** Add a widget to capture user feedback to your application. */
const feedbackSyncIntegration = buildFeedbackIntegration({
  lazyLoadIntegration,
  getModalIntegration: () => feedbackModalIntegration,
  getScreenshotIntegration: () => feedbackScreenshotIntegration,
});

export { feedbackSyncIntegration };
//# sourceMappingURL=feedbackSync.js.map
