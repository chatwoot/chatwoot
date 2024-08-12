import * as Sentry from '@sentry/vue';

export default {
  errorCaptured(err, vm, info) {
    if (window.errorLoggingConfig) {
      Sentry.setTag('from', 'errorCaptured');
      if (vm) {
        Sentry.setContext('errorData', { vm, info });
      } else {
        Sentry.setContext('errorData', { info });
      }
      Sentry.captureException(err);
    } else {
      // eslint-disable-next-line no-console
      console.log('errorCaptured: ', err, vm, info);
    }
    return false;
  },
};
