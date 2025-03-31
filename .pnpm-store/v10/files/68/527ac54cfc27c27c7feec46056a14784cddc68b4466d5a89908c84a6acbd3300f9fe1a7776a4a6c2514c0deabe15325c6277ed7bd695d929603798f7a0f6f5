Object.defineProperty(exports, '__esModule', { value: true });

const browser = require('@sentry/browser');
const integration = require('./integration.js');

/**
 * Inits the Vue SDK
 */
function init(
  config = {},
) {
  const options = {
    _metadata: {
      sdk: {
        name: 'sentry.javascript.vue',
        packages: [
          {
            name: 'npm:@sentry/vue',
            version: browser.SDK_VERSION,
          },
        ],
        version: browser.SDK_VERSION,
      },
    },
    defaultIntegrations: [...browser.getDefaultIntegrations(config), integration.vueIntegration()],
    ...config,
  };

  return browser.init(options);
}

exports.init = init;
//# sourceMappingURL=sdk.js.map
