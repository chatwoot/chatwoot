export { Breadcrumb, BreadcrumbHint, Request, SdkInfo, Event, EventHint, EventStatus, Exception, Response, Severity, StackFrame, Stacktrace, Thread, User, } from '@sentry/types';
export { SeverityLevel } from '@sentry/utils';
export { addGlobalEventProcessor, addBreadcrumb, captureException, captureEvent, captureMessage, configureScope, getHubFromCarrier, getCurrentHub, Hub, makeMain, Scope, Session, startTransaction, SDK_VERSION, setContext, setExtra, setExtras, setTag, setTags, setUser, withScope, } from '@sentry/core';
export { BrowserOptions } from './backend';
export { BrowserClient } from './client';
export { injectReportDialog, ReportDialogOptions } from './helpers';
export { eventFromException, eventFromMessage } from './eventbuilder';
export { defaultIntegrations, forceLoad, init, lastEventId, onLoad, showReportDialog, flush, close, wrap } from './sdk';
export { SDK_NAME } from './version';
//# sourceMappingURL=exports.d.ts.map