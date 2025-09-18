Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');

const SCOPE_ON_START_SPAN_FIELD = '_sentryScope';
const ISOLATION_SCOPE_ON_START_SPAN_FIELD = '_sentryIsolationScope';

/** Store the scope & isolation scope for a span, which can the be used when it is finished. */
function setCapturedScopesOnSpan(span, scope, isolationScope) {
  if (span) {
    utils.addNonEnumerableProperty(span, ISOLATION_SCOPE_ON_START_SPAN_FIELD, isolationScope);
    utils.addNonEnumerableProperty(span, SCOPE_ON_START_SPAN_FIELD, scope);
  }
}

/**
 * Grabs the scope and isolation scope off a span that were active when the span was started.
 */
function getCapturedScopesOnSpan(span) {
  return {
    scope: (span )[SCOPE_ON_START_SPAN_FIELD],
    isolationScope: (span )[ISOLATION_SCOPE_ON_START_SPAN_FIELD],
  };
}

exports.stripUrlQueryAndFragment = utils.stripUrlQueryAndFragment;
exports.getCapturedScopesOnSpan = getCapturedScopesOnSpan;
exports.setCapturedScopesOnSpan = setCapturedScopesOnSpan;
//# sourceMappingURL=utils.js.map
