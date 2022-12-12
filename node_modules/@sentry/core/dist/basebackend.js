Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var utils_1 = require("@sentry/utils");
var api_1 = require("./api");
var flags_1 = require("./flags");
var request_1 = require("./request");
var noop_1 = require("./transports/noop");
/**
 * This is the base implemention of a Backend.
 * @hidden
 */
var BaseBackend = /** @class */ (function () {
    /** Creates a new backend instance. */
    function BaseBackend(options) {
        this._options = options;
        if (!this._options.dsn) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.warn('No DSN provided, backend will not do anything.');
        }
        this._transport = this._setupTransport();
    }
    /**
     * @inheritDoc
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
    BaseBackend.prototype.eventFromException = function (_exception, _hint) {
        throw new utils_1.SentryError('Backend has to implement `eventFromException` method');
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.eventFromMessage = function (_message, _level, _hint) {
        throw new utils_1.SentryError('Backend has to implement `eventFromMessage` method');
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.sendEvent = function (event) {
        // TODO(v7): Remove the if-else
        if (this._newTransport &&
            this._options.dsn &&
            this._options._experiments &&
            this._options._experiments.newTransport) {
            var api = api_1.initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
            var env = request_1.createEventEnvelope(event, api);
            void this._newTransport.send(env).then(null, function (reason) {
                flags_1.IS_DEBUG_BUILD && utils_1.logger.error('Error while sending event:', reason);
            });
        }
        else {
            void this._transport.sendEvent(event).then(null, function (reason) {
                flags_1.IS_DEBUG_BUILD && utils_1.logger.error('Error while sending event:', reason);
            });
        }
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.sendSession = function (session) {
        if (!this._transport.sendSession) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.warn("Dropping session because custom transport doesn't implement sendSession");
            return;
        }
        // TODO(v7): Remove the if-else
        if (this._newTransport &&
            this._options.dsn &&
            this._options._experiments &&
            this._options._experiments.newTransport) {
            var api = api_1.initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
            var _a = tslib_1.__read(request_1.createSessionEnvelope(session, api), 1), env = _a[0];
            void this._newTransport.send(env).then(null, function (reason) {
                flags_1.IS_DEBUG_BUILD && utils_1.logger.error('Error while sending session:', reason);
            });
        }
        else {
            void this._transport.sendSession(session).then(null, function (reason) {
                flags_1.IS_DEBUG_BUILD && utils_1.logger.error('Error while sending session:', reason);
            });
        }
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.getTransport = function () {
        return this._transport;
    };
    /**
     * Sets up the transport so it can be used later to send requests.
     */
    BaseBackend.prototype._setupTransport = function () {
        return new noop_1.NoopTransport();
    };
    return BaseBackend;
}());
exports.BaseBackend = BaseBackend;
//# sourceMappingURL=basebackend.js.map