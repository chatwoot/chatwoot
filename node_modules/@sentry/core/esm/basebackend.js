import { __read } from "tslib";
import { logger, SentryError } from '@sentry/utils';
import { initAPIDetails } from './api';
import { IS_DEBUG_BUILD } from './flags';
import { createEventEnvelope, createSessionEnvelope } from './request';
import { NoopTransport } from './transports/noop';
/**
 * This is the base implemention of a Backend.
 * @hidden
 */
var BaseBackend = /** @class */ (function () {
    /** Creates a new backend instance. */
    function BaseBackend(options) {
        this._options = options;
        if (!this._options.dsn) {
            IS_DEBUG_BUILD && logger.warn('No DSN provided, backend will not do anything.');
        }
        this._transport = this._setupTransport();
    }
    /**
     * @inheritDoc
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
    BaseBackend.prototype.eventFromException = function (_exception, _hint) {
        throw new SentryError('Backend has to implement `eventFromException` method');
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.eventFromMessage = function (_message, _level, _hint) {
        throw new SentryError('Backend has to implement `eventFromMessage` method');
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
            var api = initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
            var env = createEventEnvelope(event, api);
            void this._newTransport.send(env).then(null, function (reason) {
                IS_DEBUG_BUILD && logger.error('Error while sending event:', reason);
            });
        }
        else {
            void this._transport.sendEvent(event).then(null, function (reason) {
                IS_DEBUG_BUILD && logger.error('Error while sending event:', reason);
            });
        }
    };
    /**
     * @inheritDoc
     */
    BaseBackend.prototype.sendSession = function (session) {
        if (!this._transport.sendSession) {
            IS_DEBUG_BUILD && logger.warn("Dropping session because custom transport doesn't implement sendSession");
            return;
        }
        // TODO(v7): Remove the if-else
        if (this._newTransport &&
            this._options.dsn &&
            this._options._experiments &&
            this._options._experiments.newTransport) {
            var api = initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
            var _a = __read(createSessionEnvelope(session, api), 1), env = _a[0];
            void this._newTransport.send(env).then(null, function (reason) {
                IS_DEBUG_BUILD && logger.error('Error while sending session:', reason);
            });
        }
        else {
            void this._transport.sendSession(session).then(null, function (reason) {
                IS_DEBUG_BUILD && logger.error('Error while sending session:', reason);
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
        return new NoopTransport();
    };
    return BaseBackend;
}());
export { BaseBackend };
//# sourceMappingURL=basebackend.js.map