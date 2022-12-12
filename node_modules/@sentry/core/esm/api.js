import { dsnToString, makeDsn, urlEncode } from '@sentry/utils';
var SENTRY_API_VERSION = '7';
/**
 * Helper class to provide urls, headers and metadata that can be used to form
 * different types of requests to Sentry endpoints.
 * Supports both envelopes and regular event requests.
 *
 * @deprecated Please use APIDetails
 **/
var API = /** @class */ (function () {
    /** Create a new instance of API */
    function API(dsn, metadata, tunnel) {
        if (metadata === void 0) { metadata = {}; }
        this.dsn = dsn;
        this._dsnObject = makeDsn(dsn);
        this.metadata = metadata;
        this._tunnel = tunnel;
    }
    /** Returns the Dsn object. */
    API.prototype.getDsn = function () {
        return this._dsnObject;
    };
    /** Does this transport force envelopes? */
    API.prototype.forceEnvelope = function () {
        return !!this._tunnel;
    };
    /** Returns the prefix to construct Sentry ingestion API endpoints. */
    API.prototype.getBaseApiEndpoint = function () {
        return getBaseApiEndpoint(this._dsnObject);
    };
    /** Returns the store endpoint URL. */
    API.prototype.getStoreEndpoint = function () {
        return getStoreEndpoint(this._dsnObject);
    };
    /**
     * Returns the store endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    API.prototype.getStoreEndpointWithUrlEncodedAuth = function () {
        return getStoreEndpointWithUrlEncodedAuth(this._dsnObject);
    };
    /**
     * Returns the envelope endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    API.prototype.getEnvelopeEndpointWithUrlEncodedAuth = function () {
        return getEnvelopeEndpointWithUrlEncodedAuth(this._dsnObject, this._tunnel);
    };
    return API;
}());
export { API };
/** Initializes API Details */
export function initAPIDetails(dsn, metadata, tunnel) {
    return {
        initDsn: dsn,
        metadata: metadata || {},
        dsn: makeDsn(dsn),
        tunnel: tunnel,
    };
}
/** Returns the prefix to construct Sentry ingestion API endpoints. */
function getBaseApiEndpoint(dsn) {
    var protocol = dsn.protocol ? dsn.protocol + ":" : '';
    var port = dsn.port ? ":" + dsn.port : '';
    return protocol + "//" + dsn.host + port + (dsn.path ? "/" + dsn.path : '') + "/api/";
}
/** Returns the ingest API endpoint for target. */
function _getIngestEndpoint(dsn, target) {
    return "" + getBaseApiEndpoint(dsn) + dsn.projectId + "/" + target + "/";
}
/** Returns a URL-encoded string with auth config suitable for a query string. */
function _encodedAuth(dsn) {
    return urlEncode({
        // We send only the minimum set of required information. See
        // https://github.com/getsentry/sentry-javascript/issues/2572.
        sentry_key: dsn.publicKey,
        sentry_version: SENTRY_API_VERSION,
    });
}
/** Returns the store endpoint URL. */
function getStoreEndpoint(dsn) {
    return _getIngestEndpoint(dsn, 'store');
}
/**
 * Returns the store endpoint URL with auth in the query string.
 *
 * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
 */
export function getStoreEndpointWithUrlEncodedAuth(dsn) {
    return getStoreEndpoint(dsn) + "?" + _encodedAuth(dsn);
}
/** Returns the envelope endpoint URL. */
function _getEnvelopeEndpoint(dsn) {
    return _getIngestEndpoint(dsn, 'envelope');
}
/**
 * Returns the envelope endpoint URL with auth in the query string.
 *
 * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
 */
export function getEnvelopeEndpointWithUrlEncodedAuth(dsn, tunnel) {
    return tunnel ? tunnel : _getEnvelopeEndpoint(dsn) + "?" + _encodedAuth(dsn);
}
/**
 * Returns an object that can be used in request headers.
 * This is needed for node and the old /store endpoint in sentry
 */
export function getRequestHeaders(dsn, clientName, clientVersion) {
    // CHANGE THIS to use metadata but keep clientName and clientVersion compatible
    var header = ["Sentry sentry_version=" + SENTRY_API_VERSION];
    header.push("sentry_client=" + clientName + "/" + clientVersion);
    header.push("sentry_key=" + dsn.publicKey);
    if (dsn.pass) {
        header.push("sentry_secret=" + dsn.pass);
    }
    return {
        'Content-Type': 'application/json',
        'X-Sentry-Auth': header.join(', '),
    };
}
/** Returns the url to the report dialog endpoint. */
export function getReportDialogEndpoint(dsnLike, dialogOptions) {
    var dsn = makeDsn(dsnLike);
    var endpoint = getBaseApiEndpoint(dsn) + "embed/error-page/";
    var encodedOptions = "dsn=" + dsnToString(dsn);
    for (var key in dialogOptions) {
        if (key === 'dsn') {
            continue;
        }
        if (key === 'user') {
            if (!dialogOptions.user) {
                continue;
            }
            if (dialogOptions.user.name) {
                encodedOptions += "&name=" + encodeURIComponent(dialogOptions.user.name);
            }
            if (dialogOptions.user.email) {
                encodedOptions += "&email=" + encodeURIComponent(dialogOptions.user.email);
            }
        }
        else {
            encodedOptions += "&" + encodeURIComponent(key) + "=" + encodeURIComponent(dialogOptions[key]);
        }
    }
    return endpoint + "?" + encodedOptions;
}
//# sourceMappingURL=api.js.map