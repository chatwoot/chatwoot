Object.defineProperty(exports, "__esModule", { value: true });
var hubextensions_1 = require("./hubextensions");
exports.addExtensionMethods = hubextensions_1.addExtensionMethods;
var Integrations = require("./integrations");
exports.Integrations = Integrations;
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
var browser_1 = require("./browser");
exports.BrowserTracing = browser_1.BrowserTracing;
var span_1 = require("./span");
exports.Span = span_1.Span;
exports.spanStatusfromHttpCode = span_1.spanStatusfromHttpCode;
// eslint-disable-next-line deprecation/deprecation
var spanstatus_1 = require("./spanstatus");
exports.SpanStatus = spanstatus_1.SpanStatus;
var transaction_1 = require("./transaction");
exports.Transaction = transaction_1.Transaction;
var browser_2 = require("./browser");
// TODO deprecate old name in v7
exports.registerRequestInstrumentation = browser_2.instrumentOutgoingRequests;
exports.defaultRequestInstrumentationOptions = browser_2.defaultRequestInstrumentationOptions;
var idletransaction_1 = require("./idletransaction");
exports.IdleTransaction = idletransaction_1.IdleTransaction;
var hubextensions_2 = require("./hubextensions");
exports.startIdleTransaction = hubextensions_2.startIdleTransaction;
// We are patching the global object with our hub extension methods
hubextensions_1.addExtensionMethods();
var utils_1 = require("./utils");
exports.extractTraceparentData = utils_1.extractTraceparentData;
exports.getActiveTransaction = utils_1.getActiveTransaction;
exports.hasTracingEnabled = utils_1.hasTracingEnabled;
exports.stripUrlQueryAndFragment = utils_1.stripUrlQueryAndFragment;
exports.TRACEPARENT_REGEXP = utils_1.TRACEPARENT_REGEXP;
//# sourceMappingURL=index.js.map