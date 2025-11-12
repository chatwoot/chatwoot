Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');

/**
 * An object that contains globally accessible properties and maintains a scope stack.
 * @hidden
 */

/**
 * Returns the global shim registry.
 *
 * FIXME: This function is problematic, because despite always returning a valid Carrier,
 * it has an optional `__SENTRY__` property, which then in turn requires us to always perform an unnecessary check
 * at the call-site. We always access the carrier through this function, so we can guarantee that `__SENTRY__` is there.
 **/
function getMainCarrier() {
  // This ensures a Sentry carrier exists
  getSentryCarrier(utils.GLOBAL_OBJ);
  return utils.GLOBAL_OBJ;
}

/** Will either get the existing sentry carrier, or create a new one. */
function getSentryCarrier(carrier) {
  const __SENTRY__ = (carrier.__SENTRY__ = carrier.__SENTRY__ || {});

  // For now: First SDK that sets the .version property wins
  __SENTRY__.version = __SENTRY__.version || utils.SDK_VERSION;

  // Intentionally populating and returning the version of "this" SDK instance
  // rather than what's set in .version so that "this" SDK always gets its carrier
  return (__SENTRY__[utils.SDK_VERSION] = __SENTRY__[utils.SDK_VERSION] || {});
}

exports.getMainCarrier = getMainCarrier;
exports.getSentryCarrier = getSentryCarrier;
//# sourceMappingURL=carrier.js.map
