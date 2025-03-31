import { forEachEnvelopeItem, getFramesFromEvent } from '@sentry/utils';
import { defineIntegration } from '../integration.js';
import { stripMetadataFromStackFrames, addMetadataToStackFrames } from '../metadata.js';

/**
 * This integration allows you to filter out, or tag error events that do not come from user code marked with a bundle key via the Sentry bundler plugins.
 */
const thirdPartyErrorFilterIntegration = defineIntegration((options) => {
  return {
    name: 'ThirdPartyErrorsFilter',
    setup(client) {
      // We need to strip metadata from stack frames before sending them to Sentry since these are client side only.
      // TODO(lforst): Move this cleanup logic into a more central place in the SDK.
      client.on('beforeEnvelope', envelope => {
        forEachEnvelopeItem(envelope, (item, type) => {
          if (type === 'event') {
            const event = Array.isArray(item) ? (item )[1] : undefined;

            if (event) {
              stripMetadataFromStackFrames(event);
              item[1] = event;
            }
          }
        });
      });

      client.on('applyFrameMetadata', event => {
        // Only apply stack frame metadata to error events
        if (event.type) {
          return;
        }

        const stackParser = client.getOptions().stackParser;
        addMetadataToStackFrames(stackParser, event);
      });
    },

    processEvent(event) {
      const frameKeys = getBundleKeysForAllFramesWithFilenames(event);

      if (frameKeys) {
        const arrayMethod =
          options.behaviour === 'drop-error-if-contains-third-party-frames' ||
          options.behaviour === 'apply-tag-if-contains-third-party-frames'
            ? 'some'
            : 'every';

        const behaviourApplies = frameKeys[arrayMethod](keys => !keys.some(key => options.filterKeys.includes(key)));

        if (behaviourApplies) {
          const shouldDrop =
            options.behaviour === 'drop-error-if-contains-third-party-frames' ||
            options.behaviour === 'drop-error-if-exclusively-contains-third-party-frames';
          if (shouldDrop) {
            return null;
          } else {
            event.tags = {
              ...event.tags,
              third_party_code: true,
            };
          }
        }
      }

      return event;
    },
  };
});

function getBundleKeysForAllFramesWithFilenames(event) {
  const frames = getFramesFromEvent(event);

  if (!frames) {
    return undefined;
  }

  return (
    frames
      // Exclude frames without a filename since these are likely native code or built-ins
      .filter(frame => !!frame.filename)
      .map(frame => {
        if (frame.module_metadata) {
          return Object.keys(frame.module_metadata)
            .filter(key => key.startsWith(BUNDLER_PLUGIN_APP_KEY_PREFIX))
            .map(key => key.slice(BUNDLER_PLUGIN_APP_KEY_PREFIX.length));
        }
        return [];
      })
  );
}

const BUNDLER_PLUGIN_APP_KEY_PREFIX = '_sentryBundlerPluginAppKey:';

export { thirdPartyErrorFilterIntegration };
//# sourceMappingURL=third-party-errors-filter.js.map
