import { addBreadcrumb } from './breadcrumbs.js';
import { getCurrentScope, withScope, getClient, getIsolationScope } from './currentScopes.js';
import { captureEvent, setUser, setTags, setTag, setExtra, setExtras, setContext, startSession, endSession } from './exports.js';

/**
 * This is for legacy reasons, and returns a proxy object instead of a hub to be used.
 *
 * @deprecated Use the methods directly from the top level Sentry API (e.g. `Sentry.withScope`)
 * For more information see our migration guide for
 * [replacing `getCurrentHub` and `Hub`](https://github.com/getsentry/sentry-javascript/blob/develop/MIGRATION.md#deprecate-hub)
 * usage
 */
// eslint-disable-next-line deprecation/deprecation
function getCurrentHubShim() {
  return {
    bindClient(client) {
      const scope = getCurrentScope();
      scope.setClient(client);
    },

    withScope,
    getClient: () => getClient() ,
    getScope: getCurrentScope,
    getIsolationScope,
    captureException: (exception, hint) => {
      return getCurrentScope().captureException(exception, hint);
    },
    captureMessage: (message, level, hint) => {
      return getCurrentScope().captureMessage(message, level, hint);
    },
    captureEvent,
    addBreadcrumb,
    setUser,
    setTags,
    setTag,
    setExtra,
    setExtras,
    setContext,

    getIntegration(integration) {
      const client = getClient();
      return (client && client.getIntegrationByName(integration.id)) || null;
    },

    startSession,
    endSession,
    captureSession(end) {
      // both send the update and pull the session from the scope
      if (end) {
        return endSession();
      }

      // only send the update
      _sendSessionUpdate();
    },
  };
}

/**
 * Returns the default hub instance.
 *
 * If a hub is already registered in the global carrier but this module
 * contains a more recent version, it replaces the registered version.
 * Otherwise, the currently registered hub will be returned.
 *
 * @deprecated Use the respective replacement method directly instead.
 */
// eslint-disable-next-line deprecation/deprecation
const getCurrentHub = getCurrentHubShim;

/**
 * Sends the current Session on the scope
 */
function _sendSessionUpdate() {
  const scope = getCurrentScope();
  const client = getClient();

  const session = scope.getSession();
  if (client && session) {
    client.captureSession(session);
  }
}

export { getCurrentHub, getCurrentHubShim };
//# sourceMappingURL=getCurrentHubShim.js.map
