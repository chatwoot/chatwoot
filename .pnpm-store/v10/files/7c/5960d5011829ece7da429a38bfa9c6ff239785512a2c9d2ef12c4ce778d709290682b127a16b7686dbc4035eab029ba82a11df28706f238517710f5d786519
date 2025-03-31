Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const dynamicSamplingContext = require('../tracing/dynamicSamplingContext.js');
const spanUtils = require('./spanUtils.js');

/**
 * Applies data from the scope to the event and runs all event processors on it.
 */
function applyScopeDataToEvent(event, data) {
  const { fingerprint, span, breadcrumbs, sdkProcessingMetadata } = data;

  // Apply general data
  applyDataToEvent(event, data);

  // We want to set the trace context for normal events only if there isn't already
  // a trace context on the event. There is a product feature in place where we link
  // errors with transaction and it relies on that.
  if (span) {
    applySpanToEvent(event, span);
  }

  applyFingerprintToEvent(event, fingerprint);
  applyBreadcrumbsToEvent(event, breadcrumbs);
  applySdkMetadataToEvent(event, sdkProcessingMetadata);
}

/** Merge data of two scopes together. */
function mergeScopeData(data, mergeData) {
  const {
    extra,
    tags,
    user,
    contexts,
    level,
    sdkProcessingMetadata,
    breadcrumbs,
    fingerprint,
    eventProcessors,
    attachments,
    propagationContext,
    transactionName,
    span,
  } = mergeData;

  mergeAndOverwriteScopeData(data, 'extra', extra);
  mergeAndOverwriteScopeData(data, 'tags', tags);
  mergeAndOverwriteScopeData(data, 'user', user);
  mergeAndOverwriteScopeData(data, 'contexts', contexts);
  mergeAndOverwriteScopeData(data, 'sdkProcessingMetadata', sdkProcessingMetadata);

  if (level) {
    data.level = level;
  }

  if (transactionName) {
    data.transactionName = transactionName;
  }

  if (span) {
    data.span = span;
  }

  if (breadcrumbs.length) {
    data.breadcrumbs = [...data.breadcrumbs, ...breadcrumbs];
  }

  if (fingerprint.length) {
    data.fingerprint = [...data.fingerprint, ...fingerprint];
  }

  if (eventProcessors.length) {
    data.eventProcessors = [...data.eventProcessors, ...eventProcessors];
  }

  if (attachments.length) {
    data.attachments = [...data.attachments, ...attachments];
  }

  data.propagationContext = { ...data.propagationContext, ...propagationContext };
}

/**
 * Merges certain scope data. Undefined values will overwrite any existing values.
 * Exported only for tests.
 */
function mergeAndOverwriteScopeData

(data, prop, mergeVal) {
  if (mergeVal && Object.keys(mergeVal).length) {
    // Clone object
    data[prop] = { ...data[prop] };
    for (const key in mergeVal) {
      if (Object.prototype.hasOwnProperty.call(mergeVal, key)) {
        data[prop][key] = mergeVal[key];
      }
    }
  }
}

function applyDataToEvent(event, data) {
  const { extra, tags, user, contexts, level, transactionName } = data;

  const cleanedExtra = utils.dropUndefinedKeys(extra);
  if (cleanedExtra && Object.keys(cleanedExtra).length) {
    event.extra = { ...cleanedExtra, ...event.extra };
  }

  const cleanedTags = utils.dropUndefinedKeys(tags);
  if (cleanedTags && Object.keys(cleanedTags).length) {
    event.tags = { ...cleanedTags, ...event.tags };
  }

  const cleanedUser = utils.dropUndefinedKeys(user);
  if (cleanedUser && Object.keys(cleanedUser).length) {
    event.user = { ...cleanedUser, ...event.user };
  }

  const cleanedContexts = utils.dropUndefinedKeys(contexts);
  if (cleanedContexts && Object.keys(cleanedContexts).length) {
    event.contexts = { ...cleanedContexts, ...event.contexts };
  }

  if (level) {
    event.level = level;
  }

  // transaction events get their `transaction` from the root span name
  if (transactionName && event.type !== 'transaction') {
    event.transaction = transactionName;
  }
}

function applyBreadcrumbsToEvent(event, breadcrumbs) {
  const mergedBreadcrumbs = [...(event.breadcrumbs || []), ...breadcrumbs];
  event.breadcrumbs = mergedBreadcrumbs.length ? mergedBreadcrumbs : undefined;
}

function applySdkMetadataToEvent(event, sdkProcessingMetadata) {
  event.sdkProcessingMetadata = {
    ...event.sdkProcessingMetadata,
    ...sdkProcessingMetadata,
  };
}

function applySpanToEvent(event, span) {
  event.contexts = {
    trace: spanUtils.spanToTraceContext(span),
    ...event.contexts,
  };

  event.sdkProcessingMetadata = {
    dynamicSamplingContext: dynamicSamplingContext.getDynamicSamplingContextFromSpan(span),
    ...event.sdkProcessingMetadata,
  };

  const rootSpan = spanUtils.getRootSpan(span);
  const transactionName = spanUtils.spanToJSON(rootSpan).description;
  if (transactionName && !event.transaction && event.type === 'transaction') {
    event.transaction = transactionName;
  }
}

/**
 * Applies fingerprint from the scope to the event if there's one,
 * uses message if there's one instead or get rid of empty fingerprint
 */
function applyFingerprintToEvent(event, fingerprint) {
  // Make sure it's an array first and we actually have something in place
  event.fingerprint = event.fingerprint ? utils.arrayify(event.fingerprint) : [];

  // If we have something on the scope, then merge it with event
  if (fingerprint) {
    event.fingerprint = event.fingerprint.concat(fingerprint);
  }

  // If we have no data at all, remove empty array default
  if (event.fingerprint && !event.fingerprint.length) {
    delete event.fingerprint;
  }
}

exports.applyScopeDataToEvent = applyScopeDataToEvent;
exports.mergeAndOverwriteScopeData = mergeAndOverwriteScopeData;
exports.mergeScopeData = mergeScopeData;
//# sourceMappingURL=applyScopeDataToEvent.js.map
