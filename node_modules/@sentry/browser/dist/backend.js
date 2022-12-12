Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_1 = require("@sentry/core");
var types_1 = require("@sentry/types");
var utils_1 = require("@sentry/utils");
var eventbuilder_1 = require("./eventbuilder");
var transports_1 = require("./transports");
/**
 * The Sentry Browser SDK Backend.
 * @hidden
 */
var BrowserBackend = /** @class */ (function (_super) {
    tslib_1.__extends(BrowserBackend, _super);
    function BrowserBackend() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype.eventFromException = function (exception, hint) {
        return eventbuilder_1.eventFromException(exception, hint, this._options.attachStacktrace);
    };
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype.eventFromMessage = function (message, level, hint) {
        if (level === void 0) { level = types_1.Severity.Info; }
        return eventbuilder_1.eventFromMessage(message, level, hint, this._options.attachStacktrace);
    };
    /**
     * @inheritDoc
     */
    BrowserBackend.prototype._setupTransport = function () {
        if (!this._options.dsn) {
            // We return the noop transport here in case there is no Dsn.
            return _super.prototype._setupTransport.call(this);
        }
        var transportOptions = tslib_1.__assign(tslib_1.__assign({}, this._options.transportOptions), { dsn: this._options.dsn, tunnel: this._options.tunnel, sendClientReports: this._options.sendClientReports, _metadata: this._options._metadata });
        var api = core_1.initAPIDetails(transportOptions.dsn, transportOptions._metadata, transportOptions.tunnel);
        var url = core_1.getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel);
        if (this._options.transport) {
            return new this._options.transport(transportOptions);
        }
        if (utils_1.supportsFetch()) {
            var requestOptions = tslib_1.__assign({}, transportOptions.fetchParameters);
            this._newTransport = transports_1.makeNewFetchTransport({ requestOptions: requestOptions, url: url });
            return new transports_1.FetchTransport(transportOptions);
        }
        this._newTransport = transports_1.makeNewXHRTransport({
            url: url,
            headers: transportOptions.headers,
        });
        return new transports_1.XHRTransport(transportOptions);
    };
    return BrowserBackend;
}(core_1.BaseBackend));
exports.BrowserBackend = BrowserBackend;
//# sourceMappingURL=backend.js.map