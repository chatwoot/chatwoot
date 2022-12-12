export { Severity, } from '@sentry/types';
export { addGlobalEventProcessor, addBreadcrumb, captureException, captureEvent, captureMessage, configureScope, getHubFromCarrier, getCurrentHub, Hub, makeMain, Scope, Session, startTransaction, SDK_VERSION, setContext, setExtra, setExtras, setTag, setTags, setUser, withScope, } from '@sentry/core';
export { BrowserClient } from './client';
export { injectReportDialog } from './helpers';
export { eventFromException, eventFromMessage } from './eventbuilder';
export { defaultIntegrations, forceLoad, init, lastEventId, onLoad, showReportDialog, flush, close, wrap } from './sdk';
export { SDK_NAME } from './version';
//# sourceMappingURL=exports.js.map