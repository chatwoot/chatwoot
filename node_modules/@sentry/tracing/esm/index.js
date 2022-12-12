import { addExtensionMethods } from './hubextensions';
import * as Integrations from './integrations';
export { Integrations };
// This is already exported as part of `Integrations` above (and for the moment will remain so for
// backwards compatibility), but that interferes with treeshaking, so we also export it separately
// here.
//
// Previously we expected users to import tracing integrations like
//
// import { Integrations } from '@sentry/tracing';
// const instance = new Integrations.BrowserTracing();
//
// This makes the integrations unable to be treeshaken though. To address this, we now have
// this individual export. We now expect users to consume BrowserTracing like so:
//
// import { BrowserTracing } from '@sentry/tracing';
// const instance = new BrowserTracing();
//
// For an example of of the new usage of BrowserTracing, see @sentry/nextjs index.client.ts
export { BrowserTracing } from './browser';
export { Span, spanStatusfromHttpCode } from './span';
// eslint-disable-next-line deprecation/deprecation
export { SpanStatus } from './spanstatus';
export { Transaction } from './transaction';
export { 
// TODO deprecate old name in v7
instrumentOutgoingRequests as registerRequestInstrumentation, defaultRequestInstrumentationOptions, } from './browser';
export { IdleTransaction } from './idletransaction';
export { startIdleTransaction } from './hubextensions';
// We are patching the global object with our hub extension methods
addExtensionMethods();
export { addExtensionMethods };
export { extractTraceparentData, getActiveTransaction, hasTracingEnabled, stripUrlQueryAndFragment, TRACEPARENT_REGEXP, } from './utils';
//# sourceMappingURL=index.js.map