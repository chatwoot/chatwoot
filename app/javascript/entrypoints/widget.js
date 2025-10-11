import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import VueDOMPurifyHTML from 'vue-dompurify-html';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18nMessages from '../widget/i18n';
import router from '../widget/router';
import { directive as onClickaway } from 'vue3-click-away';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
import { plugin, defaultConfig } from '@formkit/vue';

import {
  startsWithPlus,
  isPhoneNumberValidWithDialCode,
} from 'shared/helpers/Validators';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const app = createApp(App);

// Lazy-load Sentry ONLY when error occurs or after widget loads
// This keeps the initial bundle lightweight (~70-100KB smaller)
let sentryInitialized = false;
let sentryLoadPromise = null;

const initializeSentry = async () => {
  if (sentryInitialized || !window.errorLoggingConfig) {
    return;
  }

  // Prevent multiple initialization attempts
  if (sentryLoadPromise) {
    return sentryLoadPromise;
  }

  sentryLoadPromise = (async () => {
    try {
      // Lazy import Sentry (code-split)
      const Sentry = await import(
        /* webpackChunkName: "sentry" */ '@sentry/vue'
      );

      Sentry.init({
        app,
        dsn: window.errorLoggingConfig,
        environment: window.chatwootEnv || 'production',
        // MINIMAL INTEGRATIONS - Remove heavy features
        integrations: [
          // Only browser tracing, NO session replay (saves ~30KB)
          Sentry.browserTracingIntegration({ router }),
        ],
        // NO performance monitoring (saves bandwidth and processing)
        tracesSampleRate: 0,
        // NO session replay (saves ~30-40KB bundle + bandwidth)
        denyUrls: [
          /^chrome:\/\//i,
          /chrome-extension:/i,
          /extensions\//i,
          /file:\/\//i,
          /safari-web-extension:/i,
          /safari-extension:/i,
        ],
        ignoreErrors: [
          'ResizeObserver loop completed with undelivered notifications',
          'ResizeObserver loop limit exceeded',
          'Non-Error promise rejection captured',
        ],
        beforeSend(event) {
          // Add widget-specific context
          if (window.chatwootWebChannel) {
            event.contexts = event.contexts || {};
            event.contexts.widget = {
              websiteToken: window.chatwootWebChannel.websiteToken,
              websiteName: window.chatwootWebChannel.websiteName,
              locale: window.chatwootWebChannel.locale,
            };
          }
          return event;
        },
      });

      sentryInitialized = true;
      window.__CHATWOOT_SENTRY_LOADED__ = true;
    } catch (error) {
      console.warn('Failed to load Sentry:', error);
    }
  })();

  return sentryLoadPromise;
};

// Setup global error handler to lazy-load Sentry on first error
if (window.errorLoggingConfig) {
  app.config.errorHandler = async (err, instance, info) => {
    // Initialize Sentry on first error
    await initializeSentry();

    // Log error to console as fallback
    console.error('Widget error:', err, info);

    // Send to Sentry if loaded
    if (window.__CHATWOOT_SENTRY_LOADED__) {
      const Sentry = await import('@sentry/vue');
      Sentry.captureException(err, {
        contexts: {
          vue: {
            componentName: instance?.$options?.name,
            errorInfo: info,
          },
        },
      });
    }
  };

  // Initialize Sentry after widget is loaded (non-blocking, low priority)
  window.addEventListener('load', () => {
    // Delay initialization by 2 seconds to not impact page load
    setTimeout(() => {
      initializeSentry();
    }, 2000);
  });
}

app.use(i18n);
app.use(store);
app.use(router);
app.use(VueDOMPurifyHTML, domPurifyConfig);
app.directive('on-clickaway', onClickaway);

app.use(
  plugin,
  defaultConfig({
    rules: {
      startsWithPlus: ({ value }) => startsWithPlus(value),
      isValidPhoneNumber: ({ value }) => isPhoneNumberValidWithDialCode(value),
    },
  }),
);

// Event Bus
// We can use the useEmitter directly
// Vue.prototype.$emitter = emitter;

// Vue.config.productionTip = false;

window.onload = () => {
  window.WOOT_WIDGET = app.mount('#app');
  window.actionCable = new ActionCableConnector(
    window.WOOT_WIDGET,
    window.chatwootPubsubToken,
  );
};
