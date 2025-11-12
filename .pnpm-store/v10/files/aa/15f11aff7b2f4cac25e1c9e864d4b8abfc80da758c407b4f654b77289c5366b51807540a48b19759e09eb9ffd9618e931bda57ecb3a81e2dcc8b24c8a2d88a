import { SDK_VERSION, getDefaultIntegrations, init as init$1 } from '@sentry/browser';
import { vueIntegration } from './integration.js';

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
            version: SDK_VERSION,
          },
        ],
        version: SDK_VERSION,
      },
    },
    defaultIntegrations: [...getDefaultIntegrations(config), vueIntegration()],
    ...config,
  };

  return init$1(options);
}

export { init };
//# sourceMappingURL=sdk.js.map
