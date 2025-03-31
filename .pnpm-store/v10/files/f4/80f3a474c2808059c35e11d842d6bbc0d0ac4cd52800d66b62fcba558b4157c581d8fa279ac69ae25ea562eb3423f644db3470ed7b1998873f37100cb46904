import { generatePropagationContext, isPlainObject, dateTimestampInSeconds, uuid4, logger } from '@sentry/utils';
import { updateSession } from './session.js';
import { _setSpanForScope, _getSpanForScope } from './utils/spanOnScope.js';

/**
 * Default value for maximum number of breadcrumbs added to an event.
 */
const DEFAULT_MAX_BREADCRUMBS = 100;

/**
 * Holds additional event information.
 */
class ScopeClass  {
  /** Flag if notifying is happening. */

  /** Callback for client to receive scope changes. */

  /** Callback list that will be called during event processing. */

  /** Array of breadcrumbs. */

  /** User */

  /** Tags */

  /** Extra */

  /** Contexts */

  /** Attachments */

  /** Propagation Context for distributed tracing */

  /**
   * A place to stash data which is needed at some point in the SDK's event processing pipeline but which shouldn't get
   * sent to Sentry
   */

  /** Fingerprint */

  /** Severity */

  /**
   * Transaction Name
   *
   * IMPORTANT: The transaction name on the scope has nothing to do with root spans/transaction objects.
   * It's purpose is to assign a transaction to the scope that's added to non-transaction events.
   */

  /** Session */

  /** Request Mode Session Status */

  /** The client on this scope */

  /** Contains the last event id of a captured event.  */

  // NOTE: Any field which gets added here should get added not only to the constructor but also to the `clone` method.

   constructor() {
    this._notifyingListeners = false;
    this._scopeListeners = [];
    this._eventProcessors = [];
    this._breadcrumbs = [];
    this._attachments = [];
    this._user = {};
    this._tags = {};
    this._extra = {};
    this._contexts = {};
    this._sdkProcessingMetadata = {};
    this._propagationContext = generatePropagationContext();
  }

  /**
   * @inheritDoc
   */
   clone() {
    const newScope = new ScopeClass();
    newScope._breadcrumbs = [...this._breadcrumbs];
    newScope._tags = { ...this._tags };
    newScope._extra = { ...this._extra };
    newScope._contexts = { ...this._contexts };
    newScope._user = this._user;
    newScope._level = this._level;
    newScope._session = this._session;
    newScope._transactionName = this._transactionName;
    newScope._fingerprint = this._fingerprint;
    newScope._eventProcessors = [...this._eventProcessors];
    newScope._requestSession = this._requestSession;
    newScope._attachments = [...this._attachments];
    newScope._sdkProcessingMetadata = { ...this._sdkProcessingMetadata };
    newScope._propagationContext = { ...this._propagationContext };
    newScope._client = this._client;
    newScope._lastEventId = this._lastEventId;

    _setSpanForScope(newScope, _getSpanForScope(this));

    return newScope;
  }

  /**
   * @inheritDoc
   */
   setClient(client) {
    this._client = client;
  }

  /**
   * @inheritDoc
   */
   setLastEventId(lastEventId) {
    this._lastEventId = lastEventId;
  }

  /**
   * @inheritDoc
   */
   getClient() {
    return this._client ;
  }

  /**
   * @inheritDoc
   */
   lastEventId() {
    return this._lastEventId;
  }

  /**
   * @inheritDoc
   */
   addScopeListener(callback) {
    this._scopeListeners.push(callback);
  }

  /**
   * @inheritDoc
   */
   addEventProcessor(callback) {
    this._eventProcessors.push(callback);
    return this;
  }

  /**
   * @inheritDoc
   */
   setUser(user) {
    // If null is passed we want to unset everything, but still define keys,
    // so that later down in the pipeline any existing values are cleared.
    this._user = user || {
      email: undefined,
      id: undefined,
      ip_address: undefined,
      username: undefined,
    };

    if (this._session) {
      updateSession(this._session, { user });
    }

    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   getUser() {
    return this._user;
  }

  /**
   * @inheritDoc
   */
   getRequestSession() {
    return this._requestSession;
  }

  /**
   * @inheritDoc
   */
   setRequestSession(requestSession) {
    this._requestSession = requestSession;
    return this;
  }

  /**
   * @inheritDoc
   */
   setTags(tags) {
    this._tags = {
      ...this._tags,
      ...tags,
    };
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setTag(key, value) {
    this._tags = { ...this._tags, [key]: value };
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setExtras(extras) {
    this._extra = {
      ...this._extra,
      ...extras,
    };
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setExtra(key, extra) {
    this._extra = { ...this._extra, [key]: extra };
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setFingerprint(fingerprint) {
    this._fingerprint = fingerprint;
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setLevel(level) {
    this._level = level;
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setTransactionName(name) {
    this._transactionName = name;
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setContext(key, context) {
    if (context === null) {
      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete this._contexts[key];
    } else {
      this._contexts[key] = context;
    }

    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   setSession(session) {
    if (!session) {
      delete this._session;
    } else {
      this._session = session;
    }
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   getSession() {
    return this._session;
  }

  /**
   * @inheritDoc
   */
   update(captureContext) {
    if (!captureContext) {
      return this;
    }

    const scopeToMerge = typeof captureContext === 'function' ? captureContext(this) : captureContext;

    const [scopeInstance, requestSession] =
      scopeToMerge instanceof Scope
        ? [scopeToMerge.getScopeData(), scopeToMerge.getRequestSession()]
        : isPlainObject(scopeToMerge)
          ? [captureContext , (captureContext ).requestSession]
          : [];

    const { tags, extra, user, contexts, level, fingerprint = [], propagationContext } = scopeInstance || {};

    this._tags = { ...this._tags, ...tags };
    this._extra = { ...this._extra, ...extra };
    this._contexts = { ...this._contexts, ...contexts };

    if (user && Object.keys(user).length) {
      this._user = user;
    }

    if (level) {
      this._level = level;
    }

    if (fingerprint.length) {
      this._fingerprint = fingerprint;
    }

    if (propagationContext) {
      this._propagationContext = propagationContext;
    }

    if (requestSession) {
      this._requestSession = requestSession;
    }

    return this;
  }

  /**
   * @inheritDoc
   */
   clear() {
    // client is not cleared here on purpose!
    this._breadcrumbs = [];
    this._tags = {};
    this._extra = {};
    this._user = {};
    this._contexts = {};
    this._level = undefined;
    this._transactionName = undefined;
    this._fingerprint = undefined;
    this._requestSession = undefined;
    this._session = undefined;
    _setSpanForScope(this, undefined);
    this._attachments = [];
    this._propagationContext = generatePropagationContext();

    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   addBreadcrumb(breadcrumb, maxBreadcrumbs) {
    const maxCrumbs = typeof maxBreadcrumbs === 'number' ? maxBreadcrumbs : DEFAULT_MAX_BREADCRUMBS;

    // No data has been changed, so don't notify scope listeners
    if (maxCrumbs <= 0) {
      return this;
    }

    const mergedBreadcrumb = {
      timestamp: dateTimestampInSeconds(),
      ...breadcrumb,
    };

    const breadcrumbs = this._breadcrumbs;
    breadcrumbs.push(mergedBreadcrumb);
    this._breadcrumbs = breadcrumbs.length > maxCrumbs ? breadcrumbs.slice(-maxCrumbs) : breadcrumbs;

    this._notifyScopeListeners();

    return this;
  }

  /**
   * @inheritDoc
   */
   getLastBreadcrumb() {
    return this._breadcrumbs[this._breadcrumbs.length - 1];
  }

  /**
   * @inheritDoc
   */
   clearBreadcrumbs() {
    this._breadcrumbs = [];
    this._notifyScopeListeners();
    return this;
  }

  /**
   * @inheritDoc
   */
   addAttachment(attachment) {
    this._attachments.push(attachment);
    return this;
  }

  /**
   * @inheritDoc
   */
   clearAttachments() {
    this._attachments = [];
    return this;
  }

  /** @inheritDoc */
   getScopeData() {
    return {
      breadcrumbs: this._breadcrumbs,
      attachments: this._attachments,
      contexts: this._contexts,
      tags: this._tags,
      extra: this._extra,
      user: this._user,
      level: this._level,
      fingerprint: this._fingerprint || [],
      eventProcessors: this._eventProcessors,
      propagationContext: this._propagationContext,
      sdkProcessingMetadata: this._sdkProcessingMetadata,
      transactionName: this._transactionName,
      span: _getSpanForScope(this),
    };
  }

  /**
   * @inheritDoc
   */
   setSDKProcessingMetadata(newData) {
    this._sdkProcessingMetadata = { ...this._sdkProcessingMetadata, ...newData };

    return this;
  }

  /**
   * @inheritDoc
   */
   setPropagationContext(context) {
    this._propagationContext = context;
    return this;
  }

  /**
   * @inheritDoc
   */
   getPropagationContext() {
    return this._propagationContext;
  }

  /**
   * @inheritDoc
   */
   captureException(exception, hint) {
    const eventId = hint && hint.event_id ? hint.event_id : uuid4();

    if (!this._client) {
      logger.warn('No client configured on scope - will not capture exception!');
      return eventId;
    }

    const syntheticException = new Error('Sentry syntheticException');

    this._client.captureException(
      exception,
      {
        originalException: exception,
        syntheticException,
        ...hint,
        event_id: eventId,
      },
      this,
    );

    return eventId;
  }

  /**
   * @inheritDoc
   */
   captureMessage(message, level, hint) {
    const eventId = hint && hint.event_id ? hint.event_id : uuid4();

    if (!this._client) {
      logger.warn('No client configured on scope - will not capture message!');
      return eventId;
    }

    const syntheticException = new Error(message);

    this._client.captureMessage(
      message,
      level,
      {
        originalException: message,
        syntheticException,
        ...hint,
        event_id: eventId,
      },
      this,
    );

    return eventId;
  }

  /**
   * @inheritDoc
   */
   captureEvent(event, hint) {
    const eventId = hint && hint.event_id ? hint.event_id : uuid4();

    if (!this._client) {
      logger.warn('No client configured on scope - will not capture event!');
      return eventId;
    }

    this._client.captureEvent(event, { ...hint, event_id: eventId }, this);

    return eventId;
  }

  /**
   * This will be called on every set call.
   */
   _notifyScopeListeners() {
    // We need this check for this._notifyingListeners to be able to work on scope during updates
    // If this check is not here we'll produce endless recursion when something is done with the scope
    // during the callback.
    if (!this._notifyingListeners) {
      this._notifyingListeners = true;
      this._scopeListeners.forEach(callback => {
        callback(this);
      });
      this._notifyingListeners = false;
    }
  }
}

// NOTE: By exporting this here as const & type, instead of doing `export class`,
// We can get the correct class when importing from `@sentry/core`, but the original type (from `@sentry/types`)
// This is helpful for interop, e.g. when doing `import type { Scope } from '@sentry/node';` (which re-exports this)

/**
 * Holds additional event information.
 */
const Scope = ScopeClass;

/**
 * Holds additional event information.
 */

export { Scope };
//# sourceMappingURL=scope.js.map
