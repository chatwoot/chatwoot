import { captureException } from '@sentry/core';
import { consoleSandbox } from '@sentry/utils';
import { formatComponentName, generateComponentTrace } from './vendor/components.js';

const attachErrorHandler = (app, options) => {
  const { errorHandler, warnHandler, silent } = app.config;

  app.config.errorHandler = (error, vm, lifecycleHook) => {
    const componentName = formatComponentName(vm, false);
    const trace = vm ? generateComponentTrace(vm) : '';
    const metadata = {
      componentName,
      lifecycleHook,
      trace,
    };

    if (options.attachProps && vm) {
      // Vue2 - $options.propsData
      // Vue3 - $props
      if (vm.$options && vm.$options.propsData) {
        metadata.propsData = vm.$options.propsData;
      } else if (vm.$props) {
        metadata.propsData = vm.$props;
      }
    }

    // Capture exception in the next event loop, to make sure that all breadcrumbs are recorded in time.
    setTimeout(() => {
      captureException(error, {
        captureContext: { contexts: { vue: metadata } },
        mechanism: { handled: false },
      });
    });

    if (typeof errorHandler === 'function') {
      (errorHandler ).call(app, error, vm, lifecycleHook);
    }

    if (options.logErrors) {
      const hasConsole = typeof console !== 'undefined';
      const message = `Error in ${lifecycleHook}: "${error && error.toString()}"`;

      if (warnHandler) {
        (warnHandler ).call(null, message, vm, trace);
      } else if (hasConsole && !silent) {
        consoleSandbox(() => {
          // eslint-disable-next-line no-console
          console.error(`[Vue warn]: ${message}${trace}`);
        });
      }
    }
  };
};

export { attachErrorHandler };
//# sourceMappingURL=errorhandler.js.map
