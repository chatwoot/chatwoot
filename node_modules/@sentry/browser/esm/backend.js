import { __assign, __extends } from "tslib";
import { BaseBackend, getEnvelopeEndpointWithUrlEncodedAuth, initAPIDetails } from '@sentry/core';
import { Severity } from '@sentry/types';
import { supportsFetch } from '@sentry/utils';
import { eventFromException, eventFromMessage } from './eventbuilder';
import { FetchTransport, makeNewFetchTransport, makeNewXHRTransport, XHRTransport } from './transports';
/**
 * The Sentry Browser SDK Backend.
 * @hidden
 */
var BrowserBackend = /** @class */ (function (_super) {
    __extends(BrowserBackend, _super);
    function BrowserBackend() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype.eventFromException = function (exception, hint) {
        return eventFromException(exception, hint, this._options.attachStacktrace);
    };
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype.eventFromMessage = function (message, level, hint) {
        if (level === void 0) { level = Severity.Info; }
        return eventFromMessage(message, level, hint, this._options.attachStacktrace);
    };
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype._setupTransport = function () {
        if (!this._options.dsn) {
            // We return the noop transport here in case there is no Dsn.
            return _super.prototype._setupTransport.call(this);
        }
        var transportOptions = __assign(__assign({}, this._options.transportOptions), { dsn: this._options.dsn, tunnel: this._options.tunnel, sendClientReports: this._options.sendClientReports, _metadata: this._options._metadata });
        var api = initAPIDetails(transportOptions.dsn, transportOptions._metadata, transportOptions.tunnel);
        var url = getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel);
        if (this._options.transport) {
            return new this._options.transport(transportOptions);
        }
        if (supportsFetch()) {
            var requestOptions = __assign({}, transportOptions.fetchParameters);
            this._newTransport = makeNewFetchTransport({ requestOptions: requestOptions, url: url });
            return new FetchTransport(transportOptions);
        }
        this._newTransport = makeNewXHRTransport({
            url: url,
            headers: transportOptions.headers,
        });
        return new XHRTransport(transportOptions);
    };
    return BrowserBackend;
}(BaseBackend));
export { BrowserBackend };
//# sourceMappingURL=backend.js.map