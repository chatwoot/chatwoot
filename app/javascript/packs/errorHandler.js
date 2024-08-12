import * as Sentry from '@sentry/vue';

export default {
  errorCaptured(err, vm, info) {
    if (vm) {
      if (window.errorLoggingConfig) {
        Sentry.setTag('from', 'errorCaptured');
        Sentry.captureException(err);
      } else {
        // eslint-disable-next-line no-console
        console.log('errorCaptured: ', err, info);
      }
    } else {
      // temporary fix to avoid app freeze
      window.location.reload();
    }
    return false;
  },
};
