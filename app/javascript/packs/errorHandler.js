import * as Sentry from '@sentry/vue';

export default {
  errorCaptured(err, vm, info) {
    if (window.errorLoggingConfig) {
      Sentry.setTag('from', 'errorCaptured');
      if (vm) {
        Sentry.setContext('errorCaptured', { err, vm, info });
      } else {
        Sentry.setContext('errorCaptured', { err, info });
      }
      Sentry.captureException(err);
    }
    // eslint-disable-next-line no-console
    console.log('errorCaptured: ', err, info);
    return false;
  },
};
