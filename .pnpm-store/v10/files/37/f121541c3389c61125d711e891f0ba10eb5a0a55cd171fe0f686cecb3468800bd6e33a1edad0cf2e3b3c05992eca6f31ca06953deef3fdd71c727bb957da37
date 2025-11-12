Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const scope = require('./scope.js');

/** Get the default current scope. */
function getDefaultCurrentScope() {
  return utils.getGlobalSingleton('defaultCurrentScope', () => new scope.Scope());
}

/** Get the default isolation scope. */
function getDefaultIsolationScope() {
  return utils.getGlobalSingleton('defaultIsolationScope', () => new scope.Scope());
}

exports.getDefaultCurrentScope = getDefaultCurrentScope;
exports.getDefaultIsolationScope = getDefaultIsolationScope;
//# sourceMappingURL=defaultScopes.js.map
