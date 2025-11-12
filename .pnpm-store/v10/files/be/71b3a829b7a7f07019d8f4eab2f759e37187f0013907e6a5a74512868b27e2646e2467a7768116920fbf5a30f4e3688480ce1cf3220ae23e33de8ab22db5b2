Object.defineProperty(exports, '__esModule', { value: true });

const browser = require('@sentry/browser');
const core = require('@sentry/core');

// The following type is an intersection of the Route type from VueRouter v2, v3, and v4.
// This is not great, but kinda necessary to make it work with all versions at the same time.

/**
 * Instrument the Vue router to create navigation spans.
 */
function instrumentVueRouter(
  router,
  options

,
  startNavigationSpanFn,
) {
  let isFirstPageLoad = true;

  router.onError(error => browser.captureException(error, { mechanism: { handled: false } }));

  router.beforeEach((to, from, next) => {
    // According to docs we could use `from === VueRouter.START_LOCATION` but I couldn't get it working for Vue 2
    // https://router.vuejs.org/api/#router-start-location
    // https://next.router.vuejs.org/api/#start-location
    // Additionally, Nuxt does not provide the possibility to check for `from.matched.length === 0` (this is never 0).
    // Therefore, a flag was added to track the page-load: isFirstPageLoad

    // from.name:
    // - Vue 2: null
    // - Vue 3: undefined
    // - Nuxt: undefined
    // hence only '==' instead of '===', because `undefined == null` evaluates to `true`
    const isPageLoadNavigation =
      (from.name == null && from.matched.length === 0) || (from.name === undefined && isFirstPageLoad);

    if (isFirstPageLoad) {
      isFirstPageLoad = false;
    }

    const attributes = {
      [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.navigation.vue',
    };

    for (const key of Object.keys(to.params)) {
      attributes[`params.${key}`] = to.params[key];
    }
    for (const key of Object.keys(to.query)) {
      const value = to.query[key];
      if (value) {
        attributes[`query.${key}`] = value;
      }
    }

    // Determine a name for the routing transaction and where that name came from
    let spanName = to.path;
    let transactionSource = 'url';
    if (to.name && options.routeLabel !== 'path') {
      spanName = to.name.toString();
      transactionSource = 'custom';
    } else if (to.matched.length > 0) {
      const lastIndex = to.matched.length - 1;
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      spanName = to.matched[lastIndex].path;
      transactionSource = 'route';
    }

    core.getCurrentScope().setTransactionName(spanName);

    if (options.instrumentPageLoad && isPageLoadNavigation) {
      const activeRootSpan = getActiveRootSpan();
      if (activeRootSpan) {
        const existingAttributes = core.spanToJSON(activeRootSpan).data || {};
        if (existingAttributes[core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE] !== 'custom') {
          activeRootSpan.updateName(spanName);
          activeRootSpan.setAttribute(core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE, transactionSource);
        }
        // Set router attributes on the existing pageload transaction
        // This will override the origin, and add params & query attributes
        activeRootSpan.setAttributes({
          ...attributes,
          [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.pageload.vue',
        });
      }
    }

    if (options.instrumentNavigation && !isPageLoadNavigation) {
      attributes[core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE] = transactionSource;
      attributes[core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN] = 'auto.navigation.vue';
      startNavigationSpanFn({
        name: spanName,
        op: 'navigation',
        attributes,
      });
    }

    // Vue Router 4 no longer exposes the `next` function, so we need to
    // check if it's available before calling it.
    // `next` needs to be called in Vue Router 3 so that the hook is resolved.
    if (next) {
      next();
    }
  });
}

function getActiveRootSpan() {
  const span = core.getActiveSpan();
  const rootSpan = span && core.getRootSpan(span);

  if (!rootSpan) {
    return undefined;
  }

  const op = core.spanToJSON(rootSpan).op;

  // Only use this root span if it is a pageload or navigation span
  return op === 'navigation' || op === 'pageload' ? rootSpan : undefined;
}

exports.instrumentVueRouter = instrumentVueRouter;
//# sourceMappingURL=router.js.map
