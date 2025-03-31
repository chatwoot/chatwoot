import { getActiveSpan, startInactiveSpan, SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN } from '@sentry/browser';
import { logger, timestampInSeconds } from '@sentry/utils';
import { DEFAULT_HOOKS } from './constants.js';
import { DEBUG_BUILD } from './debug-build.js';
import { formatComponentName } from './vendor/components.js';

const VUE_OP = 'ui.vue';

// Mappings from operation to corresponding lifecycle hook.
const HOOKS = {
  activate: ['activated', 'deactivated'],
  create: ['beforeCreate', 'created'],
  // Vue 3
  unmount: ['beforeUnmount', 'unmounted'],
  // Vue 2
  destroy: ['beforeDestroy', 'destroyed'],
  mount: ['beforeMount', 'mounted'],
  update: ['beforeUpdate', 'updated'],
};

/** Finish top-level span and activity with a debounce configured using `timeout` option */
function finishRootSpan(vm, timestamp, timeout) {
  if (vm.$_sentryRootSpanTimer) {
    clearTimeout(vm.$_sentryRootSpanTimer);
  }

  vm.$_sentryRootSpanTimer = setTimeout(() => {
    if (vm.$root && vm.$root.$_sentryRootSpan) {
      vm.$root.$_sentryRootSpan.end(timestamp);
      vm.$root.$_sentryRootSpan = undefined;
    }
  }, timeout);
}

/** Find if the current component exists in the provided `TracingOptions.trackComponents` array option. */
function findTrackComponent(trackComponents, formattedName) {
  function extractComponentName(name) {
    return name.replace(/^<([^\s]*)>(?: at [^\s]*)?$/, '$1');
  }

  const isMatched = trackComponents.some(compo => {
    return extractComponentName(formattedName) === extractComponentName(compo);
  });

  return isMatched;
}

const createTracingMixins = (options) => {
  const hooks = (options.hooks || [])
    .concat(DEFAULT_HOOKS)
    // Removing potential duplicates
    .filter((value, index, self) => self.indexOf(value) === index);

  const mixins = {};

  for (const operation of hooks) {
    // Retrieve corresponding hooks from Vue lifecycle.
    // eg. mount => ['beforeMount', 'mounted']
    const internalHooks = HOOKS[operation];
    if (!internalHooks) {
      DEBUG_BUILD && logger.warn(`Unknown hook: ${operation}`);
      continue;
    }

    for (const internalHook of internalHooks) {
      mixins[internalHook] = function () {
        const isRoot = this.$root === this;

        if (isRoot) {
          const activeSpan = getActiveSpan();
          if (activeSpan) {
            this.$_sentryRootSpan =
              this.$_sentryRootSpan ||
              startInactiveSpan({
                name: 'Application Render',
                op: `${VUE_OP}.render`,
                attributes: {
                  [SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.vue',
                },
              });
          }
        }

        // Skip components that we don't want to track to minimize the noise and give a more granular control to the user
        const name = formatComponentName(this, false);

        const shouldTrack = Array.isArray(options.trackComponents)
          ? findTrackComponent(options.trackComponents, name)
          : options.trackComponents;

        // We always want to track root component
        if (!isRoot && !shouldTrack) {
          return;
        }

        this.$_sentrySpans = this.$_sentrySpans || {};

        // Start a new span if current hook is a 'before' hook.
        // Otherwise, retrieve the current span and finish it.
        if (internalHook == internalHooks[0]) {
          const activeSpan = (this.$root && this.$root.$_sentryRootSpan) || getActiveSpan();
          if (activeSpan) {
            // Cancel old span for this hook operation in case it didn't get cleaned up. We're not actually sure if it
            // will ever be the case that cleanup hooks re not called, but we had users report that spans didn't get
            // finished so we finish the span before starting a new one, just to be sure.
            const oldSpan = this.$_sentrySpans[operation];
            if (oldSpan) {
              oldSpan.end();
            }

            this.$_sentrySpans[operation] = startInactiveSpan({
              name: `Vue ${name}`,
              op: `${VUE_OP}.${operation}`,
              attributes: {
                [SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.vue',
              },
              // UI spans should only be created if there is an active root span (transaction)
              onlyIfParent: true,
            });
          }
        } else {
          // The span should already be added via the first handler call (in the 'before' hook)
          const span = this.$_sentrySpans[operation];
          // The before hook did not start the tracking span, so the span was not added.
          // This is probably because it happened before there is an active transaction
          if (!span) return;
          span.end();

          finishRootSpan(this, timestampInSeconds(), options.timeout);
        }
      };
    }
  }

  return mixins;
};

export { createTracingMixins, findTrackComponent };
//# sourceMappingURL=tracing.js.map
