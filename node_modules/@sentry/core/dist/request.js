Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var utils_1 = require("@sentry/utils");
var api_1 = require("./api");
/** Extract sdk info from from the API metadata */
function getSdkMetadataForEnvelopeHeader(api) {
    if (!api.metadata || !api.metadata.sdk) {
        return;
    }
    var _a = api.metadata.sdk, name = _a.name, version = _a.version;
    return { name: name, version: version };
}
/**
 * Apply SdkInfo (name, version, packages, integrations) to the corresponding event key.
 * Merge with existing data if any.
 **/
function enhanceEventWithSdkInfo(event, sdkInfo) {
    if (!sdkInfo) {
        return event;
    }
    event.sdk = event.sdk || {};
    event.sdk.name = event.sdk.name || sdkInfo.name;
    event.sdk.version = event.sdk.version || sdkInfo.version;
    event.sdk.integrations = tslib_1.__spread((event.sdk.integrations || []), (sdkInfo.integrations || []));
    event.sdk.packages = tslib_1.__spread((event.sdk.packages || []), (sdkInfo.packages || []));
    return event;
}
/** Creates an envelope from a Session */
function createSessionEnvelope(session, api) {
    var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
    var envelopeHeaders = tslib_1.__assign(tslib_1.__assign({ sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: utils_1.dsnToString(api.dsn) }));
    // I know this is hacky but we don't want to add `sessions` to request type since it's never rate limited
    var type = 'aggregates' in session ? 'sessions' : 'session';
    // TODO (v7) Have to cast type because envelope items do not accept a `SentryRequestType`
    var envelopeItem = [{ type: type }, session];
    var envelope = utils_1.createEnvelope(envelopeHeaders, [envelopeItem]);
    return [envelope, type];
}
exports.createSessionEnvelope = createSessionEnvelope;
/** Creates a SentryRequest from a Session. */
function sessionToSentryRequest(session, api) {
    var _a = tslib_1.__read(createSessionEnvelope(session, api), 2), envelope = _a[0], type = _a[1];
    return {
        body: utils_1.serializeEnvelope(envelope),
        type: type,
        url: api_1.getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel),
    };
}
exports.sessionToSentryRequest = sessionToSentryRequest;
/**
 * Create an Envelope from an event. Note that this is duplicated from below,
 * but on purpose as this will be refactored in v7.
 */
function createEventEnvelope(event, api) {
    var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
    var eventType = event.type || 'event';
    var transactionSampling = (event.sdkProcessingMetadata || {}).transactionSampling;
    var _a = transactionSampling || {}, samplingMethod = _a.method, sampleRate = _a.rate;
    // TODO: Below is a temporary hack in order to debug a serialization error - see
    // https://github.com/getsentry/sentry-javascript/issues/2809,
    // https://github.com/getsentry/sentry-javascript/pull/4425, and
    // https://github.com/getsentry/sentry-javascript/pull/4574.
    //
    // TL; DR: even though we normalize all events (which should prevent this), something is causing `JSON.stringify` to
    // throw a circular reference error.
    //
    // When it's time to remove it:
    // 1. Delete everything between here and where the request object `req` is created, EXCEPT the line deleting
    //    `sdkProcessingMetadata`
    // 2. Restore the original version of the request body, which is commented out
    // 3. Search for either of the PR URLs above and pull out the companion hacks in the browser playwright tests and the
    //    baseClient tests in this package
    enhanceEventWithSdkInfo(event, api.metadata.sdk);
    event.tags = event.tags || {};
    event.extra = event.extra || {};
    // In theory, all events should be marked as having gone through normalization and so
    // we should never set this tag/extra data
    if (!(event.sdkProcessingMetadata && event.sdkProcessingMetadata.baseClientNormalized)) {
        event.tags.skippedNormalization = true;
        event.extra.normalizeDepth = event.sdkProcessingMetadata ? event.sdkProcessingMetadata.normalizeDepth : 'unset';
    }
    // prevent this data from being sent to sentry
    // TODO: This is NOT part of the hack - DO NOT DELETE
    delete event.sdkProcessingMetadata;
    var envelopeHeaders = tslib_1.__assign(tslib_1.__assign({ event_id: event.event_id, sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: utils_1.dsnToString(api.dsn) }));
    var eventItem = [
        {
            type: eventType,
            sample_rates: [{ id: samplingMethod, rate: sampleRate }],
        },
        event,
    ];
    return utils_1.createEnvelope(envelopeHeaders, [eventItem]);
}
exports.createEventEnvelope = createEventEnvelope;
/** Creates a SentryRequest from an event. */
function eventToSentryRequest(event, api) {
    var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
    var eventType = event.type || 'event';
    var useEnvelope = eventType === 'transaction' || !!api.tunnel;
    var transactionSampling = (event.sdkProcessingMetadata || {}).transactionSampling;
    var _a = transactionSampling || {}, samplingMethod = _a.method, sampleRate = _a.rate;
    // TODO: Below is a temporary hack in order to debug a serialization error - see
    // https://github.com/getsentry/sentry-javascript/issues/2809,
    // https://github.com/getsentry/sentry-javascript/pull/4425, and
    // https://github.com/getsentry/sentry-javascript/pull/4574.
    //
    // TL; DR: even though we normalize all events (which should prevent this), something is causing `JSON.stringify` to
    // throw a circular reference error.
    //
    // When it's time to remove it:
    // 1. Delete everything between here and where the request object `req` is created, EXCEPT the line deleting
    //    `sdkProcessingMetadata`
    // 2. Restore the original version of the request body, which is commented out
    // 3. Search for either of the PR URLs above and pull out the companion hacks in the browser playwright tests and the
    //    baseClient tests in this package
    enhanceEventWithSdkInfo(event, api.metadata.sdk);
    event.tags = event.tags || {};
    event.extra = event.extra || {};
    // In theory, all events should be marked as having gone through normalization and so
    // we should never set this tag/extra data
    if (!(event.sdkProcessingMetadata && event.sdkProcessingMetadata.baseClientNormalized)) {
        event.tags.skippedNormalization = true;
        event.extra.normalizeDepth = event.sdkProcessingMetadata ? event.sdkProcessingMetadata.normalizeDepth : 'unset';
    }
    // prevent this data from being sent to sentry
    // TODO: This is NOT part of the hack - DO NOT DELETE
    delete event.sdkProcessingMetadata;
    var body;
    try {
        // 99.9% of events should get through just fine - no change in behavior for them
        body = JSON.stringify(event);
    }
    catch (err) {
        // Record data about the error without replacing original event data, then force renormalization
        event.tags.JSONStringifyError = true;
        event.extra.JSONStringifyError = err;
        try {
            body = JSON.stringify(utils_1.normalize(event));
        }
        catch (newErr) {
            // At this point even renormalization hasn't worked, meaning something about the event data has gone very wrong.
            // Time to cut our losses and record only the new error. With luck, even in the problematic cases we're trying to
            // debug with this hack, we won't ever land here.
            var innerErr = newErr;
            body = JSON.stringify({
                message: 'JSON.stringify error after renormalization',
                // setting `extra: { innerErr }` here for some reason results in an empty object, so unpack manually
                extra: { message: innerErr.message, stack: innerErr.stack },
            });
        }
    }
    var req = {
        // this is the relevant line of code before the hack was added, to make it easy to undo said hack once we've solved
        // the mystery
        // body: JSON.stringify(sdkInfo ? enhanceEventWithSdkInfo(event, api.metadata.sdk) : event),
        body: body,
        type: eventType,
        url: useEnvelope
            ? api_1.getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel)
            : api_1.getStoreEndpointWithUrlEncodedAuth(api.dsn),
    };
    // https://develop.sentry.dev/sdk/envelopes/
    // Since we don't need to manipulate envelopes nor store them, there is no
    // exported concept of an Envelope with operations including serialization and
    // deserialization. Instead, we only implement a minimal subset of the spec to
    // serialize events inline here.
    if (useEnvelope) {
        var envelopeHeaders = tslib_1.__assign(tslib_1.__assign({ event_id: event.event_id, sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: utils_1.dsnToString(api.dsn) }));
        var eventItem = [
            {
                type: eventType,
                sample_rates: [{ id: samplingMethod, rate: sampleRate }],
            },
            req.body,
        ];
        var envelope = utils_1.createEnvelope(envelopeHeaders, [eventItem]);
        req.body = utils_1.serializeEnvelope(envelope);
    }
    return req;
}
exports.eventToSentryRequest = eventToSentryRequest;
//# sourceMappingURL=request.js.map