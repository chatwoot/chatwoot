import * as Sentry from '@sentry/vue';

export default {
  errorCaptured(err, vm, info) {
    if (window.errorLoggingConfig) {
      Sentry.captureException(err);
    }
    // eslint-disable-next-line no-console
    console.error(err, info);
    return false;
  },
};
