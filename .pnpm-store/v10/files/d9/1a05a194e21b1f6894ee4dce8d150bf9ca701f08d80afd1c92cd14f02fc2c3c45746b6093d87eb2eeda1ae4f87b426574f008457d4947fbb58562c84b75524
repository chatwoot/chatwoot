Object.defineProperty(exports, '__esModule', { value: true });

const version = require('./version.js');

/** Get's the global object for the current JavaScript runtime */
const GLOBAL_OBJ = globalThis ;

/**
 * Returns a global singleton contained in the global `__SENTRY__[]` object.
 *
 * If the singleton doesn't already exist in `__SENTRY__`, it will be created using the given factory
 * function and added to the `__SENTRY__` object.
 *
 * @param name name of the global singleton on __SENTRY__
 * @param creator creator Factory function to create the singleton if it doesn't already exist on `__SENTRY__`
 * @param obj (Optional) The global object on which to look for `__SENTRY__`, if not `GLOBAL_OBJ`'s return value
 * @returns the singleton
 */
function getGlobalSingleton(name, creator, obj) {
  const gbl = (obj || GLOBAL_OBJ) ;
  const __SENTRY__ = (gbl.__SENTRY__ = gbl.__SENTRY__ || {});
  const versionedCarrier = (__SENTRY__[version.SDK_VERSION] = __SENTRY__[version.SDK_VERSION] || {});
  return versionedCarrier[name] || (versionedCarrier[name] = creator());
}

exports.GLOBAL_OBJ = GLOBAL_OBJ;
exports.getGlobalSingleton = getGlobalSingleton;
//# sourceMappingURL=worldwide.js.map
